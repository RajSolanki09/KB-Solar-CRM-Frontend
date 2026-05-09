// lib/screens/Dashboards/Installation_Dashboard/Dashboard/pending_installation.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/installation_model.dart';

// ── Date helpers ──────────────────────────────────────────────────────────────
bool _isOverdue(DateTime? dt) {
  if (dt == null) return false;
  final todayMid = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  return DateTime(dt.year, dt.month, dt.day).isBefore(todayMid);
}

bool _isToday(DateTime? dt) {
  if (dt == null) return false;
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

bool _isFuture(DateTime? dt) {
  if (dt == null) return false;
  final todayMid = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  return DateTime(dt.year, dt.month, dt.day).isAfter(todayMid);
}

enum _Urgency { overdue, today, upcoming, noDate }

_Urgency _urgency(DateTime? dt, InstallationStatus status) {
  if (status == InstallationStatus.installationStarted) {
    if (dt == null) return _Urgency.noDate;
    if (_isToday(dt)) return _Urgency.today;
    if (_isFuture(dt)) return _Urgency.upcoming;
    return _Urgency.noDate;
  }
  if (dt == null) return _Urgency.noDate;
  if (_isOverdue(dt)) return _Urgency.overdue;
  if (_isToday(dt)) return _Urgency.today;
  if (_isFuture(dt)) return _Urgency.upcoming;
  return _Urgency.noDate;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────
class PendingInstallationsScreen extends StatefulWidget {
  final Color appBarColor;
  final VoidCallback? onBack;
  const PendingInstallationsScreen({
    super.key,
    this.appBarColor = AppColors.primary,
    this.onBack,
  });

  @override
  State<PendingInstallationsScreen> createState() =>
      _PendingInstallationsScreenState();
}

class _PendingInstallationsScreenState extends State<PendingInstallationsScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';

  final Map<String, bool> _expanded = {};

  bool _isExpanded(int tabIdx, String urgKey) =>
      _expanded['$tabIdx-$urgKey'] ?? true;

  void _setExpanded(int tabIdx, String urgKey, bool v) {
    if (mounted) setState(() => _expanded['$tabIdx-$urgKey'] = v);
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) return;
        setState(() {
          _search = '';
          _searchCtrl.clear();
        });
      });
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _search = _searchCtrl.text.trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstallationCubit>().fetchInstallations();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────
  List<InstallationModel> _pending(List<InstallationModel> all) =>
      all
          .where(
            (m) =>
                m.status != InstallationStatus.projectCompleted &&
                !(m.projectType.toLowerCase() == 'solar' &&
                    m.status == InstallationStatus.meterInstalled),
          )
          .where(_matchesSearch)
          .toList()
        ..sort(_sortByUrgency);

  List<InstallationModel> _pendingSolar(List<InstallationModel> all) =>
      _pending(all).where((m) => m.projectType.toLowerCase() == 'solar').toList();

  List<InstallationModel> _pendingSprinkler(List<InstallationModel> all) =>
      _pending(all).where((m) => m.projectType.toLowerCase() != 'solar').toList();

  bool _matchesSearch(InstallationModel m) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return m.customerName.toLowerCase().contains(q) ||
        m.phone.contains(_search) ||
        m.address.toLowerCase().contains(q);
  }

  int _sortByUrgency(InstallationModel a, InstallationModel b) {
    const order = {
      _Urgency.overdue: 0,
      _Urgency.today: 1,
      _Urgency.upcoming: 2,
      _Urgency.noDate: 3,
    };
    final ua = order[_urgency(a.scheduledDate, a.status)]!;
    final ub = order[_urgency(b.scheduledDate, b.status)]!;
    if (ua != ub) return ua.compareTo(ub);
    final da = a.scheduledDate, db = b.scheduledDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      builder: (ctx, state) {
        final all = state is InstallationsLoaded
            ? state.installations
            : <InstallationModel>[];

        final pendingAll = _pending(all);
        final pendingSolar = _pendingSolar(all);
        final pendingSprinkler = _pendingSprinkler(all);
        final loading = state is InstallationLoading && all.isEmpty;

        // ── Overdue counts for summary chips ──
        final overdueAll = pendingAll
            .where((m) => _urgency(m.scheduledDate, m.status) == _Urgency.overdue)
            .length;
        final overdueSolar = pendingSolar
            .where((m) => _urgency(m.scheduledDate, m.status) == _Urgency.overdue)
            .length;
        final overdueSprinkler = pendingSprinkler
            .where((m) => _urgency(m.scheduledDate, m.status) == _Urgency.overdue)
            .length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: widget.appBarColor,
            elevation: 0,
            leading: IconButton(
              icon: const AppSvgIcon(
                AppSvgAssets.chevronLeft,
                size: 18,
                color: Colors.white,
              ),
              onPressed: widget.onBack ?? () => Navigator.pop(context),
            ),
            title: const Text(
              'Overdue Installations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
                  onPressed: () =>
                      ctx.read<InstallationCubit>().fetchInstallations(),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade200),
            ),
          ),
          body: Column(
            children: [
              // ── Summary strip ──────────────────────────────────────
              if (overdueAll > 0)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label: 'All',
                        count: overdueAll,
                        color: AppColors.primary,
                        svgAsset: AppSvgAssets.triangleAlert,
                      ),
                      const SizedBox(width: 6),
                      _SummaryChip(
                        label: 'Solar',
                        count: overdueSolar,
                        color: AppColors.primary,
                        svgAsset: AppSvgAssets.sun,
                      ),
                      const SizedBox(width: 6),
                      _SummaryChip(
                        label: 'Sprinkler',
                        count: overdueSprinkler,
                        color: AppColors.primary,
                        svgAsset: AppSvgAssets.droplet,
                      ),
                    ],
                  ),
                ),

              // ── Tabs ──────────────────────────────────────────────
              Container(
                color: Colors.white,
                 child: TabBar(
                   controller: _tab,
                   labelColor: AppColors.primary,
                   unselectedLabelColor: AppColors.textDark,
                   indicatorColor: AppColors.primary,
                   indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvgIcon(AppSvgAssets.clipboardList, size: 14),
                          const SizedBox(width: 4),
                          Text('All ($overdueAll)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvgIcon(AppSvgAssets.sun, size: 14),
                          const SizedBox(width: 4),
                          Text('Solar ($overdueSolar)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvgIcon(AppSvgAssets.droplet, size: 14),
                          const SizedBox(width: 4),
                          Text('Sprinkler ($overdueSprinkler)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search bar ─────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search name, phone, address…',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AppSvgIcon(
                          AppSvgAssets.search,
                          size: 17,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const AppSvgIcon(AppSvgAssets.x, size: 13),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade200),

              // ── Tab views ──────────────────────────────────────────
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _buildTableView(
                            pendingAll,
                            tabIndex: 0,
                            showType: true,
                          ),
                          _buildTableView(
                            pendingSolar,
                            tabIndex: 1,
                            showType: false,
                          ),
                          _buildTableView(
                            pendingSprinkler,
                            tabIndex: 2,
                            showType: false,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Table view — sirf overdue ─────────────────────────────────────────────
  Widget _buildTableView(
    List<InstallationModel> items, {
    required int tabIndex,
    required bool showType,
  }) {
    // ── Sirf overdue filter ──
    final overdue = items
        .where((m) => _urgency(m.scheduledDate, m.status) == _Urgency.overdue)
        .toList();

    if (overdue.isEmpty) {
      return _EmptyState(tabLabel: 'overdue', hasSearch: _search.isNotEmpty);
    }

    return RefreshIndicator(
      color: Colors.red.shade500,
      onRefresh: () async =>
          context.read<InstallationCubit>().fetchInstallations(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minW =
              constraints.maxWidth < 900 ? 920.0 : constraints.maxWidth;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
            children: [
              _UrgencyTableSection(
                urgKey: 'overdue',
                tabIndex: tabIndex,
                label: 'Overdue',
                svgAsset: AppSvgAssets.triangleAlert,
                color: Colors.red.shade500,
                items: overdue,
                minWidth: minW,
                showType: showType,
                expanded: _isExpanded(tabIndex, 'overdue'),
                onExpansionChanged: (v) =>
                    _setExpanded(tabIndex, 'overdue', v),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Urgency Table Section (collapsible)
// ─────────────────────────────────────────────────────────────
class _UrgencyTableSection extends StatelessWidget {
  final String urgKey, label;
  final int tabIndex;
  final String svgAsset;
  final Color color;
  final List<InstallationModel> items;
  final double minWidth;
  final bool showType;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

  const _UrgencyTableSection({
    required this.urgKey,
    required this.tabIndex,
    required this.label,
    required this.svgAsset,
    required this.color,
    required this.items,
    required this.minWidth,
    required this.showType,
    required this.expanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey<String>('pending_${tabIndex}_$urgKey'),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: AppSvgIcon(svgAsset, size: 13, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                '$label (${items.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          children: [
            _PendingDataTable(
              items: items,
              minWidth: minWidth,
              showType: showType,
              accentColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DataTable
// ─────────────────────────────────────────────────────────────
class _PendingDataTable extends StatelessWidget {
  final List<InstallationModel> items;
  final double minWidth;
  final bool showType;
  final Color accentColor;

  const _PendingDataTable({
    required this.items,
    required this.minWidth,
    required this.showType,
    required this.accentColor,
  });

  Color _typeAccent(InstallationModel m) =>
      m.projectType.toLowerCase() == 'solar' ? AppColors.primary : AppColors.primaryLight;

  Color _statusColor(InstallationModel m) {
    switch (m.status) {
      case InstallationStatus.projectCompleted:
      case InstallationStatus.installationCompleted:
      case InstallationStatus.meterInstalled:
        return Colors.green;
      case InstallationStatus.installationStarted:
      case InstallationStatus.meterApplied:
      case InstallationStatus.meterInspection:
        return Colors.orange;
      case InstallationStatus.installationAssigned:
        return Colors.indigo;
    }
  }

  Widget _typeBadge(InstallationModel m) {
    final isSolar = m.projectType.toLowerCase() == 'solar';
    final color = _typeAccent(m);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            isSolar ? AppSvgAssets.sun : AppSvgAssets.droplet,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isSolar ? 'Solar' : 'Sprinkler',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(InstallationModel m) {
    final color = _statusColor(m);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        m.statusLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _progressCell(InstallationModel m) {
    const vals = {
      InstallationStatus.installationAssigned: 1 / 5,
      InstallationStatus.installationCompleted: 2 / 5,
      InstallationStatus.meterApplied: 3 / 5,
      InstallationStatus.meterInspection: 4 / 5,
      InstallationStatus.meterInstalled: 5 / 5,
      InstallationStatus.projectCompleted: 1.0,
    };
    const labels = {
      InstallationStatus.installationAssigned: '1/5',
      InstallationStatus.installationCompleted: '2/5',
      InstallationStatus.meterApplied: '3/5',
      InstallationStatus.meterInspection: '4/5',
      InstallationStatus.meterInstalled: '5/5',
      InstallationStatus.projectCompleted: 'Done',
    };
    final accent = _typeAccent(m);
    final value = vals[m.status] ?? 0.0;
    final label = labels[m.status] ?? '—';

    return SizedBox(
      width: 90,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduledCell(InstallationModel m) {
    final dt = m.scheduledDate;

    if (dt == null) {
      return Text(
        'Date TBD',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      );
    }

    final daysDiff = DateTime.now().difference(dt).inDays;
    final overdueLabel = daysDiff > 0 ? '${daysDiff}d overdue' : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('dd MMM yyyy').format(dt),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade600,
          ),
        ),
        Text(
          DateFormat('hh:mm a').format(dt),
          style: TextStyle(
            fontSize: 10,
            color: Colors.red.shade400,
          ),
        ),
        if (overdueLabel != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red.shade500,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              overdueLabel,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const rowStyle = TextStyle(fontSize: 12, color: Color(0xFF111827));

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            horizontalMargin: isDesktop ? 18 : 12,
            columnSpacing: isDesktop ? 24 : 14,
            headingRowColor: WidgetStateProperty.all(
              Colors.red.shade50,
            ),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.blueGrey.shade50),
              bottom: BorderSide(color: Colors.blueGrey.shade100),
              top: BorderSide(color: Colors.blueGrey.shade100),
            ),
            columns: [
              if (showType) const DataColumn(label: Text('Type')),
              const DataColumn(label: Text('Customer')),
              const DataColumn(label: Text('Phone')),
              const DataColumn(label: Text('Address')),
              const DataColumn(label: Text('Status')),
              const DataColumn(label: Text('Progress')),
              const DataColumn(label: Text('Scheduled')),
              const DataColumn(label: Text('System')),
            ],
            rows: items.map((m) {
              return DataRow(
                cells: [
                  if (showType) DataCell(_typeBadge(m)),
                  DataCell(
                    Text(
                      m.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(m.phone, style: rowStyle)),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 200 : 160,
                      child: Text(
                        m.address.isEmpty ? '—' : m.address,
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle,
                      ),
                    ),
                  ),
                  DataCell(_statusBadge(m)),
                  DataCell(_progressCell(m)),
                  DataCell(_scheduledCell(m)),
                  DataCell(
                    Text(
                      m.systemSize > 0
                          ? '${m.systemSize.toStringAsFixed(m.systemSize % 1 == 0 ? 0 : 1)} kW'
                          : '—',
                      style: rowStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _typeAccent(m),
                      ),
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

// ─────────────────────────────────────────────────────────────
//  Summary Chip
// ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String svgAsset;
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvgIcon(svgAsset, size: 10, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String tabLabel;
  final bool hasSearch;
  const _EmptyState({required this.tabLabel, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              AppSvgAssets.circleCheckBig,
              size: 56,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch
                  ? 'No results found'
                  : 'No overdue $tabLabel installations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different search term.'
                  : 'All clear! No overdue jobs.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}