// lib/screens/Dashboards/Service_Dashboard/History/service_history.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/date_time_helper.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/service_detail_screen.dart';
import 'package:solar_project/Helper/app_colors.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});
  @override
  State<ServiceHistoryPage> createState() => _State();
}

class _State extends State<ServiceHistoryPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _charge = 'All'; // All | Free | Paid
  DateTime? _date;
  bool _showOlder = false;

  static const Color _color = AppColors.accent1);

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
    return all.where((s) {
      if (!s.isComplete) return false;

      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          s.customerName.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.serviceId.toLowerCase().contains(q);

      final matchCharge = _charge == 'All' || s.chargeType == _charge;

      bool matchDate = true;
      if (_date != null) {
        final d = s.createdAt;
        matchDate =
            d.year == _date!.year &&
            d.month == _date!.month &&
            d.day == _date!.day;
      }

      return matchSearch && matchCharge && matchDate;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ServiceRequestModel> _recent(List<ServiceRequestModel> f) =>
      f.where((s) => !s.createdAt.isBefore(_recentCutoff)).toList();

  List<ServiceRequestModel> _older(List<ServiceRequestModel> f) =>
      f.where((s) => s.createdAt.isBefore(_recentCutoff)).toList();

  bool get _hasFilter =>
      _date != null || _charge != 'All' || _search.isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await DateTimeHelper.pickDateThemed(
      context,
      accentColor: AppColors.accent1),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _getDateLabel(DateTime? date) => DateTimeHelper.leadDateFilterLabel(date);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: AppColors.accent1),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Service History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_hasFilter)
            TextButton(
              onPressed: () => setState(() {
                _date = null;
                _charge = 'All';
                _searchCtrl.clear();
                _search = '';
              }),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
            onPressed: () =>
                context.read<ServiceLeadCubit>().fetchAllServices(),
          ),
        ],
      ),
      body: BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
        builder: (ctx, state) {
          // ── Loading ─────────────────────────────────────────────────
          if (state is ServiceLeadLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _color),
            );
          }

          // ── Error ───────────────────────────────────────────────────
          if (state is ServiceLeadError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(
                    AppSvgAssets.triangleAlert,
                    size: 52,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.textSecondary),
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

          // ── Loaded ──────────────────────────────────────────────────
          if (state is ServiceLeadsLoaded) {
            final filtered = _filtered(state.services);
            final recent = _recent(filtered);
            final older = _older(filtered);
            final allDone = state.services.where((s) => s.isComplete).toList();
            final width = MediaQuery.of(context).size.width;
            final minWidth = width < 920 ? 980.0 : width;

            return Column(
              children: [
                // ── Summary bar ───────────────────────────────────────
                _SummaryBar(
                  total: allDone.length,
                  free: allDone.where((s) => s.chargeType == 'Free').length,
                  paid: allDone.where((s) => s.chargeType == 'Paid').length,
                  revenue: allDone
                      .where((s) => s.isPaid)
                      .fold(0.0, (sum, s) => sum + s.amount),
                ),

                // ── Filter row ─────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary),
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
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: const AppSvgIcon(
                                  AppSvgAssets.search,
                                  size: 16,
                                  color: AppColors.accent1),
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

                      // Charge dropdown
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _charge != 'All'
                                ? AppColors.accent1).withValues(alpha: 0.5)
                                : AppColors.borderLight,
                            width: _charge != 'All' ? 1.5 : 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _charge,
                            icon: const AppSvgIcon(
                              AppSvgAssets.chevronDown,
                              size: 18,
                              color: AppColors.accent1),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: _charge != 'All'
                                  ? AppColors.accent1)
                                  : AppColors.textSecondary),
                              fontWeight: _charge != 'All'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            items: ['All', 'Free', 'Paid']
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
                              if (v != null) setState(() => _charge = v);
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
                            color: _date != null ? _color : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _date != null
                                  ? _color
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
                                    : AppColors.textSecondary),
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
                                  child: AppSvgIcon(
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

                // ── Result count ───────────────────────────────────────
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} result${filtered.length != 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.shade600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Tables ─────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(
                          hasFilter: _hasFilter,
                          onClear: () => setState(() {
                            _date = null;
                            _charge = 'All';
                            _searchCtrl.clear();
                            _search = '';
                          }),
                        )
                      : RefreshIndicator(
                          color: AppColors.accent1),
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
                                  _HistoryTableSection(
                                    title: 'Last 7 Days',
                                    subtitle:
                                        'Services completed in the last 7 days',
                                    items: recent,
                                    minWidth: minWidth,
                                    showEmptyMessage: true,
                                    onTap: (s) => _openDetail(ctx, s),
                                  ),

                                  const SizedBox(height: 12),

                                  // Older (collapsible)
                                  _CollapsibleHistoryTableSection(
                                    title: 'Older History',
                                    subtitle:
                                        'Older completed records — collapsed by default',
                                    items: older,
                                    minWidth: minWidth,
                                    initiallyExpanded: _showOlder,
                                    onExpansionChanged: (v) =>
                                        setState(() => _showOlder = v),
                                    onTap: (s) => _openDetail(ctx, s),
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

// ── Non-collapsible section ───────────────────────────────────────────────────
class _HistoryTableSection extends StatelessWidget {
  final String title, subtitle;
  final List<ServiceRequestModel> items;
  final double minWidth;
  final bool showEmptyMessage;
  final void Function(ServiceRequestModel) onTap;

  const _HistoryTableSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.minWidth,
    required this.onTap,
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
                'No history in this section.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else if (items.isNotEmpty)
            _HistoryDataTable(items: items, minWidth: minWidth, onTap: onTap),
        ],
      ),
    );
  }
}

// ── Collapsible section ───────────────────────────────────────────────────────
class _CollapsibleHistoryTableSection extends StatelessWidget {
  final String title, subtitle;
  final List<ServiceRequestModel> items;
  final double minWidth;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final void Function(ServiceRequestModel) onTap;

  const _CollapsibleHistoryTableSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.minWidth,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onTap,
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
          key: const ValueKey('older_history'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          iconColor: AppColors.accent1),
          collapsedIconColor: AppColors.success),
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
                    'No older history found.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              _HistoryDataTable(items: items, minWidth: minWidth, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

// ── DataTable ─────────────────────────────────────────────────────────────────
class _HistoryDataTable extends StatelessWidget {
  final List<ServiceRequestModel> items;
  final double minWidth;
  final void Function(ServiceRequestModel) onTap;

  const _HistoryDataTable({
    required this.items,
    required this.minWidth,
    required this.onTap,
  });

  static const _color = AppColors.accent1);

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
              _color.withValues(alpha: 0.08),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _color.withValues(alpha: 0.06);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.blueGrey.shade50),
              bottom: BorderSide(color: Colors.blueGrey.shade100),
              top: BorderSide(color: Colors.blueGrey.shade100),
            ),
            columns: const [
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Issue')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('Charge')),
              DataColumn(label: Text('Payment')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Assigned To')),
              DataColumn(label: Text('Completed')),
              DataColumn(label: Text('Action')),
            ],
            rows: items.map((s) {
              final payColor = s.isPaid ? Colors.green : Colors.red;
              final payLabel = s.isPaid ? 'Paid' : 'Unpaid';

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
                  DataCell(
                    _badge(
                      s.chargeType,
                      s.chargeType == 'Paid' ? Colors.orange : Colors.teal,
                    ),
                  ),
                  DataCell(_badge(payLabel, payColor)),
                  DataCell(
                    s.isPaid && s.amount > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppSvgIcon(
                                AppSvgAssets.indianRupee,
                                size: 11,
                                color: AppColors.warning,
                              ),
                              Text(
                                s.amount.toStringAsFixed(0),
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
                    SizedBox(
                      width: isDesktop ? 120 : 100,
                      child: Text(
                        s.assignedToName ?? '-',
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle.copyWith(
                          color: s.assignedToName != null
                              ? AppColors.textPrimary)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      DateTimeHelper.formatDate(s.createdAt),
                      style: rowStyle,
                    ),
                  ),
                  DataCell(
                    OutlinedButton(
                      onPressed: () => onTap(s),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _color,
                        side: const BorderSide(color: _color),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View', style: TextStyle(fontSize: 12)),
                    ),
                  ),
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
  final int total, free, paid;
  final double revenue;
  const _SummaryBar({
    required this.total,
    required this.free,
    required this.paid,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('Total', '$total', AppColors.accent1)),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _Stat('Free', '$free', AppColors.accent1)),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _Stat('Paid', '$paid', AppColors.accent1)),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _Stat('Revenue', '₹${revenue.toStringAsFixed(0)}', AppColors.accent1)),
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
  final bool hasFilter;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(AppSvgAssets.history, size: 60, color: AppColors.borderLight),
        const SizedBox(height: 14),
        Text(
          hasFilter
              ? 'No results for this filter'
              : 'No completed services yet',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasFilter ? 'Try changing your filters' : 'Pull down to refresh',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (hasFilter) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onClear,
              icon: const AppSvgIcon(AppSvgAssets.x, size: 14),
            label: const Text('Clear all filters'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ],
      ],
    ),
  );
}







