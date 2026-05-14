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

class _MaterialListScreenState extends State<MaterialListScreen> with TickerProviderStateMixin {
  // Helper to build page number buttons for material pagination bar
  List<Widget> _buildPageNumbers() {
    const Color primaryColor = AppColors.indigo500;
    const Color borderColor = AppColors.slate200;
    const Color unselectedBg = AppColors.slate50;
    const int maxPagesToShow = 5;
    List<Widget> widgets = [];
    int start = (_materialPage - 2).clamp(1, (_materialTotalPages - maxPagesToShow + 1).clamp(1, _materialTotalPages));
    int end = (start + maxPagesToShow - 1).clamp(1, _materialTotalPages);
    if (_materialTotalPages <= maxPagesToShow) {
      start = 1;
      end = _materialTotalPages;
    }
    for (int i = start; i <= end; i++) {
      final bool isSelected = i == _materialPage;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: isSelected || _loadingMaterials ? null : () => _onMaterialPageChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : unselectedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  // Helper to build page number buttons for customer pagination bar
  List<Widget> _buildCustomerPageNumbers() {
    const Color primaryColor = AppColors.indigo500;
    const Color borderColor = AppColors.slate200;
    const Color unselectedBg = AppColors.slate50;
    const int maxPagesToShow = 5;
    List<Widget> widgets = [];
    int start = (_customerPage - 2).clamp(1, (_customerTotalPages - maxPagesToShow + 1).clamp(1, _customerTotalPages));
    int end = (start + maxPagesToShow - 1).clamp(1, _customerTotalPages);
    if (_customerTotalPages <= maxPagesToShow) {
      start = 1;
      end = _customerTotalPages;
    }
    for (int i = start; i <= end; i++) {
      final bool isSelected = i == _customerPage;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: isSelected || _loadingCustomers ? null : () => _onCustomerPageChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : unselectedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  void _onCustomerPageChanged(int newPage) {
    if (newPage < 1 || newPage > _customerTotalPages) return;
    _loadCustomers(page: newPage);
  }
    // (removed duplicate material pagination code)
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
  // Helper for INR formatting
  String _inr(dynamic value) {
    final numValue = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return '₹${numValue.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
      final raw = value?.toString() ?? '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return '-';
      return DateFormat('dd MMM yyyy').format(dt.toLocal());
    }
  static const int _materialLimit = 10;

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

  Future<void> _loadMaterials({int page = 1}) async {
    setState(() => _loadingMaterials = true);
    try {
      final data = await _apiService.getMaterials(page: page, limit: _materialLimit);
      if (!mounted) return;
      setState(() {
        _materials = List<Map<String, dynamic>>.from(data['materials'] ?? []);
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
      final data = await _apiService.getMaterialCustomers(page: page, limit: _customerLimit);
      if (!mounted) return;
      setState(() {
        _customers = List<Map<String, dynamic>>.from(data['customers'] ?? []);
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

  Future<void> _openAddMaterial() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMaterialScreen(appBarColor: AppColors.indigo500),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadMaterials();
    }
  }

  Future<void> _openAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddMaterialCustomerScreen(appBarColor: AppColors.indigo500),
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
          appBarColor:   AppColors.indigo500,
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
          appBarColor:   AppColors.indigo500,
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
          appBarColor:   AppColors.indigo500,
          initialMaterial: material,
        ),
      ),
    );
    if (!mounted) return;
    await _loadMaterials();
  }

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

  Future<void> _confirmAndDeleteMaterial(Map<String, dynamic> material) async {
    final materialName = (material['materialName'] ?? 'this material')
        .toString();
    final id = _materialId(material);
    if (id == null) {
      AppFeedback.showError(context, 'Material id not found');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Material'),
          content: Text('Are you sure you want to delete "$materialName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:   AppColors.redError,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _apiService.deleteMaterial(id);
      if (!mounted) return;
      setState(() {
        _materials = _materials.where((e) => _materialId(e) != id).toList();
      });
      AppFeedback.showSuccess(context, 'Material deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to delete material: $e');
    }
  }

  Future<void> _confirmAndDeleteCustomer(Map<String, dynamic> customer) async {
    final customerName = (customer['customerName'] ?? 'this customer')
        .toString();
    final id = _customerId(customer);
    if (id == null) {
      AppFeedback.showError(context, 'Customer id not found');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete "$customerName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:   AppColors.indigo500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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

  void _onMaterialPageChanged(int newPage) {
    if (newPage < 1 || newPage > _materialTotalPages) return;
    _loadMaterials(page: newPage);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.appBarColor ??   AppColors.indigo500;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isExtraLarge = screenWidth >= 1600;

    final horizontalPadding = isExtraLarge
        ? 0.0
        : isDesktop
        ? 8.0
        : 14.0;
    final isMaterialTab = _tabController.index == 0;

    // Widget build
    // (no stray return)
    return Scaffold(
      backgroundColor:   AppColors.slate50,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.packagePlus,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Material Inventory',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        leading: IconButton(
          icon: AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isMaterialTab ? _openAddMaterial : _openAddCustomer,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: AppSvgIcon(
          AppSvgAssets.plus,
          color: Colors.white,
          size: 18,
        ),
        label: Text(isMaterialTab ? 'Add Material' : 'Add Customer'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor:   AppColors.slate500,
              indicatorColor: primaryColor,
              tabs: [
                Tab(text: 'Materials'),
                Tab(text: 'Customers'),
              ],
            ),
          ),
          Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          color: primaryColor,
                          onRefresh: () => _loadMaterials(page: 1),
                          child: _loadingMaterials
                              ? const Center(child: CircularProgressIndicator())
                              : _materials.isEmpty
                                  ? ListView(
                                      children: [
                                        SizedBox(height: 180),
                                        Center(
                                          child: Text(
                                            'No materials found',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView(
                                      padding: EdgeInsets.all(horizontalPadding),
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.slate200,
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                return SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minWidth: constraints.maxWidth,
                                                    ),
                                                    child: DataTable(
                                                      headingRowColor:
                                                          WidgetStatePropertyAll(
                                                            primaryColor.withOpacity(0.14),
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
                                                        return DataRow(
                                                          cells: [
                                                            DataCell(
                                                              Text(
                                                                '${item['materialName'] ?? '-'}',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                '${item['brand'] ?? '-'}',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                _inr(item['purchasePrice']),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                _inr(item['sellingPrice']),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                '${item['gstRate'] ?? '-'}',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                _formatDate(
                                                                  item['createdAt'],
                                                                ),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Row(
                                                                children: [
                                                                  IconButton(
                                                                    tooltip: 'Edit',
                                                                    onPressed: () => _openEditMaterial(item),
                                                                    icon: Icon(
                                                                      Icons.edit_outlined,
                                                                      color: primaryColor,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    tooltip: 'Delete',
                                                                    onPressed: () => _confirmAndDeleteMaterial(item),
                                                                    icon: Icon(
                                                                      Icons.delete_outline,
                                                                      color: AppColors.redError,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        // Modern Pagination Bar (styled as per image)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Previous Button
                                              GestureDetector(
                                                onTap: _materialPage > 1 && !_loadingMaterials
                                                    ? () => _onMaterialPageChanged(_materialPage - 1)
                                                    : null,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.slate50,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: AppColors.slate200, width: 1.5),
                                                  ),
                                                  child: Icon(Icons.chevron_left,
                                                    color: _materialPage > 1 && !_loadingMaterials ? AppColors.indigo500 : AppColors.slate300,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                              ..._buildPageNumbers(),
                                              // Next Button
                                              GestureDetector(
                                                onTap: _materialPage < _materialTotalPages && !_loadingMaterials
                                                    ? () => _onMaterialPageChanged(_materialPage + 1)
                                                    : null,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.slate50,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: AppColors.slate200, width: 1.5),
                                                  ),
                                                  child: Icon(Icons.chevron_right,
                                                    color: _materialPage < _materialTotalPages && !_loadingMaterials ? AppColors.indigo500 : AppColors.slate300,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                        Column(
                          children: [
                            Expanded(
                              child: MaterialCustomerListTab(
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
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Previous Button
                                  GestureDetector(
                                    onTap: _customerPage > 1 && !_loadingCustomers
                                        ? () => _onCustomerPageChanged(_customerPage - 1)
                                        : null,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.slate50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.slate200, width: 1.5),
                                      ),
                                      child: Icon(Icons.chevron_left,
                                        color: _customerPage > 1 && !_loadingCustomers ? AppColors.indigo500 : AppColors.slate300,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  ..._buildCustomerPageNumbers(),
                                  // Next Button
                                  GestureDetector(
                                    onTap: _customerPage < _customerTotalPages && !_loadingCustomers
                                        ? () => _onCustomerPageChanged(_customerPage + 1)
                                        : null,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.slate50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.slate200, width: 1.5),
                                      ),
                                      child: Icon(Icons.chevron_right,
                                        color: _customerPage < _customerTotalPages && !_loadingCustomers ? AppColors.indigo500 : AppColors.slate300,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
}
}



