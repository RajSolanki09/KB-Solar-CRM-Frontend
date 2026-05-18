import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/screens/Dashboards/Material/add_material_customer.dart';
import 'package:solar_project/screens/Dashboards/Material/add_material.dart';
import 'package:solar_project/screens/Dashboards/Material/material_customer_list_tab.dart';
import 'package:solar_project/screens/Dashboards/Material/material_customer_pipeline_screen.dart';
import 'package:solar_project/services/api_service.dart';

class MaterialListScreen extends StatefulWidget {
  final Color? appBarColor;
  const MaterialListScreen({super.key, this.appBarColor});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _loadingMaterials = true;
  bool _loadingCustomers = true;
  List<Map<String, dynamic>> _materials = const [];
  List<Map<String, dynamic>> _customers = const [];

  int _customerPage = 1;
  int _customerTotalPages = 1;
  static const int _customerLimit = 10;

  int _materialPage = 1;
  int _materialTotalPages = 1;
  static const int _materialLimit = 10;

  // ─── Formatters ──────────────────────────────────────────────────────────────

  String _inr(dynamic value) {
    final numValue =
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return '₹${numValue.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadMaterials();
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Data loaders ─────────────────────────────────────────────────────────────

  Future<void> _loadMaterials({int page = 1}) async {
    setState(() => _loadingMaterials = true);
    try {
      final data =
          await _apiService.getMaterials(page: page, limit: _materialLimit);
      if (!mounted) return;
      setState(() {
        _materials =
            List<Map<String, dynamic>>.from(data['materials'] ?? []);
        _materialPage = data['page'] ?? 1;
        _materialTotalPages = data['totalPages'] ?? 1;
        _loadingMaterials = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMaterials = false);
      AppFeedback.showError(context, 'Failed to load materials: $e');
    }
  }

  Future<void> _loadCustomers({int page = 1}) async {
    setState(() => _loadingCustomers = true);
    try {
      final data = await _apiService.getMaterialCustomers(
          page: page, limit: _customerLimit);
      if (!mounted) return;
      setState(() {
        _customers =
            List<Map<String, dynamic>>.from(data['customers'] ?? []);
        _customerPage = data['page'] ?? 1;
        _customerTotalPages = data['totalPages'] ?? 1;
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      AppFeedback.showError(context, 'Failed to load customers: $e');
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _openAddMaterial() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddMaterialScreen(appBarColor: AppColors.indigo500),
      ),
    );
    if (!mounted) return;
    if (result == true) await _loadMaterials();
  }

  Future<void> _openAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMaterialCustomerScreen(
            appBarColor: AppColors.indigo500),
      ),
    );
    if (!mounted) return;
    await _loadCustomers(page: 1);
  }

  Future<void> _openEditCustomer(Map<String, dynamic> customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaterialCustomerScreen(
          appBarColor: AppColors.indigo500,
          initialCustomer: customer,
        ),
      ),
    );
    if (!mounted) return;
    await _loadCustomers(page: _customerPage);
  }

  Future<void> _openCustomerPipeline(Map<String, dynamic> customer) async {
    final id = _customerId(customer);
    if (id == null) {
      AppFeedback.showError(context, 'Customer id not found');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialCustomerPipelineScreen(
          customerId: id,
          initialCustomer: customer,
          appBarColor: AppColors.indigo500,
        ),
      ),
    );
    if (!mounted) return;
    await _loadCustomers();
  }

  Future<void> _openEditMaterial(Map<String, dynamic> material) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaterialScreen(
          appBarColor: AppColors.indigo500,
          initialMaterial: material,
        ),
      ),
    );
    if (!mounted) return;
    await _loadMaterials();
  }

  // ─── ID helpers ──────────────────────────────────────────────────────────────

  String? _materialId(Map<String, dynamic> item) {
    final dynamic id = item['_id'] ?? item['id'] ?? item['materialId'];
    final value = id?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? _customerId(Map<String, dynamic> item) {
    final dynamic id = item['_id'] ?? item['id'] ?? item['customerId'];
    final value = id?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  // ─── Delete confirmations ─────────────────────────────────────────────────────

  Future<void> _confirmAndDeleteMaterial(
      Map<String, dynamic> material) async {
    final materialName =
        (material['materialName'] ?? 'this material').toString();
    final id = _materialId(material);
    if (id == null) {
      AppFeedback.showError(context, 'Material id not found');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material'),
        content:
            Text('Are you sure you want to delete "$materialName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _apiService.deleteMaterial(id);
      if (!mounted) return;
      setState(() {
        _materials =
            _materials.where((e) => _materialId(e) != id).toList();
      });
      AppFeedback.showSuccess(context, 'Material deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to delete material: $e');
    }
  }

  Future<void> _confirmAndDeleteCustomer(
      Map<String, dynamic> customer) async {
    final customerName =
        (customer['customerName'] ?? 'this customer').toString();
    final id = _customerId(customer);
    if (id == null) {
      AppFeedback.showError(context, 'Customer id not found');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content:
            Text('Are you sure you want to delete "$customerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _apiService.deleteMaterialCustomer(id);
      if (!mounted) return;
      await _loadCustomers(page: _customerPage);
      AppFeedback.showSuccess(context, 'Customer deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to delete customer: $e');
    }
  }

  // ─── Pagination callbacks ─────────────────────────────────────────────────────

  void _onMaterialPageChanged(int newPage) {
    if (newPage < 1 || newPage > _materialTotalPages) return;
    _loadMaterials(page: newPage);
  }

  void _onCustomerPageChanged(int newPage) {
    if (newPage < 1 || newPage > _customerTotalPages) return;
    _loadCustomers(page: newPage);
  }

  // ─── Pagination number builders ───────────────────────────────────────────────

  List<Widget> _buildPageNumbers({
    required int currentPage,
    required int totalPages,
    required bool loading,
    required void Function(int) onPageTap,
  }) {
    const int maxPagesToShow = 5;
    int start = (currentPage - 2)
        .clamp(1, (totalPages - maxPagesToShow + 1).clamp(1, totalPages));
    int end = (start + maxPagesToShow - 1).clamp(1, totalPages);
    if (totalPages <= maxPagesToShow) {
      start = 1;
      end = totalPages;
    }

    return List.generate(end - start + 1, (i) {
      final page = start + i;
      final isSelected = page == currentPage;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: isSelected || loading ? null : () => onPageTap(page),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.indigo500 : AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.slate200, width: 1.5),
            ),
            child: Center(
              child: Text(
                '$page',
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : AppColors.indigo500,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.appBarColor ?? AppColors.indigo500;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isExtraLarge = screenWidth >= 1600;

    final horizontalPadding =
        isExtraLarge ? 0.0 : isDesktop ? 8.0 : 14.0;
    final isMaterialTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      // ── NO floatingActionButton — moved into _BottomActionBar ──
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            AppSvgIcon(AppSvgAssets.packagePlus, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Material Inventory',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Top TabBar: Materials / Customers ─────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: AppColors.slate500,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'Materials'),
                Tab(text: 'Customers'),
              ],
            ),
          ),

          // ── Tab content (scrollable) ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Materials tab ──────────────────────────────────────────
                _buildMaterialsTab(
                  primaryColor: primaryColor,
                  horizontalPadding: horizontalPadding,
                  isDesktop: isDesktop,
                ),

                // ── Customers tab ──────────────────────────────────────────
                _buildCustomersTab(
                  primaryColor: primaryColor,
                  horizontalPadding: horizontalPadding,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),

          // ── Sticky bottom bar: pagination + add button ────────────────────
          _BottomActionBar(
            primaryColor: primaryColor,
            onAdd: isMaterialTab ? _openAddMaterial : _openAddCustomer,
            addLabel: isMaterialTab ? 'Add Material' : 'Add Customer',
            page: isMaterialTab ? _materialPage : _customerPage,
            totalPages:
                isMaterialTab ? _materialTotalPages : _customerTotalPages,
            loading:
                isMaterialTab ? _loadingMaterials : _loadingCustomers,
            onPrev: isMaterialTab
                ? () => _onMaterialPageChanged(_materialPage - 1)
                : () => _onCustomerPageChanged(_customerPage - 1),
            onNext: isMaterialTab
                ? () => _onMaterialPageChanged(_materialPage + 1)
                : () => _onCustomerPageChanged(_customerPage + 1),
            pageNumbers: _buildPageNumbers(
              currentPage:
                  isMaterialTab ? _materialPage : _customerPage,
              totalPages:
                  isMaterialTab ? _materialTotalPages : _customerTotalPages,
              loading:
                  isMaterialTab ? _loadingMaterials : _loadingCustomers,
              onPageTap: isMaterialTab
                  ? _onMaterialPageChanged
                  : _onCustomerPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Materials tab widget ─────────────────────────────────────────────────────

  Widget _buildMaterialsTab({
    required Color primaryColor,
    required double horizontalPadding,
    required bool isDesktop,
  }) {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _loadMaterials(page: 1),
      child: _loadingMaterials
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 180),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: AppColors.slate300),
                          const SizedBox(height: 12),
                          const Text(
                            'No materials found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, horizontalPadding,
                      horizontalPadding, 8),
                  children: [
                    Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStatePropertyAll(
                                  primaryColor.withValues(alpha: 0.14),
                                ),
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                                columnSpacing: isDesktop ? 56 : 28,
                                columns: const [
                                  DataColumn(label: Text('Material')),
                                  DataColumn(label: Text('Brand')),
                                  DataColumn(label: Text('Purchase')),
                                  DataColumn(label: Text('Selling')),
                                  DataColumn(label: Text('GST')),
                                  DataColumn(label: Text('Created')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _materials.map((item) {
                                  return DataRow(cells: [
                                    DataCell(Text(
                                        '${item['materialName'] ?? '-'}')),
                                    DataCell(
                                        Text('${item['brand'] ?? '-'}')),
                                    DataCell(
                                        Text(_inr(item['purchasePrice']))),
                                    DataCell(
                                        Text(_inr(item['sellingPrice']))),
                                    DataCell(
                                        Text('${item['gstRate'] ?? '-'}')),
                                    DataCell(Text(
                                        _formatDate(item['createdAt']))),
                                    DataCell(
                                      Row(children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          onPressed: () =>
                                              _openEditMaterial(item),
                                          icon: Icon(Icons.edit_outlined,
                                              color: primaryColor,
                                              size: 20),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          onPressed: () =>
                                              _confirmAndDeleteMaterial(
                                                  item),
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.redError,
                                              size: 20),
                                        ),
                                      ]),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // ─── Customers tab widget ─────────────────────────────────────────────────────

  Widget _buildCustomersTab({
    required Color primaryColor,
    required double horizontalPadding,
    required bool isDesktop,
  }) {
    return MaterialCustomerListTab(
      loading: _loadingCustomers,
      customers: _customers,
      onRefresh: () => _loadCustomers(page: 1),
      color: primaryColor,
      horizontalPadding: horizontalPadding,
      isDesktop: isDesktop,
      formatDate: _formatDate,
      onOpenCustomer: _openCustomerPipeline,
      onEditCustomer: _openEditCustomer,
      onDeleteCustomer: _confirmAndDeleteCustomer,
      onAddCustomer: _openAddCustomer,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sticky Bottom Action Bar — pagination (left) + add button (right)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onAdd;
  final String addLabel;
  final int page;
  final int totalPages;
  final bool loading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final List<Widget> pageNumbers;

  const _BottomActionBar({
    required this.primaryColor,
    required this.onAdd,
    required this.addLabel,
    required this.page,
    required this.totalPages,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    required this.pageNumbers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // ── Pagination ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageNavBtn(
                    icon: Icons.chevron_left,
                    enabled: page > 1 && !loading,
                    onTap: onPrev,
                  ),
                  ...pageNumbers,
                  _PageNavBtn(
                    icon: Icons.chevron_right,
                    enabled: page < totalPages && !loading,
                    onTap: onNext,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Add button ──────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 17),
            label: Text(
              addLabel,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Prev / Next nav button
// ─────────────────────────────────────────────────────────────────────────────

class _PageNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.slate200, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.indigo500 : AppColors.slate300,
        ),
      ),
    );
  }
}