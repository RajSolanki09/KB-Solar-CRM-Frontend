import 'package:flutter/material.dart';
import 'package:solar_project/core/app_colors.dart';

class MaterialCustomerListTab extends StatefulWidget {
  final bool loading;
  final List<Map<String, dynamic>> customers;
  final Future<void> Function() onRefresh;
  final Color color;
  final double horizontalPadding;
  final bool isDesktop;
  final String Function(dynamic value) formatDate;
  final Future<void> Function(Map<String, dynamic> customer) onOpenCustomer;
  final Future<void> Function(Map<String, dynamic> customer) onEditCustomer;
  final Future<void> Function(Map<String, dynamic> customer) onDeleteCustomer;
  final VoidCallback? onAddCustomer;

  const MaterialCustomerListTab({
    super.key,
    required this.loading,
    required this.customers,
    required this.onRefresh,
    required this.color,
    required this.horizontalPadding,
    required this.isDesktop,
    required this.formatDate,
    required this.onOpenCustomer,
    required this.onEditCustomer,
    required this.onDeleteCustomer,
    this.onAddCustomer,
  });

  @override
  State<MaterialCustomerListTab> createState() =>
      _MaterialCustomerListTabState();
}

class _MaterialCustomerListTabState extends State<MaterialCustomerListTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _pipelineOf(Map<String, dynamic> customer) {
    final raw = customer['pipeline'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  String _statusOf(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    return '${pipeline['status'] ?? 'New'}';
  }

  bool _isCompletedCustomer(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    final status = _statusOf(customer).trim().toLowerCase();
    final dispatch = pipeline['dispatch'];
    final dispatchDate = dispatch is Map
        ? dispatch['dispatchDate']?.toString() ?? ''
        : '';

    if (pipeline['isCompleted'] == true) return true;
    if (dispatchDate.isNotEmpty) return true;

    return {
      'completed',
      'project completed',
      'payment completed',
      'payment',
      'won',
    }.contains(status);
  }

  Color _statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return   AppColors.cyanLight;
      case 'follow up':
      case 'follow-up':
        return  AppColors.yellowAccent;
      case 'quoted':
      case 'quotation sent':
        return   AppColors.purpleLight1;
      case 'won':
      case 'completed':
      case 'project completed':
      case 'payment':
      case 'payment completed':
        return   AppColors.greenLight;
      case 'lost':
      case 'cancelled':
        return  AppColors.errorLight;
      default:
        return   AppColors.slate200;
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return   AppColors.cyanLight;
      case 'follow up':
      case 'follow-up':
        return  AppColors.orange900;
      case 'quoted':
      case 'quotation sent':
        return   AppColors.purple1;
      case 'won':
      case 'completed':
      case 'project completed':
      case 'payment':
      case 'payment completed':
        return   AppColors.greenDark;
      case 'lost':
      case 'cancelled':
        return   AppColors.redDarker;
      default:
        return   AppColors.slate700;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'payment':
      case 'payment completed':
        return 'Payment Completed';
      case 'project completed':
        return 'Project Completed';
      default:
        return status;
    }
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color:   AppColors.slate300,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTable(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStatePropertyAll(
                widget.color.withValues(alpha: 0.10),
              ),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.color,
                fontSize: 13,
              ),
              columnSpacing: widget.isDesktop ? 56 : 28,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              columns: const [
                DataColumn(label: Text('Customer Name')),
                DataColumn(label: Text('Mobile')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Current Status')),
                DataColumn(label: Text('Created')),
                DataColumn(label: Text('Actions')),
              ],
              rows: items.map((item) {
                final status = _statusOf(item);
                return DataRow(
                  cells: [
                    DataCell(Text('${item['customerName'] ?? '-'}')),
                    DataCell(Text('${item['mobile'] ?? '-'}')),
                    DataCell(Text('${item['address'] ?? '-'}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBackgroundColor(status),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusTextColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(widget.formatDate(item['createdAt']))),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => widget.onEditCustomer(item),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: widget.color,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => widget.onDeleteCustomer(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.redError,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelectChanged: (_) => widget.onOpenCustomer(item),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Tab content — wraps table or empty state inside a scrollable + RefreshIndicator
  Widget _buildTabContent({
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
  }) {
    return RefreshIndicator(
      color: widget.color,
      onRefresh: widget.onRefresh,
      child: items.isEmpty
          ? ListView(
              // ListView needed so RefreshIndicator works even when empty
              children: [_buildEmptyMessage(emptyMessage)],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(widget.horizontalPadding),
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color:   AppColors.slate200),
                ),
                child: _buildCustomerTable(items),
              ),
            ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Center(child: CircularProgressIndicator(color: widget.color));
    }

    final activeCustomers = widget.customers
        .where((c) => !_isCompletedCustomer(c))
        .toList();
    final completedCustomers = widget.customers
        .where(_isCompletedCustomer)
        .toList();

    const double fabH = 36.0;

    return Column(
      children: [
        // ── TabBar ───────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: widget.color,
            indicatorWeight: 3,
            labelColor: widget.color,
            unselectedLabelColor:   AppColors.slate300,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Active'),
                    const SizedBox(width: 6),
                    _buildTabBadge(
                      count: activeCustomers.length,
                      bgColor: widget.color.withValues(alpha: 0.12),
                      textColor: widget.color,
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Completed'),
                    const SizedBox(width: 6),
                    _buildTabBadge(
                      count: completedCustomers.length,
                      bgColor:   AppColors.greenLight,
                      textColor:   AppColors.greenDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Divider with FAB centered on it ─────────────────────────────────
        SizedBox(
          height: fabH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Divider in the vertical center of this SizedBox
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(height: 1, color:   AppColors.slate200),
                ),
              ),
              // FAB pinned to right, centered vertically
              Positioned(
                top: 0,
                bottom: 0,
                right: 16,
                child: Center(
                  child: SizedBox(
                    height: fabH,
                    child: FloatingActionButton.extended(
                      heroTag: 'material_customer_fab',
                      onPressed: widget.onAddCustomer,
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Add Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Tab Views ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                items: activeCustomers,
                emptyMessage: 'No active leads found',
              ),
              _buildTabContent(
                items: completedCustomers,
                emptyMessage: 'No completed leads found',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBadge({
    required int count,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}









