// lib/screens/Dashboards/Service_Dashboard/My Services/myservices_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/date_time_helper.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/service_detail_screen.dart';
import 'package:solar_project/core/app_colors.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});
  @override
  State<MyServicesPage> createState() => _State();
}

class _State extends State<MyServicesPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _status = 'All';
  DateTime? _date;
  bool _showOlder = false;

  static const _color = AppColors.success;

  DateTime get _recentCutoff => DateTimeHelper.recentCutoff();

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return; 
    context.read<ServiceLeadCubit>().fetchAllServices();
  });
}

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ServiceRequestModel> _filtered(List<ServiceRequestModel> all) {
    return all.where((s) {
      bool matchStatus = true;
      if (_status == 'All')
        matchStatus = !s.isComplete;
      else if (_status == 'Completed')
        matchStatus = s.isComplete;
      else
        matchStatus = s.status == _status;

      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          s.customerName.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.serviceId.toLowerCase().contains(q);

      bool matchDate = true;
      if (_date != null) {
        final d = s.serviceDate ?? s.createdAt;
        matchDate =
            d.year == _date!.year &&
            d.month == _date!.month &&
            d.day == _date!.day;
      }

      return matchStatus && matchSearch && matchDate;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ServiceRequestModel> _recent(List<ServiceRequestModel> f) =>
      f.where((s) => !s.createdAt.isBefore(_recentCutoff)).toList();

  List<ServiceRequestModel> _older(List<ServiceRequestModel> f) =>
      f.where((s) => s.createdAt.isBefore(_recentCutoff)).toList();

  int _count(List<ServiceRequestModel> all, String s) {
    if (s == 'All') return all.where((x) => !x.isComplete).length;
    if (s == 'Completed') return all.where((x) => x.isComplete).length;
    return all.where((x) => x.status == s).length;
  }

  bool get _hasFilter =>
      _date != null || _status != 'All' || _search.isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await DateTimeHelper.pickDateThemed(
      context,
      accentColor: _color,
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _getDateLabel(DateTime? date) =>
      DateTimeHelper.leadDateFilterLabel(date);

  Future<void> _openDetail(
    BuildContext ctx,
    ServiceRequestModel service,
  ) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: ctx.read<ServiceLeadCubit>(),
          child: ServiceDetailScreen(service: service, isAdmin: false),
        ),
      ),
    );
    if (ctx.mounted) ctx.read<ServiceLeadCubit>().fetchAllServices();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned':
        return AppColors.primaryLight;
      case 'In Progress':
        return AppColors.solar;
      case 'Completed':
      case 'Resolved':
        return AppColors.success;
      case 'Open':
      case 'Pending':
        return AppColors.solar;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
          builder: (ctx, state) {
            final all = state is ServiceLeadsLoaded
                ? state.services
                : <ServiceRequestModel>[];

            if (state is ServiceLeadLoading && all.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _color),
              );
            }

            if (state is ServiceLeadError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppSvgIcon(
                      AppSvgAssets.triangleAlert,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ctx.read<ServiceLeadCubit>().fetchAllServices(),
                      icon: const AppSvgIcon(AppSvgAssets.refreshCw),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: _color),
                    ),
                  ],
                ),
              );
            }

            final filtered = _filtered(all);
            final recent = _recent(filtered);
            final older = _older(filtered);
            final width = MediaQuery.of(context).size.width;
            final minWidth = width < 920 ? 980.0 : width;

            return Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Services',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Your assigned jobs',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_hasFilter)
                        TextButton(
                          onPressed: () => setState(() {
                            _date = null;
                            _status = 'All';
                            _searchCtrl.clear();
                            _search = '';
                          }),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const AppSvgIcon(
                          AppSvgAssets.refreshCw,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                        onPressed: () =>
                            ctx.read<ServiceLeadCubit>().fetchAllServices(),
                      ),
                    ],
                  ),
                ),

                // ── Summary bar ──────────────────────────────────────────────
                _SummaryBar(
                  total: _count(all, 'All'),
                  assigned: _count(all, 'Assigned'),
                  inProgress: _count(all, 'In Progress'),
                  completed: _count(all, 'Completed'),
                ),

                // ── Filter row ───────────────────────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search name / phone / ID',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: const AppSvgIcon(
                                  AppSvgAssets.search,
                                  size: 18,
                                  color: _color,
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
                                        color: AppColors.textLight,
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

                      // Status dropdown
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _status != 'All'
                                ? _color.withValues(alpha: 0.5)
                                : AppColors.divider,
                            width: _status != 'All' ? 1.5 : 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            icon: const AppSvgIcon(
                              AppSvgAssets.chevronDown,
                              size: 18,
                              color: _color,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: _status != 'All'
                                  ? _color
                                  : AppColors.textGray,
                              fontWeight: _status != 'All'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            items:
                                ['All', 'Assigned', 'In Progress', 'Completed']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Date picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _date != null ? _color : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _date != null ? _color : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(
                                AppSvgAssets.calendarDays,
                                size: 17,
                                color: _date != null
                                    ? AppColors.surface
                                    : AppColors.textGray,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDateLabel(_date),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _date != null
                                      ? AppColors.surface
                                      : AppColors.textGray,
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
                                    color: AppColors.surface,
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

                // ── Result count ─────────────────────────────────────────────
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} result${filtered.length != 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Tables ───────────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(
                          hasFilter: _hasFilter,
                          onClear: () => setState(() {
                            _date = null;
                            _status = 'All';
                            _searchCtrl.clear();
                            _search = '';
                          }),
                        )
                      : RefreshIndicator(
                          color: _color,
                          onRefresh: () =>
                              ctx.read<ServiceLeadCubit>().fetchAllServices(),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  40,
                                ),
                                children: [
                                  // Last 7 days
                                  _MyServiceTableSection(
                                    title: 'Last 7 Days',
                                    subtitle:
                                        'Your services from the last 7 days',
                                    items: recent,
                                    minWidth: minWidth,
                                    showEmptyMessage: true,
                                    statusColor: _statusColor,
                                    onTap: (s) => _openDetail(ctx, s),
                                    onStart: (s) => ctx
                                        .read<ServiceLeadCubit>()
                                        .updateService(s.id, {
                                          'status': 'In Progress',
                                        }),
                                    onDone: (s) => ctx
                                        .read<ServiceLeadCubit>()
                                        .updateService(s.id, {
                                          'status': 'Completed',
                                        }),
                                  ),

                                  const SizedBox(height: 12),

                                  // Older (collapsible)
                                  _CollapsibleMyServiceTableSection(
                                    title: 'Older Services',
                                    subtitle:
                                        'Older assigned jobs — collapsed by default',
                                    items: older,
                                    minWidth: minWidth,
                                    initiallyExpanded: _showOlder,
                                    onExpansionChanged: (v) =>
                                        setState(() => _showOlder = v),
                                    statusColor: _statusColor,
                                    onTap: (s) => _openDetail(ctx, s),
                                    onStart: (s) => ctx
                                        .read<ServiceLeadCubit>()
                                        .updateService(s.id, {
                                          'status': 'In Progress',
                                        }),
                                    onDone: (s) => ctx
                                        .read<ServiceLeadCubit>()
                                        .updateService(s.id, {
                                          'status': 'Completed',
                                        }),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Non-collapsible section ───────────────────────────────────────────────────
class _MyServiceTableSection extends StatelessWidget {
  final String title, subtitle;
  final List<ServiceRequestModel> items;
  final double minWidth;
  final bool showEmptyMessage;
  final Color Function(String) statusColor;
  final void Function(ServiceRequestModel) onTap;
  final void Function(ServiceRequestModel) onStart;
  final void Function(ServiceRequestModel) onDone;

  const _MyServiceTableSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.minWidth,
    required this.statusColor,
    required this.onTap,
    required this.onStart,
    required this.onDone,
    this.showEmptyMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
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
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.background),
                ),
              ],
            ),
          ),
          if (items.isEmpty && showEmptyMessage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No services in this section.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            )
          else if (items.isNotEmpty)
            _MyServiceDataTable(
              items: items,
              minWidth: minWidth,
              statusColor: statusColor,
              onTap: onTap,
              onStart: onStart,
              onDone: onDone,
            ),
        ],
      ),
    );
  }
}

// ── Collapsible section ───────────────────────────────────────────────────────
class _CollapsibleMyServiceTableSection extends StatelessWidget {
  final String title, subtitle;
  final List<ServiceRequestModel> items;
  final double minWidth;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Color Function(String) statusColor;
  final void Function(ServiceRequestModel) onTap;
  final void Function(ServiceRequestModel) onStart;
  final void Function(ServiceRequestModel) onDone;

  const _CollapsibleMyServiceTableSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.minWidth,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.statusColor,
    required this.onTap,
    required this.onStart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('older_my_services'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          iconColor: AppColors.success,
          collapsedIconColor: AppColors.success,
          title: Text(
            '$title (${items.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: AppColors.background),
          ),
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No older services found.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              )
            else
              _MyServiceDataTable(
                items: items,
                minWidth: minWidth,
                statusColor: statusColor,
                onTap: onTap,
                onStart: onStart,
                onDone: onDone,
              ),
          ],
        ),
      ),
    );
  }
}

// ── DataTable ─────────────────────────────────────────────────────────────────
class _MyServiceDataTable extends StatelessWidget {
  final List<ServiceRequestModel> items;
  final double minWidth;
  final Color Function(String) statusColor;
  final void Function(ServiceRequestModel) onTap;
  final void Function(ServiceRequestModel) onStart;
  final void Function(ServiceRequestModel) onDone;

  const _MyServiceDataTable({
    required this.items,
    required this.minWidth,
    required this.statusColor,
    required this.onTap,
    required this.onStart,
    required this.onDone,
  });

  static const _color = AppColors.success;

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _actionCell(ServiceRequestModel s) {
    if (s.status == 'Assigned') {
      return _ActionBtn(
        label: 'Start',
        svgAsset: AppSvgAssets.play,
        color: AppColors.solar,
        onTap: () => onStart(s),
      );
    }
    if (s.status == 'In Progress') {
      return _ActionBtn(
        label: 'Done',
        svgAsset: AppSvgAssets.check,
        color: AppColors.success,
        onTap: () => onDone(s),
      );
    }
    if (s.isComplete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            AppSvgAssets.circleCheckBig,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Done',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }
    return OutlinedButton(
      onPressed: () => onTap(s),
      style: OutlinedButton.styleFrom(
        foregroundColor: _color,
        side: const BorderSide(color: _color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('View', style: TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const rowStyle = TextStyle(fontSize: 12, color: AppColors.textDark);

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
              _color.withValues(alpha: 0.08),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _color.withValues(alpha: 0.06);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.primary),
              bottom: BorderSide(color: AppColors.primary),
              top: BorderSide(color: AppColors.primary),
            ),
            columns: const [
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Issue')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Charge')),
              DataColumn(label: Text('Visit Date & Time')),
              DataColumn(label: Text('Requested')),
              DataColumn(label: Text('Action')),
            ],
            rows: items.map((s) {
              final sc = statusColor(s.status);
              return DataRow(
                onSelectChanged: (_) => onTap(s),
                cells: [
                  DataCell(
                    Text(
                      s.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(s.phone, style: rowStyle)),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 120 : 100,
                      child: Text(
                        s.issueType ?? '-',
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 160 : 130,
                      child: Text(
                        s.address.isEmpty ? '-' : s.address,
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle,
                      ),
                    ),
                  ),
                  DataCell(_badge(s.status, sc)),
                  DataCell(
                    _badge(
                      s.chargeType,
                      s.chargeType == 'Paid' ? AppColors.solar : Colors.teal,
                    ),
                  ),
                  DataCell(
                    s.serviceDate != null
                        ? Text(
                            '${DateTimeHelper.formatDate(s.serviceDate!)}\n'
                            '${DateTimeHelper.formatTime(s.serviceDate!)}',
                            style: rowStyle.copyWith(
                              color: _color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          )
                        : Text(
                            '-',
                            style: rowStyle.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                  ),
                  DataCell(
                    Text(
                      DateTimeHelper.formatDate(s.createdAt),
                      style: rowStyle,
                    ),
                  ),
                  DataCell(_actionCell(s)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final int total, assigned, inProgress, completed;
  const _SummaryBar({
    required this.total,
    required this.assigned,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('Active', '$total', AppColors.success),
          Container(width: 1, height: 28, color: AppColors.divider),
          _Stat('Assigned', '$assigned', AppColors.primaryLight),
          Container(width: 1, height: 28, color: AppColors.divider),
          _Stat('In Progress', '$inProgress', AppColors.solar),
          Container(width: 1, height: 28, color: AppColors.divider),
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
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(AppSvgAssets.cog, size: 60, color: AppColors.divider),
        const SizedBox(height: 14),
        Text(
          'No Services Found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasFilter ? 'No results for current filters' : 'Pull down to refresh',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        if (hasFilter) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onClear,
            icon: const AppSvgIcon(AppSvgAssets.x, size: 14),
            label: const Text('Clear filters'),
            style: TextButton.styleFrom(foregroundColor: AppColors.background),
          ),
        ],
      ],
    ),
  );
}

// ── Action button (Start / Done) ──────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final String svgAsset;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.svgAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(svgAsset, size: 13, color: AppColors.surface),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    ),
  );
}
