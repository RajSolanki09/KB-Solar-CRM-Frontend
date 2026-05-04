import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/screens/Dashboards/Material/add_material_customer.dart';
import 'package:solar_project/screens/Dashboards/Material/add_material.dart';
import 'package:solar_project/screens/Dashboards/Material/material_customer_list_tab.dart';
import 'package:solar_project/screens/Dashboards/Material/material_customer_pipeline_screen.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_colors.dart';

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

  Future<void> _loadMaterials() async {
    setState(() => _loadingMaterials = true);
    try {
      final data = await _apiService.getMaterials();
      if (!mounted) return;
      setState(() {
        _materials = data;
        _loadingMaterials = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMaterials = false);
      AppFeedback.showError(context, 'Failed to load materials: $e');
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final data = await _apiService.getMaterialCustomers();
      if (!mounted) return;
      setState(() {
        _customers = data;
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      AppFeedback.showError(context, 'Failed to load customers: $e');
    }
  }

  Future<void> _openAddMaterial() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMaterialScreen(appBarColor: AppColors.primary)),
      ),
    );
    if (!mounted) return;
    await _loadMaterials();
  }

  Future<void> _openAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddMaterialCustomerScreen(appBarColor: AppColors.primary)),
      ),
    );
    if (!mounted) return;
    await _loadCustomers();
  }

  Future<void> _openEditCustomer(Map<String, dynamic> customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMaterialCustomerScreen(
          appBarColor: AppColors.primary),
          initialCustomer: customer,
        ),
      ),
    );
    if (!mounted) return;
    await _loadCustomers();
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
          appBarColor: AppColors.primary),
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
          appBarColor: AppColors.primary),
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
                backgroundColor: AppColors.primary),
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
                backgroundColor: AppColors.primary),
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
      setState(() {
        _customers = _customers.where((e) => _customerId(e) != id).toList();
      });
      AppFeedback.showSuccess(context, 'Customer deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to delete customer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.appBarColor ?? AppColors.primary);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isExtraLarge = screenWidth >= 1600;

    final horizontalPadding = isExtraLarge
        ? 0.0
        : isDesktop
        ? 8.0
        : 14.0;
    final isMaterialTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.packagePlus, // 👈 material/inventory icon
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
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const AppSvgIcon(
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
              labelColor: color,
              unselectedLabelColor: AppColors.textSecondary),
              indicatorColor: color,
              tabs: const [
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
                  color: color,
                  onRefresh: _loadMaterials,
                  child: _loadingMaterials
                      ? const Center(child: CircularProgressIndicator())
                      : _materials.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 180),
                            Center(
                              child: Text(
                                'No materials found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary),
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
                                    color: AppColors.bgPrimary),
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
                                                color.withValues(alpha: 0.14),
                                              ),
                                          headingTextStyle: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: color,
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
                                                        onPressed: () =>
                                                            _openEditMaterial(
                                                              item,
                                                            ),
                                                        icon: Icon(
                                                          Icons.edit_outlined,
                                                          color: color,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Delete',
                                                        onPressed: () =>
                                                            _confirmAndDeleteMaterial(
                                                              item,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          color: Color(
                                                            AppColors.error,
                                                          ),
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
                          ],
                        ),
                ),
                MaterialCustomerListTab(
                  loading: _loadingCustomers,
                  customers: _customers,
                  onRefresh: _loadCustomers,
                  color: color,
                  horizontalPadding: horizontalPadding,
                  isDesktop: isDesktop,
                  formatDate: _formatDate,
                  onOpenCustomer: _openCustomerPipeline,
                  onEditCustomer: _openEditCustomer,
                  onDeleteCustomer: _confirmAndDeleteCustomer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}





