// lib/screens/Dashboards/Installation_Dashboard/History/complete_installation.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_cubit.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/data/Models/installation_model.dart';
import 'package:solar_project/core/app_colors.dart';

const _kGreen = AppColors.primary;
const _kPurple = AppColors.primary;
const _kBlue = AppColors.primaryLight;

class CompletedInstallationsScreen extends StatefulWidget {
  const CompletedInstallationsScreen({super.key});

  @override
  State<CompletedInstallationsScreen> createState() =>
      _CompletedInstallationsScreenState();
}

class _CompletedInstallationsScreenState
    extends State<CompletedInstallationsScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  List<InstallationModel> _allCompleted = [];
  List<InstallationModel> _solarCompleted = [];
  List<InstallationModel> _sprinklerCompleted = [];
  int _thisMonthCount = 0;
  int _thisWeekCount = 0;

  // collapsible state per month-group: key = '$tabIndex-$monthKey'
  final Map<String, bool> _monthExpanded = {};

  bool _isMonthExpanded(int tabIdx, String monthKey) =>
      _monthExpanded['$tabIdx-$monthKey'] ?? true;

  void _setMonthExpanded(int tabIdx, String monthKey, bool v) {
    if (mounted) setState(() => _monthExpanded['$tabIdx-$monthKey'] = v);
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) return;
        if (mounted) {
          setState(() {
            _search = '';
            _searchCtrl.clear();
          });
        }
      });
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _search = _searchCtrl.text.trim());
    });
    Future.microtask(() {
      if (mounted) context.read<InstallationCubit>().fetchInstallations();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _computeLists(List<InstallationModel> all) {
    final now = DateTime.now();
    final completed =
        all
            .where((m) => m.projectCompleted)
            .where(_matchesSearch)
            .where(_matchesDateRange)
            .toList()
          ..sort((a, b) {
            final da =
                a.projectCompletedAt ?? a.completedDate ?? a.assignedDate;
            final db =
                b.projectCompletedAt ?? b.completedDate ?? b.assignedDate;
            return db.compareTo(da);
          });

    _allCompleted = completed;
    _solarCompleted = completed
        .where((m) => m.projectType.toLowerCase() == 'solar')
        .toList();
    _sprinklerCompleted = completed
        .where((m) => m.projectType.toLowerCase() != 'solar')
        .toList();

    _thisMonthCount = completed.where((m) {
      final d = m.projectCompletedAt ?? m.completedDate ?? m.assignedDate;
      return d.year == now.year && d.month == now.month;
    }).length;

    _thisWeekCount = completed.where((m) {
      final d = m.projectCompletedAt ?? m.completedDate ?? m.assignedDate;
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekMid = DateTime(weekStart.year, weekStart.month, weekStart.day);
      return !DateTime(d.year, d.month, d.day).isBefore(weekMid);
    }).length;
  }

  bool _matchesSearch(InstallationModel m) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return m.customerName.toLowerCase().contains(q) ||
        m.phone.contains(_search) ||
        m.address.toLowerCase().contains(q);
  }

  bool _matchesDateRange(InstallationModel m) {
    if (_fromDate == null && _toDate == null) return true;
    final d = m.projectCompletedAt ?? m.completedDate ?? m.assignedDate;
    final dMid = DateTime(d.year, d.month, d.day);
    if (_fromDate != null && dMid.isBefore(_fromDate!)) return false;
    if (_toDate != null && dMid.isAfter(_toDate!)) return false;
    return true;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kGreen,
            onPrimary: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
    }
  }

  String _dateRangeLabel() {
    if (_fromDate == null && _toDate == null) return 'All Time';
    final fmt = DateFormat('d MMM');
    if (_fromDate != null && _toDate != null) {
      if (_fromDate == _toDate) return fmt.format(_fromDate!);
      return '${fmt.format(_fromDate!)} – ${fmt.format(_toDate!)}';
    }
    return 'Filtered';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      buildWhen: (prev, curr) =>
          curr is InstallationsLoaded ||
          curr is InstallationLoading ||
          curr is InstallationError,
      builder: (ctx, state) {
        final all = state is InstallationsLoaded
            ? state.installations
            : <InstallationModel>[];
        final loading = state is InstallationLoading && all.isEmpty;

        if (state is InstallationsLoaded) _computeLists(all);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: _kGreen,
            elevation: 0,
            leading: IconButton(
              icon: const AppSvgIcon(
                AppSvgAssets.chevronLeft,
                size: 18,
                color: AppColors.surface,
              ),
              onPressed: () => ctx.read<InstallationNavCubit>().changePage(
                InstallationNavPage.dashboard,
              ),
            ),
            title: const Text(
              'Completed Installations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
            actions: [
              if (state is InstallationLoading && all.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const AppSvgIcon(
                    AppSvgAssets.refreshCw,
                    color: AppColors.surface,
                  ),
                  onPressed: () =>
                      ctx.read<InstallationCubit>().fetchInstallations(),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.divider),
            ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator(color: _kGreen))
              : state is InstallationError
              ? Center(
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
                            ctx.read<InstallationCubit>().fetchInstallations(),
                        icon: const AppSvgIcon(AppSvgAssets.refreshCw),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Summary strip ───────────────────────────────
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(
                        children: [
                          _SummaryChip(
                            label: 'Total',
                            count: _allCompleted.length,
                            color: _kGreen,
                            svgAsset: AppSvgAssets.circleCheckBig,
                          ),
                          const SizedBox(width: 6),
                          _SummaryChip(
                            label: 'This Week',
                            count: _thisWeekCount,
                            color: _kPurple,
                            svgAsset: AppSvgAssets.calendarDays,
                          ),
                          const SizedBox(width: 6),
                          _SummaryChip(
                            label: 'This Month',
                            count: _thisMonthCount,
                            color: _kBlue,
                            svgAsset: AppSvgAssets.calendarDays,
                          ),
                          const SizedBox(width: 6),
                          _SummaryChip(
                            label: '☀ / 💧',
                            count: _solarCompleted.length,
                            secondCount: _sprinklerCompleted.length,
                            color: AppColors.solar,
                            svgAsset: AppSvgAssets.chevronRight,
                          ),
                        ],
                      ),
                    ),

                    // ── Tabs ────────────────────────────────────────
                     Container(
                       color: AppColors.surface,
                       child: TabBar(
                         controller: _tab,
                         labelColor: _kGreen,
                         unselectedLabelColor: AppColors.primaryDark,
                         indicatorColor: _kGreen,
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
                                const AppSvgIcon(
                                  AppSvgAssets.clipboardList,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text('All (${_allCompleted.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppSvgIcon(AppSvgAssets.sun, size: 14),
                                const SizedBox(width: 4),
                                Text('Solar (${_solarCompleted.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppSvgIcon(
                                  AppSvgAssets.droplet,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sprinkler (${_sprinklerCompleted.length})',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Search + date range bar ──────────────────────
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search name, phone, address…',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AppSvgIcon(
                                      AppSvgAssets.search,
                                      size: 17,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const AppSvgIcon(
                                            AppSvgAssets.x,
                                            size: 13,
                                          ),
                                          onPressed: () => _searchCtrl.clear(),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _kGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _pickDateRange,
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: (_fromDate != null || _toDate != null)
                                    ? _kGreen
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (_fromDate != null || _toDate != null)
                                      ? _kGreen
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   AppSvgIcon(
                                     AppSvgAssets.calendarDays,
                                     size: 15,
                                     color:
                                         (_fromDate != null || _toDate != null)
                                         ? AppColors.surface
                                         : AppColors.primaryDark,
                                   ),
                                  const SizedBox(width: 5),
                                   Text(
                                     _dateRangeLabel(),
                                     style: TextStyle(
                                       fontSize: 11,
                                       fontWeight: FontWeight.w600,
                                       color:
                                           (_fromDate != null || _toDate != null)
                                           ? AppColors.surface
                                           : AppColors.primaryDark,
                                     ),
                                   ),
                                  if (_fromDate != null || _toDate != null) ...[
                                    const SizedBox(width: 5),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _fromDate = null;
                                        _toDate = null;
                                      }),
                                      child: const AppSvgIcon(
                                        AppSvgAssets.x,
                                        size: 13,
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

                    Divider(height: 1, color: AppColors.divider),

                    // ── Tab views ────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _buildTableView(
                            _allCompleted,
                            tabIndex: 0,
                            showType: true,
                          ),
                          _buildTableView(
                            _solarCompleted,
                            tabIndex: 1,
                            showType: false,
                          ),
                          _buildTableView(
                            _sprinklerCompleted,
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

  // ── Table view — grouped by month ─────────────────────────────────────────
  Widget _buildTableView(
    List<InstallationModel> items, {
    required int tabIndex,
    required bool showType,
  }) {
    if (items.isEmpty) {
      return _EmptyState(
        tabLabel: 'completed',
        hasSearch: _search.isNotEmpty || _fromDate != null,
      );
    }

    // Group by month
    final Map<String, List<InstallationModel>> grouped = {};
    for (final m in items) {
      final d = m.projectCompletedAt ?? m.completedDate ?? m.assignedDate;
      final key = DateFormat('MMMM yyyy').format(d);
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return RefreshIndicator(
      color: _kGreen,
      onRefresh: () async =>
          context.read<InstallationCubit>().fetchInstallations(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minW = constraints.maxWidth < 900
              ? 940.0
              : constraints.maxWidth;

          final sections = <Widget>[];
          for (final entry in grouped.entries) {
            sections.add(
              _MonthTableSection(
                monthKey: entry.key,
                tabIndex: tabIndex,
                items: entry.value,
                minWidth: minW,
                showType: showType,
                expanded: _isMonthExpanded(tabIndex, entry.key),
                onExpansionChanged: (v) =>
                    _setMonthExpanded(tabIndex, entry.key, v),
              ),
            );
            sections.add(const SizedBox(height: 10));
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
            children: sections,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Month Table Section (collapsible)
// ─────────────────────────────────────────────────────────────
class _MonthTableSection extends StatelessWidget {
  final String monthKey;
  final int tabIndex;
  final List<InstallationModel> items;
  final double minWidth;
  final bool showType;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

  const _MonthTableSection({
    required this.monthKey,
    required this.tabIndex,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const AppSvgIcon(
                  AppSvgAssets.calendarDays,
                  size: 13,
                  color: _kGreen,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$monthKey (${items.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kGreen,
                ),
              ),
            ],
          ),
          children: [
            _CompletedDataTable(
              items: items,
              minWidth: minWidth,
              showType: showType,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DataTable — non-clickable rows
// ─────────────────────────────────────────────────────────────
class _CompletedDataTable extends StatelessWidget {
  final List<InstallationModel> items;
  final double minWidth;
  final bool showType;

  const _CompletedDataTable({
    required this.items,
    required this.minWidth,
    required this.showType,
  });

  Color _typeAccent(InstallationModel m) =>
      m.projectType.toLowerCase() == 'solar' ? _kPurple : _kBlue;

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

  Widget _completedDateCell(InstallationModel m) {
    final dt = m.projectCompletedAt ?? m.completedDate ?? m.assignedDate;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvgIcon(
              AppSvgAssets.circleCheckBig,
              size: 10,
              color: _kGreen,
            ),
            const SizedBox(width: 3),
            Text(
              DateFormat('dd MMM yyyy').format(dt),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kGreen,
              ),
            ),
          ],
        ),
        Text(
          DateFormat('hh:mm a').format(dt),
          style: TextStyle(
            fontSize: 10,
            color: _kGreen.withValues(alpha: 0.75),
          ),
        ),
      ],
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
            dataRowMinHeight: 56,
            dataRowMaxHeight: 68,
            horizontalMargin: isDesktop ? 18 : 12,
            columnSpacing: isDesktop ? 24 : 14,
            // ── Non-clickable: no onSelectChanged, no hover colour ────────
            headingRowColor: WidgetStateProperty.all(
              _kGreen.withValues(alpha: 0.07),
            ),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.primary),
              bottom: BorderSide(color: AppColors.primary),
              top: BorderSide(color: AppColors.primary),
            ),
            columns: [
              if (showType) const DataColumn(label: Text('Type')),
              const DataColumn(label: Text('Customer')),
              const DataColumn(label: Text('Phone')),
              const DataColumn(label: Text('Address')),
              const DataColumn(label: Text('System')),
              const DataColumn(label: Text('Completed On')),
              const DataColumn(label: Text('Assigned By')),
            ],
            rows: items.map((m) {
              final accent = _typeAccent(m);
              return DataRow(
                // ── NO onSelectChanged — display only ─────────────────────
                cells: [
                  if (showType) DataCell(_typeBadge(m)),
                  // Customer
                  DataCell(
                    Text(
                      m.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Phone
                  DataCell(Text(m.phone, style: rowStyle)),
                  // Address
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
                  // System size
                  DataCell(
                    Text(
                      m.systemSize > 0
                          ? '${m.systemSize.toStringAsFixed(m.systemSize % 1 == 0 ? 0 : 1)} kW'
                          : '—',
                      style: rowStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                  // Completed on
                  DataCell(_completedDateCell(m)),
                  // Assigned by
                  DataCell(Text(m.assignedByName ?? '—', style: rowStyle)),
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
  final int? secondCount;
  final Color color;
  final String svgAsset;
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.svgAsset,
    this.secondCount,
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
            secondCount != null
                ? Text(
                    '$count / $secondCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  )
                : Text(
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
                AppSvgIcon(
                  svgAsset,
                  size: 10,
                  color: color.withValues(alpha: 0.7),
                ),
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
//  Empty State
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
              AppSvgAssets.clipboardList,
              size: 56,
              color: AppColors.divider,
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch
                  ? 'No results found'
                  : 'No completed $tabLabel installations yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try adjusting your search or date filter.'
                  : 'Completed jobs will appear here once meter is installed.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
