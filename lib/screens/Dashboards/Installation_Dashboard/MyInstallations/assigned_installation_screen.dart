// lib/screens/Dashboards/Installation_Dashboard/MyInstallations/assigned_installation_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_cubit.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/installation_model.dart';
import 'package:solar_project/data/Repository/sprinkler_leads_repository.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/MyInstallations/solar_installation_detail_screen.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/MyInstallations/sprinkler_installation_detail_screen.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

// ─── accent colour ────────────────────────────────────────────────────────────
const _kPurple = AppColors.primary;
const _kAssignedCard = AppColors.primary;
const _kTeal = Colors.teal;

class AssignedInstallationsScreen extends StatefulWidget {
  const AssignedInstallationsScreen({super.key});

  @override
  State<AssignedInstallationsScreen> createState() =>
      _AssignedInstallationsScreenState();
}

class _AssignedInstallationsScreenState
    extends State<AssignedInstallationsScreen>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  String _search = '';
  Timer? _midnightRefreshTimer;

  // collapsible state for older assignments section
  bool _showOlder = false;

  // 7-day cutoff
  DateTime get _recentCutoff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 6));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _search = _searchCtrl.text.trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstallationCubit>().fetchInstallations();
    });
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightRefreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<InstallationCubit>().fetchInstallations();
      setState(() {});
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightRefreshTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);

    _midnightRefreshTimer = Timer(delay, () {
      if (!mounted) return;
      context.read<InstallationCubit>().fetchInstallations();
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  bool _isNextDayInstallation(InstallationModel m) {
    final scheduled = m.scheduledDate;
    if (scheduled == null) return false;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return scheduled.year == tomorrow.year &&
        scheduled.month == tomorrow.month &&
        scheduled.day == tomorrow.day;
  }

  void _handleBack() => context.read<InstallationNavCubit>().changePage(
    InstallationNavPage.dashboard,
  );

  // ── Filtering ─────────────────────────────────────────────────────────────
  List<InstallationModel> _base(List<InstallationModel> all) =>
      all
          .where(
            (m) =>
                !m.projectCompleted &&
                !(m.projectType.toLowerCase() == 'solar' &&
                    m.status == InstallationStatus.meterInstalled),
          )
          .where(_matchesSearch)
          .toList()
        ..sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

  List<InstallationModel> _filteredByProjectType(
    List<InstallationModel> all,
    String? projectType,
  ) {
    final items = _base(all);
    if (projectType == null || projectType.isEmpty) return items;

    final byProjectType = items
        .where((m) => m.projectType.toLowerCase() == projectType)
        .toList();

    // Card navigation (solar/sprinkler) should display only tomorrow's jobs.
    return byProjectType.where(_isNextDayInstallation).toList();
  }

  bool _matchesSearch(InstallationModel m) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return m.customerName.toLowerCase().contains(q) ||
        m.phone.toLowerCase().contains(q) ||
        m.address.toLowerCase().contains(q);
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Future<void> _openDetail(BuildContext ctx, InstallationModel m) async {
    if (m.projectType.toLowerCase() == 'sprinkler') {
      try {
        final spkLead = await SprinklerLeadRepository(
          DioClient(),
        ).getSingleLead(m.id);
        if (!mounted) return;
        await Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: ctx.read<InstallationCubit>()),
                BlocProvider.value(value: ctx.read<SprinklerLeadCubit>()),
              ],
              child: SprinklerInstallationDetailScreen(lead: spkLead),
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Could not load lead: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    } else {
      await Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: ctx.read<InstallationCubit>()),
              BlocProvider.value(value: ctx.read<SolarLeadCubit>()),
              BlocProvider.value(value: ctx.read<SprinklerLeadCubit>()),
            ],
            child: InstallationDetailScreen.fromModel(m),
          ),
        ),
      );
    }
    if (mounted) context.read<InstallationCubit>().fetchInstallations();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      builder: (ctx, state) {
        final all = state is InstallationsLoaded
            ? state.installations
            : <InstallationModel>[];
        final loading = state is InstallationLoading && all.isEmpty;

        final navCubit = ctx.read<InstallationNavCubit>();
        final projectTypeFilter = navCubit.myInstallationsProjectType;
        final allItems = _base(all);
        final visibleItems = _filteredByProjectType(all, projectTypeFilter);

        final title = projectTypeFilter == 'solar'
            ? 'Solar Installations'
            : projectTypeFilter == 'sprinkler'
            ? 'Sprinkler Installations'
            : 'My Installations';

        return Scaffold(
          backgroundColor:  AppColors.background,
          appBar: AppBar(
            backgroundColor: _kAssignedCard,
            elevation: 0,
            leading: IconButton(
              icon: const AppSvgIcon(
                AppSvgAssets.chevronLeft,
                size: 18,
                color: AppColors.surface,
              ),
              onPressed: _handleBack,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
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
          ),
          body: Column(
            children: [
              Container(height: 1, color: AppColors.divider),

              Container(
                color: AppColors.surface,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Text(
                  projectTypeFilter == 'solar'
                      ? 'Showing next-day Solar leads (${visibleItems.length})'
                      : projectTypeFilter == 'sprinkler'
                      ? 'Showing next-day Sprinkler leads (${visibleItems.length})'
                      : 'Showing all leads (${allItems.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              // ── Search bar ───────────────────────────────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search customer, phone, address...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AppSvgIcon(
                        AppSvgAssets.search,
                        size: 12,
                        color: AppColors.background,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.divider,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // ── Tab views ────────────────────────────────────────────
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kPurple),
                      )
                    : _buildTableView(ctx, visibleItems),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Table view builder ────────────────────────────────────────────────────
  Widget _buildTableView(BuildContext ctx, List<InstallationModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              AppSvgAssets.clipboardList,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              'No installations found',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    final recent = items
        .where((m) => !m.assignedDate.isBefore(_recentCutoff))
        .toList();
    final older = items
        .where((m) => m.assignedDate.isBefore(_recentCutoff))
        .toList();

    return RefreshIndicator(
      color: _kPurple,
      onRefresh: () async => ctx.read<InstallationCubit>().fetchInstallations(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minW = constraints.maxWidth < 900
              ? 920.0
              : constraints.maxWidth;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
            children: [
              _TableSection(
                title: 'Last 7 Days',
                subtitle: 'Assignments from the last seven days',
                items: recent,
                minWidth: minW,
                showEmptyMessage: true,
                onTap: (m) => _openDetail(ctx, m),
              ),
              const SizedBox(height: 12),
              _CollapsibleTableSection(
                title: 'Older Assignments',
                subtitle: 'Older records collapsed by default',
                items: older,
                minWidth: minW,
                initiallyExpanded: _showOlder,
                onExpansionChanged: (v) {
                  if (mounted) setState(() => _showOlder = v);
                },
                onTap: (m) => _openDetail(ctx, m),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Table Section (always expanded)
// ─────────────────────────────────────────────────────────────
class _TableSection extends StatelessWidget {
  final String title, subtitle;
  final List<InstallationModel> items;
  final double minWidth;
  final bool showEmptyMessage;
  final ValueChanged<InstallationModel> onTap;

  const _TableSection({
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.divider),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty && showEmptyMessage)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No assignments in the last 7 days.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            )
          else if (items.isNotEmpty)
            _InstallDataTable(items: items, minWidth: minWidth, onTap: onTap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Collapsible Table Section
// ─────────────────────────────────────────────────────────────
class _CollapsibleTableSection extends StatelessWidget {
  final String title, subtitle;
  final List<InstallationModel> items;
  final double minWidth;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<InstallationModel> onTap;

  const _CollapsibleTableSection({
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('install_assigned_older_$title'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
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
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          children: [
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No older assignments found.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              )
            else
              _InstallDataTable(items: items, minWidth: minWidth, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DataTable renderer
// ─────────────────────────────────────────────────────────────
class _InstallDataTable extends StatelessWidget {
  final List<InstallationModel> items;
  final double minWidth;
  final ValueChanged<InstallationModel> onTap;

  const _InstallDataTable({
    required this.items,
    required this.minWidth,
    required this.onTap,
  });

  bool get _mixed =>
      items.any((m) => m.projectType.toLowerCase() == 'solar') &&
      items.any((m) => m.projectType.toLowerCase() == 'sprinkler');

  Color _typeColor(InstallationModel m) =>
      m.projectType.toLowerCase() == 'sprinkler' ? _kTeal : _kPurple;

  Widget _typeBadge(InstallationModel m) {
    final color = _typeColor(m);
    final label = m.projectType.toLowerCase() == 'sprinkler'
        ? 'Sprinkler'
        : 'Solar';
    final icon = m.projectType.toLowerCase() == 'sprinkler'
        ? AppSvgAssets.droplet
        : AppSvgAssets.sun;
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
          AppSvgIcon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
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

  Widget _scheduledCell(DateTime? dt) {
    if (dt == null) {
      return Text(
        'Date TBD',
        style: TextStyle(fontSize: 11, color: AppColors.textLight),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('dd MMM yyyy').format(dt),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kPurple,
          ),
        ),
        Text(
          DateFormat('hh:mm a').format(dt),
          style: TextStyle(
            fontSize: 10,
            color: _kPurple.withValues(alpha: 0.85),
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
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            horizontalMargin: isDesktop ? 18 : 12,
            columnSpacing: isDesktop ? 24 : 14,
            headingRowColor: WidgetStateProperty.all(
              _kPurple.withValues(alpha: 0.07),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _kPurple.withValues(alpha: 0.05);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.primary),
              bottom: BorderSide(color: AppColors.primary),
              top: BorderSide(color: AppColors.primary),
            ),
            columns: [
              // Show Type column only when the list is mixed
              if (_mixed) const DataColumn(label: Text('Type')),
              const DataColumn(label: Text('Customer')),
              const DataColumn(label: Text('Phone')),
              const DataColumn(label: Text('Address')),
              const DataColumn(label: Text('Team')),
              const DataColumn(label: Text('Status')),
              const DataColumn(label: Text('Scheduled')),
            ],
            rows: items.map((m) {
              // Join multiple team member names
              final teamLabel = m.installationTeamMemberNames.isNotEmpty
                  ? m.installationTeamMemberNames.join(', ')
                  : (m.installationTeamName ?? '—');

              return DataRow(
                onSelectChanged: (_) => onTap(m),
                cells: [
                  if (_mixed) DataCell(_typeBadge(m)),
                  DataCell(
                    Text(
                      m.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(m.phone, style: rowStyle)),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 220 : 170,
                      child: Text(
                        m.address.isEmpty ? '—' : m.address,
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 160 : 120,
                      child: Text(
                        teamLabel,
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                  DataCell(_statusBadge(m)),
                  DataCell(_scheduledCell(m.scheduledDate)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
