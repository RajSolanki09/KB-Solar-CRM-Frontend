// lib/screens/Dashboards/Installation_Dashboard/Dashboard/todays-jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/installation_model.dart';

const _kPurple = AppColors.purple500;
const _kBlue   = AppColors.cyan;

bool _isToday(DateTime? dt) {
  if (dt == null) return false;
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────
class TodaysJobsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Color appBarColor;
  const TodaysJobsScreen({
    super.key,
    required this.onBack,
    this.appBarColor = _kPurple,
  });

  @override
  State<TodaysJobsScreen> createState() => _TodaysJobsScreenState();
}

class _TodaysJobsScreenState extends State<TodaysJobsScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';

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
  List<InstallationModel> _todayAll(List<InstallationModel> all) => all
      .where((m) =>
          _isToday(m.scheduledDate) &&
          m.status != InstallationStatus.projectCompleted)
      .where(_matchesSearch)
      .toList()
    ..sort((a, b) => (a.scheduledDate ?? DateTime(2100))
        .compareTo(b.scheduledDate ?? DateTime(2100)));

  List<InstallationModel> _todaySolar(List<InstallationModel> all) =>
      _todayAll(all)
          .where((m) => m.projectType.toLowerCase() == 'solar')
          .toList();

  List<InstallationModel> _todaySprinkler(List<InstallationModel> all) =>
      _todayAll(all)
          .where((m) => m.projectType.toLowerCase() != 'solar')
          .toList();

  bool _matchesSearch(InstallationModel m) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return m.customerName.toLowerCase().contains(q) ||
        m.phone.contains(_search) ||
        m.address.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      builder: (ctx, state) {
        final all = state is InstallationsLoaded
            ? state.installations
            : <InstallationModel>[];

        final todayAll       = _todayAll(all);
        final todaySolar     = _todaySolar(all);
        final todaySprinkler = _todaySprinkler(all);
        final loading        = state is InstallationLoading && all.isEmpty;

        final todayLabel =
            DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

        return Scaffold(
          backgroundColor:   AppColors.slate50,
          appBar: AppBar(
            backgroundColor: widget.appBarColor,
            elevation: 0,
            leading: IconButton(
              icon: const AppSvgIcon(
                AppSvgAssets.chevronLeft,
                size: 18,
                color: Colors.white,
              ),
              onPressed: widget.onBack,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Jobs",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(todayLabel,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white70)),
              ],
            ),
            actions: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPurple),
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
              child:
                  Container(height: 1, color: Colors.grey.shade200),
            ),
          ),
          body: Column(
            children: [
              // ── Summary banner ─────────────────────────────────────
              if (todayAll.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:   AppColors.purpleVariant2
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:   AppColors.purpleVariant2
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppSvgIcon(AppSvgAssets.calendarDays,
                                size: 13, color: AppColors.purpleVariant2),
                            const SizedBox(width: 5),
                            Text(
                              '${todayAll.length} job${todayAll.length == 1 ? '' : 's'} today',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.purpleVariant2,
                              ),
                            ),
                            if (todaySolar.isNotEmpty ||
                                todaySprinkler.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(☀ ${todaySolar.length}  💧 ${todaySprinkler.length})',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Tabs ───────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tab,
                  labelColor: _kPurple,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: _kPurple,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const AppSvgIcon(AppSvgAssets.clipboardList, size: 14),
                        const SizedBox(width: 4),
                        Text('All (${todayAll.length})'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const AppSvgIcon(AppSvgAssets.sun, size: 14),
                        const SizedBox(width: 4),
                        Text('Solar (${todaySolar.length})'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const AppSvgIcon(AppSvgAssets.droplet, size: 14),
                        const SizedBox(width: 4),
                        Text('Sprinkler (${todaySprinkler.length})'),
                      ]),
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
                          fontSize: 12, color: Colors.grey.shade400),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AppSvgIcon(AppSvgAssets.search,
                            size: 17, color: Colors.grey.shade400),
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
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _kPurple),
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
                        child: CircularProgressIndicator(
                            color: _kPurple))
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _buildTableView(todayAll,       showType: true),
                          _buildTableView(todaySolar,     showType: false),
                          _buildTableView(todaySprinkler, showType: false),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableView(
    List<InstallationModel> items, {
    required bool showType,
  }) {
    if (items.isEmpty) {
      return _EmptyState(hasSearch: _search.isNotEmpty);
    }

    return RefreshIndicator(
      color: _kPurple,
      onRefresh: () async =>
          context.read<InstallationCubit>().fetchInstallations(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minW =
              constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 40),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color:   AppColors.divider),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minW,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 44,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    horizontalMargin:
                        constraints.maxWidth >= 1000 ? 18 : 12,
                    columnSpacing:
                        constraints.maxWidth >= 1000 ? 24 : 14,
                    // ── Non-clickable: no dataRowColor hover ──────────
                    headingRowColor: WidgetStateProperty.all(
                      _kPurple.withValues(alpha: 0.07),
                    ),
                    border: TableBorder(
                      horizontalInside:
                          BorderSide(color: Colors.blueGrey.shade50),
                      bottom: BorderSide(
                          color: Colors.blueGrey.shade100),
                      top:
                          BorderSide(color: Colors.blueGrey.shade100),
                    ),
                    columns: [
                      if (showType)
                        const DataColumn(label: Text('Type')),
                      const DataColumn(label: Text('Customer')),
                      const DataColumn(label: Text('Phone')),
                      const DataColumn(label: Text('Address')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Progress')),
                      const DataColumn(label: Text('Sched. Time')),
                      const DataColumn(label: Text('Assigned By')),
                    ],
                    rows: items.map((m) {
                      final isSolar =
                          m.projectType.toLowerCase() == 'solar';
                      final accent = isSolar ? _kPurple : _kBlue;

                      return DataRow(
                        // ── NO onSelectChanged — rows are non-clickable ──
                        cells: [
                          // Type (All tab only)
                          if (showType)
                            DataCell(_typeBadge(m)),
                          // Customer
                          DataCell(Text(m.customerName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark))),
                          // Phone
                          DataCell(Text(m.phone,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark))),
                          // Address
                          DataCell(SizedBox(
                            width: constraints.maxWidth >= 1000
                                ? 200
                                : 150,
                            child: Text(
                              m.address.isEmpty ? '—' : m.address,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark),
                            ),
                          )),
                          // Status badge
                          DataCell(_statusBadge(m, accent)),
                          // Progress
                          DataCell(_progressCell(m, accent)),
                          // Scheduled time
                          DataCell(_timeCell(m.scheduledDate)),
                          // Assigned by
                          DataCell(Text(
                            m.assignedByName ?? '—',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Cell helpers ──────────────────────────────────────────────────────────
  Widget _typeBadge(InstallationModel m) {
    final isSolar = m.projectType.toLowerCase() == 'solar';
    final color   = isSolar ? _kPurple : _kBlue;
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
          Text(isSolar ? 'Solar' : 'Sprinkler',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Widget _statusBadge(InstallationModel m, Color accent) {
    final color = _statusColor(m);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(m.statusLabel,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

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

  Widget _progressCell(InstallationModel m, Color accent) {
    const vals = {
      InstallationStatus.installationAssigned:  1 / 5,
      InstallationStatus.installationCompleted: 2 / 5,
      InstallationStatus.meterApplied:          3 / 5,
      InstallationStatus.meterInspection:       4 / 5,
      InstallationStatus.meterInstalled:        5 / 5,
      InstallationStatus.projectCompleted:      1.0,
    };
    const labels = {
      InstallationStatus.installationAssigned:  '1/5',
      InstallationStatus.installationCompleted: '2/5',
      InstallationStatus.meterApplied:          '3/5',
      InstallationStatus.meterInspection:       '4/5',
      InstallationStatus.meterInstalled:        '5/5',
      InstallationStatus.projectCompleted:      'Done',
    };
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
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent)),
        ],
      ),
    );
  }

  Widget _timeCell(DateTime? dt) {
    if (dt == null) {
      return Text('TBD',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _kPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon(AppSvgAssets.clock,
                  size: 11, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                DateFormat('hh:mm a').format(dt),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(AppSvgAssets.calendarDays,
                size: 56, color: Colors.grey.shade200),
            const SizedBox(height: 14),
            Text(
              hasSearch
                  ? 'No results found'
                  : 'No jobs scheduled for today',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different search term.'
                  : "Jobs with today's install date will appear here.",
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



