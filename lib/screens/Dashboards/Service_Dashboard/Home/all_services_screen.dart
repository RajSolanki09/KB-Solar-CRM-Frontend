// lib/screens/Dashboards/Service_Dashboard/all_services_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Helper/date_time_helper.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/service_detail_screen.dart';
import 'package:solar_project/Helper/app_colors.dart';

enum ServiceFilter {
  all,
  today,
  pending,
  inProgress,
  completed,
  free,
  paid;

  String get label {
    switch (this) {
      case all:
        return 'All Services';
      case today:
        return 'Today';
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case free:
        return 'Free Services';
      case paid:
        return 'Paid Services';
    }
  }

  String get icon {
    switch (this) {
      case all:
        return AppSvgAssets.clipboardList;
      case today:
        return AppSvgAssets.calendarDays;
      case pending:
        return AppSvgAssets.clock;
      case inProgress:
        return AppSvgAssets.refreshCw;
      case completed:
        return AppSvgAssets.circleCheckBig;
      case free:
        return AppSvgAssets.handshake;
      case paid:
        return AppSvgAssets.indianRupee;
    }
  }

  Color get color {
    switch (this) {
      case all:
        return AppColors.primary);
      case today:
        return AppColors.primary);
      case pending:
        return AppColors.primary);
      case inProgress:
        return AppColors.primary);
      case completed:
        return AppColors.primary);
      case free:
        return AppColors.primary);
      case paid:
        return AppColors.primary);
    }
  }
}

class AllServicesScreen extends StatefulWidget {
  final ServiceFilter initialFilter;
  final bool isAdmin;
  const AllServicesScreen({
    super.key,
    this.initialFilter = ServiceFilter.all,
    this.isAdmin = false,
  });
  @override
  State<AllServicesScreen> createState() => _State();
}

class _State extends State<AllServicesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  DateTime? _date;
  bool _showOlder = false;

  DateTime get _recentCutoff => DateTimeHelper.recentCutoff();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ServiceLeadCubit>().fetchAllServices(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ServiceRequestModel> _filtered(List<ServiceRequestModel> all) {
    final now = DateTime.now();
    return all.where((s) {
      // ── Category filter ───────────────────────────────────────────────
      bool cat = true;
      switch (widget.initialFilter) {
        case ServiceFilter.all:
          cat = !s.isComplete;
          break;
        case ServiceFilter.today:
          final d = s.serviceDate ?? s.createdAt;
          cat = d.year == now.year && d.month == now.month && d.day == now.day;
          break;
        case ServiceFilter.pending:
          cat = s.status == 'Open' || s.status == 'Pending';
          break;
        case ServiceFilter.inProgress:
          cat = s.status == 'In Progress' || s.status == 'inProgress';
          break;
        case ServiceFilter.completed:
          cat = s.isComplete;
          break;
        case ServiceFilter.free:
          cat = s.chargeType == 'Free' && !s.isComplete;
          break;
        case ServiceFilter.paid:
          cat = s.chargeType == 'Paid' && !s.isComplete;
          break;
      }

      // ── Search ────────────────────────────────────────────────────────
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          s.customerName.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.serviceId.toLowerCase().contains(q);

      // ── Date filter ───────────────────────────────────────────────────
      bool matchDate = true;
      if (_date != null) {
        final d = s.serviceDate ?? s.createdAt;
        matchDate =
            d.year == _date!.year &&
            d.month == _date!.month &&
            d.day == _date!.day;
      }

      return cat && matchSearch && matchDate;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await DateTimeHelper.pickDateThemed(
      context,
      accentColor: widget.initialFilter.color,
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _getDateLabel(DateTime? date) => DateTimeHelper.leadDateFilterLabel(date);

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned':
        return const Color(0xFF2193b0);
      case 'In Progress':
        return const Color(0xFFFF8008);
      case 'Completed':
      case 'Resolved':
        return const Color(0xFF11998e);
      case 'Open':
      case 'Pending':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.initialFilter;
    final color = f.color;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: color,
        elevation: 0,
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          f.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
            onPressed: () =>
                context.read<ServiceLeadCubit>().fetchAllServices(),
          ),
        ],
      ),
      body: BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
        builder: (ctx, state) {
          if (state is ServiceLeadLoading) {
            return Center(child: CircularProgressIndicator(color: color));
          }

          if (state is ServiceLeadError) {
            return _ErrorView(
              color: color,
              message: state.message,
              onRetry: () => ctx.read<ServiceLeadCubit>().fetchAllServices(),
            );
          }

          if (state is ServiceLeadsLoaded) {
            final list = _filtered(state.services);

            // Split into recent (last 7 days) and older
            final sorted = [...list]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final recent = sorted
                .where((s) => !(s.createdAt.isBefore(_recentCutoff)))
                .toList();
            final older = sorted
                .where((s) => s.createdAt.isBefore(_recentCutoff))
                .toList();

            return Column(
              children: [
                // ── Summary Bar ───────────────────────────────────────────
                _SummaryBar(
                  total: state.services.length,
                  pending: state.services
                      .where((s) => s.status == 'Open' || s.status == 'Pending')
                      .length,
                  completed: state.services.where((s) => s.isComplete).length,
                  color: color,
                ),

                // ── Filter bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search name / phone / ID',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: Expanded(
                                child: AppSvgIcon(
                                  AppSvgAssets.search,
                                  size: 18,
                                  color: color,
                                ),
                              ),
                              suffixIcon: _search.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() => _search = '');
                                      },
                                      child: AppSvgIcon(
                                        AppSvgAssets.x,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Calendar button
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _date != null ? color : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _date != null
                                  ? color
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(
                                AppSvgAssets.calendarDays,
                                size: 17,
                                color: _date != null
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDateLabel(_date),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _date != null
                                      ? Colors.white
                                      : AppColors.textSecondary),
                                  fontWeight: _date != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (_date != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() => _date = null),
                                  child: const AppSvgIcon(
                                    AppSvgAssets.x,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Result count ──────────────────────────────────────────
                if (list.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${list.length} result${list.length != 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.shade600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Table list ────────────────────────────────────────────
                Expanded(
                  child: list.isEmpty
                      ? _EmptyState(
                          filter: f,
                          hasDateFilter: _date != null,
                          onClear: () => setState(() => _date = null),
                        )
                      : RefreshIndicator(
                          color: color,
                          onRefresh: () =>
                              ctx.read<ServiceLeadCubit>().fetchAllServices(),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final minWidth = math.max(constraints.maxWidth, 1020.0);
                              final showAmountColumn =
                                  f != ServiceFilter.free;
                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  40,
                                ),
                                children: [
                                  // ── Recent: last 7 days ───────────────────
                                  _ServiceTableSection(
                                    title: 'Last 7 Days',
                                    subtitle:
                                        'Services created in the last 7 days',
                                    items: recent
                                        .map(
                                          (s) => _ServiceTableItem(
                                            customerName: s.customerName,
                                            phone: s.phone,
                                            address: s.address,
                                            issueType: s.issueType ?? '-',
                                            status: s.status,
                                            chargeType: s.chargeType,
                                            priority: s.priority,
                                            assignedTo: s.assignedToName ?? '-',
                                            amount: s.isPaid && s.amount > 0
                                                ? s.amount
                                                : null,
                                            serviceDateTime: s.serviceDate,
                                            color: color,
                                            statusColor: _statusColor(s.status),
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BlocProvider.value(
                                                        value: ctx
                                                            .read<
                                                              ServiceLeadCubit
                                                            >(),
                                                        child:
                                                            ServiceDetailScreen(
                                                              service: s,
                                                              isAdmin: widget
                                                                  .isAdmin,
                                                            ),
                                                      ),
                                                ),
                                              );
                                              if (ctx.mounted) {
                                                ctx
                                                    .read<ServiceLeadCubit>()
                                                    .fetchAllServices();
                                              }
                                            },
                                          ),
                                        )
                                        .toList(),
                                    color: color,
                                    minWidth: minWidth,
                                    showAmountColumn: showAmountColumn,
                                    showEmptyMessage: true,
                                  ),

                                  const SizedBox(height: 12),

                                  // ── Older (collapsible) ───────────────────
                                  _CollapsibleServiceTableSection(
                                    title: 'Older Services',
                                    subtitle:
                                        'Older service records — collapsed by default',
                                    items: older
                                        .map(
                                          (s) => _ServiceTableItem(
                                            customerName: s.customerName,
                                            phone: s.phone,
                                            address: s.address,
                                            issueType: s.issueType ?? '-',
                                            status: s.status,
                                            chargeType: s.chargeType,
                                            priority: s.priority,
                                            assignedTo: s.assignedToName ?? '-',
                                            amount: s.isPaid && s.amount > 0
                                                ? s.amount
                                                : null,
                                            serviceDateTime: s.serviceDate,
                                            color: color,
                                            statusColor: _statusColor(s.status),
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BlocProvider.value(
                                                        value: ctx
                                                            .read<
                                                              ServiceLeadCubit
                                                            >(),
                                                        child:
                                                            ServiceDetailScreen(
                                                              service: s,
                                                              isAdmin: widget
                                                                  .isAdmin,
                                                            ),
                                                      ),
                                                ),
                                              );
                                              if (ctx.mounted) {
                                                ctx
                                                    .read<ServiceLeadCubit>()
                                                    .fetchAllServices();
                                              }
                                            },
                                          ),
                                        )
                                        .toList(),
                                    color: color,
                                    minWidth: minWidth,
                                    initiallyExpanded: _showOlder,
                                    onExpansionChanged: (v) =>
                                        setState(() => _showOlder = v),
                                    showAmountColumn: showAmountColumn,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Data class for one table row ──────────────────────────────────────────────
class _ServiceTableItem {
  final String customerName;
  final String phone;
  final String address;
  final String issueType;
  final String status;
  final String chargeType;
  final String priority;
  final String assignedTo;
  final double? amount;
  final DateTime? serviceDateTime;
  final Color color;
  final Color statusColor;
  final VoidCallback onTap;

  const _ServiceTableItem({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.issueType,
    required this.status,
    required this.chargeType,
    required this.priority,
    required this.assignedTo,
    required this.amount,
    required this.serviceDateTime,
    required this.color,
    required this.statusColor,
    required this.onTap,
  });
}

// ── Non-collapsible section ───────────────────────────────────────────────────
class _ServiceTableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ServiceTableItem> items;
  final Color color;
  final double minWidth;
  final bool showEmptyMessage;
  final bool showAmountColumn;

  const _ServiceTableSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.color,
    required this.minWidth,
    required this.showAmountColumn,
    this.showEmptyMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title (${items.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (items.isEmpty && showEmptyMessage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No services in this section.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else if (items.isNotEmpty)
            _ServiceDataTable(
              items: items,
              color: color,
              minWidth: minWidth,
              showAmountColumn: showAmountColumn,
            ),
        ],
      ),
    );
  }
}

// ── Collapsible section ───────────────────────────────────────────────────────
class _CollapsibleServiceTableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ServiceTableItem> items;
  final Color color;
  final double minWidth;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final bool showAmountColumn;

  const _CollapsibleServiceTableSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.color,
    required this.minWidth,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.showAmountColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('older_services'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          iconColor: color,
          collapsedIconColor: color,
          title: Text(
            '$title (${items.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No older services found.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              _ServiceDataTable(
                items: items,
                color: color,
                minWidth: minWidth,
                showAmountColumn: showAmountColumn,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Actual DataTable ──────────────────────────────────────────────────────────
class _ServiceDataTable extends StatelessWidget {
  final List<_ServiceTableItem> items;
  final Color color;
  final double minWidth;
  final bool showAmountColumn;

  const _ServiceDataTable({
    required this.items,
    required this.color,
    required this.minWidth,
    required this.showAmountColumn,
  });

  Widget _statusBadge(String status, Color sc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sc.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sc.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc),
      ),
    );
  }

  Widget _chip(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
    ),
  );

  Color _priorityColor(String p) {
    switch (p) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return const Color(0xFF4e54c8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const rowStyle = TextStyle(fontSize: 12, color: AppColors.textPrimary));

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 44,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 56,
            horizontalMargin: isDesktop ? 12 : 8,
            columnSpacing: isDesktop ? 14 : 8,
            headingRowColor: WidgetStateProperty.all(
              color.withValues(alpha: 0.08),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return color.withValues(alpha: 0.06);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.blueGrey.shade50),
              bottom: BorderSide(color: Colors.blueGrey.shade100),
              top: BorderSide(color: Colors.blueGrey.shade100),
            ),
            columns: [
              const DataColumn(label: Text('Customer')),
              const DataColumn(label: Text('Mobile')),
              const DataColumn(label: Text('Issue')),
              const DataColumn(label: Text('Address')),
              const DataColumn(label: Text('Status')),
              const DataColumn(label: Text('Charge')),
              const DataColumn(label: Text('Priority')),
              const DataColumn(label: Text('Assigned To')),
              if (showAmountColumn) const DataColumn(label: Text('Amount')),
              const DataColumn(label: Text('Service Date & Time')),
            ],
            rows: items
                .map(
                  (item) => DataRow(
                    onSelectChanged: (_) => item.onTap(),
                    cells: [
                      DataCell(
                        Text(
                          item.customerName,
                          style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(item.phone, style: rowStyle)),
                      DataCell(
                        SizedBox(
                          width: isDesktop ? 130 : 110,
                          child: Text(
                            item.issueType,
                            overflow: TextOverflow.ellipsis,
                            style: rowStyle,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: isDesktop ? 200 : 160,
                          child: Text(
                            item.address.isEmpty ? '-' : item.address,
                            overflow: TextOverflow.ellipsis,
                            style: rowStyle,
                          ),
                        ),
                      ),
                      DataCell(_statusBadge(item.status, item.statusColor)),
                      DataCell(
                        _chip(
                          item.chargeType,
                          item.chargeType == 'Paid'
                              ? Colors.orange
                              : Colors.teal,
                        ),
                      ),
                      DataCell(
                        _chip(item.priority, _priorityColor(item.priority)),
                      ),
                      DataCell(
                        SizedBox(
                          width: isDesktop ? 120 : 100,
                          child: Text(
                            item.assignedTo,
                            overflow: TextOverflow.ellipsis,
                            style: rowStyle,
                          ),
                        ),
                      ),
                      if (showAmountColumn)
                        DataCell(
                          item.amount != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppSvgIcon(
                                      AppSvgAssets.indianRupee,
                                      size: 11,
                                      color: AppColors.warning,
                                    ),
                                    Text(
                                      item.amount!.toStringAsFixed(0),
                                      style: rowStyle.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                )
                              : Text('-', style: rowStyle),
                        ),
                      DataCell(
                        item.serviceDateTime != null
                            ? Text(
                                '${DateTimeHelper.formatDate(item.serviceDateTime!)}\n'
                                '${DateTimeHelper.formatTime(item.serviceDateTime!)}',
                                style: rowStyle.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              )
                            : Text(
                                '-',
                                style: rowStyle.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final int total, pending, completed;
  final Color color;
  const _SummaryBar({
    required this.total,
    required this.pending,
    required this.completed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('Total', '$total', color),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _Stat('Pending', '$pending', AppColors.warning),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _Stat('Completed', '$completed', AppColors.success),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary.shade600)),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ServiceFilter filter;
  final bool hasDateFilter;
  final VoidCallback onClear;
  const _EmptyState({
    required this.filter,
    required this.hasDateFilter,
    required this.onClear,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(filter.icon, size: 60, color: AppColors.borderLight),
        const SizedBox(height: 14),
        Text(
          'No ${filter.label}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasDateFilter ? 'No data for selected date' : 'Pull down to refresh',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (hasDateFilter) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onClear,
            icon: const AppSvgIcon(AppSvgAssets.x, size: 14),
            label: const Text('Clear date'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ],
      ],
    ),
  );
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final Color color;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.color,
    required this.message,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(AppSvgAssets.triangleAlert, size: 52, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const AppSvgIcon(AppSvgAssets.refreshCw),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: color),
        ),
      ],
    ),
  );
}

// ── Wrappers ──────────────────────────────────────────────────────────────────
class TotalServicesPage extends AllServicesScreen {
  const TotalServicesPage({super.key})
    : super(initialFilter: ServiceFilter.all);
}

class TodayServicesPage extends AllServicesScreen {
  const TodayServicesPage({super.key})
    : super(initialFilter: ServiceFilter.today);
}

class PendingServicesPage extends AllServicesScreen {
  const PendingServicesPage({super.key})
    : super(initialFilter: ServiceFilter.pending);
}

class CompletedServicesPage extends AllServicesScreen {
  const CompletedServicesPage({super.key})
    : super(initialFilter: ServiceFilter.completed);
}

class FreeServicesPage extends AllServicesScreen {
  const FreeServicesPage({super.key})
    : super(initialFilter: ServiceFilter.free);
}

class PaidServicesPage extends AllServicesScreen {
  const PaidServicesPage({super.key})
    : super(initialFilter: ServiceFilter.paid);
}







