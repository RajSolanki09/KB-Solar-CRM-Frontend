import 'package:flutter/material.dart';
import 'package:solar_project/core/app_colors.dart';

class MaterialCustomerListTab extends StatelessWidget {
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
  });

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
        return const Color(0xFFE0F2FE);
      case 'follow up':
      case 'follow-up':
        return const Color(0xFFFEF3C7);
      case 'quoted':
      case 'quotation sent':
        return  AppColors.primaryTint;
      case 'won':
      case 'completed':
      case 'project completed':
      case 'payment':
      case 'payment completed':
        return  AppColors.successLight;
      case 'lost':
      case 'cancelled':
        return  AppColors.errorLight;
      default:
        return  AppColors.divider;
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFF0369A1);
      case 'follow up':
      case 'follow-up':
        return  Color(0xFFB45309);
      case 'quoted':
      case 'quotation sent':
        return  AppColors.primary;
      case 'won':
      case 'completed':
      case 'project completed':
      case 'payment':
      case 'payment completed':
        return  AppColors.success;
      case 'lost':
      case 'cancelled':
        return  AppColors.error;
      default:
        return  AppColors.textGray;
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

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textGray,
          ),
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
                color.withValues(alpha: 0.14),
              ),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              columnSpacing: isDesktop ? 56 : 28,
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
                    DataCell(Text(formatDate(item['createdAt']))),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => onEditCustomer(item),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: color,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => onDeleteCustomer(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelectChanged: (_) => onOpenCustomer(item),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias, // 👈 rounded corners ke liye
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12), // 👈 rounded
        border: Border.all(color:  AppColors.divider),
      ),
      child: child,
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required int count,
    required Color badgeColor,
    required Color badgeTextColor,
    required bool initiallyExpanded,
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
    required BuildContext context,
  }) {
    return _buildSectionCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: initiallyExpanded,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
            if (items.isEmpty)
              _buildEmptyMessage(emptyMessage)
            else
              _buildCustomerTable(items),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCustomers = customers.where(_isCompletedCustomer).toList();
    final activeCustomers = customers
        .where((c) => !_isCompletedCustomer(c))
        .toList();

    Widget content;
    if (loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (customers.isEmpty) {
      content = ListView(
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              'No customers found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ),
        ],
      );
    } else {
      content = ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          // Active Leads
          _buildExpansionSection(
            context: context,
            title: 'Active Leads',
            count: activeCustomers.length,
            badgeColor: const Color(0xFFE0E7FF),
            badgeTextColor: const Color(0xFF4338CA),
            initiallyExpanded: true, // 👈 default open
            items: activeCustomers,
            emptyMessage: 'No active leads found',
          ),
          const SizedBox(height: 16),
          // Completed Leads
          _buildExpansionSection(
            context: context,
            title: 'Completed Leads',
            count: completedCustomers.length,
            badgeColor:  AppColors.successLight,
            badgeTextColor:  AppColors.success,
            initiallyExpanded: false,
            items: completedCustomers,
            emptyMessage: 'No completed leads found',
          ),
        ],
      );
    }

    return RefreshIndicator(color: color, onRefresh: onRefresh, child: content);
  }
}
