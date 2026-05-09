import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/data/Models/installation_model.dart';
import 'package:solar_project/core/app_colors.dart';

bool _isToday(DateTime? dt) {
  if (dt == null) return false;
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

class TodaysJobsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Color appBarColor;
  const TodaysJobsScreen({
    super.key,
    required this.onBack,
    this.appBarColor = AppColors.primary, // _kPurple removed
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

  List<InstallationModel> _todayAll(List<InstallationModel> all) =>
      all
          .where(
            (m) =>
                _isToday(m.scheduledDate) &&
                m.status != InstallationStatus.projectCompleted,
          )
          .where(_matchesSearch)
          .toList()
        ..sort(
          (a, b) => (a.scheduledDate ?? DateTime(2100)).compareTo(
            b.scheduledDate ?? DateTime(2100),
          ),
        );

  List<InstallationModel> _todaySolar(List<InstallationModel> all) => _todayAll(
    all,
  ).where((m) => m.projectType.toLowerCase() == 'solar').toList();

  List<InstallationModel> _todaySprinkler(List<InstallationModel> all) =>
      _todayAll(
        all,
      ).where((m) => m.projectType.toLowerCase() != 'solar').toList();

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

        final todayAll = _todayAll(all);
        final todaySolar = _todaySolar(all);
        final todaySprinkler = _todaySprinkler(all);
        final loading = state is InstallationLoading && all.isEmpty;
        final todayLabel = DateFormat(
          'EEEE, d MMM yyyy',
        ).format(DateTime.now());

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: widget.appBarColor,
            elevation: 0,
            leading: IconButton(
              icon: const AppSvgIcon(
                AppSvgAssets.chevronLeft,
                size: 18,
                color: AppColors.surface,
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
                    color: AppColors.surface,
                  ),
                ),
                Text(
                  todayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.surface.withValues(alpha: 0.7),
                  ),
                ),
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
          body: Column(
            children: [
              if (todayAll.isNotEmpty)
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppSvgIcon(
                              AppSvgAssets.calendarDays,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${todayAll.length} job${todayAll.length == 1 ? '' : 's'} today',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (todaySolar.isNotEmpty ||
                                todaySprinkler.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(☀ ${todaySolar.length}  💧 ${todaySprinkler.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Tabs
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tab,
                  labelColor: AppColors.primary, // was _kPurple
                  unselectedLabelColor: AppColors.textGray,
                  indicatorColor: AppColors.primary, // was _kPurple
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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
                          Text('All (${todayAll.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvgIcon(AppSvgAssets.sun, size: 14),
                          const SizedBox(width: 4),
                          Text('Solar (${todaySolar.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvgIcon(AppSvgAssets.droplet, size: 14),
                          const SizedBox(width: 4),
                          Text('Sprinkler (${todaySprinkler.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search name, phone, address…',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AppSvgIcon(
                          AppSvgAssets.search,
                          size: 17,
                          color: AppColors.textGray,
                        ),
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const AppSvgIcon(AppSvgAssets.x, size: 13),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ), // was _kPurple
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.divider),

              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ) // was _kPurple
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _buildTableView(todayAll, showType: true),
                          _buildTableView(todaySolar, showType: false),
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
    if (items.isEmpty) return _EmptyState(hasSearch: _search.isNotEmpty);

    return RefreshIndicator(
      color: AppColors.primary, // was _kPurple
      onRefresh: () async =>
          context.read<InstallationCubit>().fetchInstallations(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minW = constraints.maxWidth < 900
              ? 900.0
              : constraints.maxWidth;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 40),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
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
                    horizontalMargin: constraints.maxWidth >= 1000 ? 18 : 12,
                    columnSpacing: constraints.maxWidth >= 1000 ? 24 : 14,
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.primaryTint,
                    ), // was _kPurple.withValues(alpha:0.07)
                    border: TableBorder(
                      horizontalInside: const BorderSide(
                        color: AppColors.background,
                      ),
                      bottom: const BorderSide(color: AppColors.divider),
                      top: const BorderSide(color: AppColors.divider),
                    ),
                    columns: [
                      if (showType) const DataColumn(label: Text('Type')),
                      const DataColumn(label: Text('Customer')),
                      const DataColumn(label: Text('Phone')),
                      const DataColumn(label: Text('Address')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Progress')),
                      const DataColumn(label: Text('Sched. Time')),
                      const DataColumn(label: Text('Assigned By')),
                    ],
                    rows: items.map((m) {
                      final isSolar = m.projectType.toLowerCase() == 'solar';
                      final accent = isSolar
                          ? AppColors.primary
                          : AppColors.primaryLight; // was _kPurple : _kBlue
                      return DataRow(
                        cells: [
                          if (showType) DataCell(_typeBadge(m)),
                          DataCell(
                            Text(
                              m.customerName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              m.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: constraints.maxWidth >= 1000 ? 200 : 150,
                              child: Text(
                                m.address.isEmpty ? '—' : m.address,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                          DataCell(_statusBadge(m, accent)),
                          DataCell(_progressCell(m, accent)),
                          DataCell(_timeCell(m.scheduledDate)),
                          DataCell(
                            Text(
                              m.assignedByName ?? '—',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
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

  Widget _typeBadge(InstallationModel m) {
    final isSolar = m.projectType.toLowerCase() == 'solar';
    final color = isSolar
        ? AppColors.primary
        : AppColors.primaryLight; // was _kPurple : _kBlue
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

  Widget _statusBadge(InstallationModel m, Color accent) {
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

  Color _statusColor(InstallationModel m) {
    switch (m.status) {
      case InstallationStatus.projectCompleted:
      case InstallationStatus.installationCompleted:
      case InstallationStatus.meterInstalled:
        return AppColors.success;
      case InstallationStatus.installationStarted:
      case InstallationStatus.meterApplied:
      case InstallationStatus.meterInspection:
        return AppColors.solar;
      case InstallationStatus.installationAssigned:
        return AppColors.primary;
    }
  }

  Widget _progressCell(InstallationModel m, Color accent) {
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
                backgroundColor: AppColors.divider,
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

  Widget _timeCell(DateTime? dt) {
    if (dt == null)
      return const Text(
        'TBD',
        style: TextStyle(fontSize: 11, color: AppColors.textLight),
      );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon(
                AppSvgAssets.clock,
                size: 11,
                color: AppColors.surface,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('hh:mm a').format(dt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
            AppSvgIcon(
              AppSvgAssets.calendarDays,
              size: 56,
              color: AppColors.divider,
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch ? 'No results found' : 'No jobs scheduled for today',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different search term.'
                  : "Jobs with today's install date will appear here.",
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
