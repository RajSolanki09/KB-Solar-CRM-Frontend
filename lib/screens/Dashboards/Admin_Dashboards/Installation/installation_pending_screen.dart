// lib/screens/Dashboards/Admin_Dashboards/Installation/installation_pending_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/core/app_colors.dart';

class InstallationPendingScreen extends StatefulWidget {
  final Color appBarColor;
  const InstallationPendingScreen({
    super.key,
    this.appBarColor = AppColors.primaryDark,
  });
  @override
  State<InstallationPendingScreen> createState() => _State();
}

class _State extends State<InstallationPendingScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _showOlderSolar = false;
  bool _showOlderSpk = false;

  // 7-day cutoff — same pattern as other screens
  DateTime get _recentCutoff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 6));
  }

  late final VoidCallback _tabListener;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tabListener = () {
      if (mounted) setState(() {});
    };
    _tab.addListener(_tabListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolarLeadCubit>().fetchAllLeads();
      context.read<SprinklerLeadCubit>().fetchAllLeads();
    });
  }

  @override
  void dispose() {
    _tab.removeListener(_tabListener);
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter helpers ────────────────────────────────────────────────────────
  List<SolarLeadsModel> _solarPending(List<SolarLeadsModel> all) {
    final q = _search.toLowerCase();
    return all.where((l) {
      final matchStep =
          l.currentStep.index >= SolarStep.dealDone.index &&
          l.currentStep.index < SolarStep.installation.index;
      final matchSearch =
          _search.isEmpty ||
          l.customerName.toLowerCase().contains(q) ||
          l.mobile.contains(_search) ||
          l.address.toLowerCase().contains(q);
      return matchStep && matchSearch;
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<SprinklerLeadModel> _spkPending(List<SprinklerLeadModel> all) {
    final q = _search.toLowerCase();
    return all.where((l) {
      final matchStep =
          l.currentStep.index >= SprinklerStep.dealDone.index &&
          l.currentStep.index < SprinklerStep.installationCompleted.index;
      final matchSearch =
          _search.isEmpty ||
          l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(_search) ||
          l.address.toLowerCase().contains(q);
      return matchStep && matchSearch;
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final tabColor = _tab.index == 0 ? LeadTheme.primary : LeadTheme.secondary;

    return Scaffold(
      backgroundColor:  AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: AppColors.surface,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installation Pending',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
            Text(
              'Deal done — awaiting installation',
              style: TextStyle(fontSize: 11, color: AppColors.surface),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.refreshCw,
              color: AppColors.surface,
            ),
            onPressed: () {
              context.read<SolarLeadCubit>().fetchAllLeads();
              context.read<SprinklerLeadCubit>().fetchAllLeads();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tab,
              indicatorColor: tabColor,
              indicatorWeight: 2.5,
              labelColor: tabColor,
              unselectedLabelColor:  AppColors.textDark,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: BlocBuilder<SolarLeadCubit, SolarLeadState>(
                    builder: (_, state) {
                      final all = state is SolarLeadsLoaded
                          ? state.leads
                          : <SolarLeadsModel>[];
                      final count = _solarPending(all).length;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppSvgIcon(AppSvgAssets.sun, size: 14),
                          const SizedBox(width: 5),
                          const Text('Solar'),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            _CountChip(count, LeadTheme.primary),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Tab(
                  child: BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
                    builder: (_, state) {
                      final all = state is SprinklerLeadsLoaded
                          ? state.leads
                          : <SprinklerLeadModel>[];
                      final count = _spkPending(all).length;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppSvgIcon(AppSvgAssets.droplet, size: 14),
                          const SizedBox(width: 5),
                          const Text('Sprinkler'),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            _CountChip(count, LeadTheme.secondary),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color:  AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search name / phone / address',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AppSvgIcon(
                      AppSvgAssets.search,
                      size: 16,
                      color: tabColor,
                    ),
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const AppSvgIcon(AppSvgAssets.x, size: 14),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),

          // ── Tab views ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ── SOLAR ────────────────────────────────────────────────
                BlocBuilder<SolarLeadCubit, SolarLeadState>(
                  builder: (ctx, state) {
                    if (state is SolarLeadLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: LeadTheme.primary,
                        ),
                      );
                    }
                    if (state is SolarLeadsLoaded) {
                      final list = _solarPending(state.leads);
                      if (list.isEmpty) {
                        return _EmptyState(
                          svgAsset: AppSvgAssets.sun,
                          message: _search.isNotEmpty
                              ? 'No results for "$_search"'
                              : 'No solar leads awaiting installation',
                          sub: _search.isEmpty
                              ? 'Leads appear here after Deal Closed and stay until Installation Completed'
                              : null,
                        );
                      }

                      // Split into recent / older
                      final recent = list
                          .where((l) => !l.createdAt.isBefore(_recentCutoff))
                          .toList();
                      final older = list
                          .where((l) => l.createdAt.isBefore(_recentCutoff))
                          .toList();

                      return RefreshIndicator(
                        color: LeadTheme.primary,
                        onRefresh: () =>
                            ctx.read<SolarLeadCubit>().fetchAllLeads(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final minW = constraints.maxWidth < 900
                                ? 1000.0
                                : constraints.maxWidth;
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                              children: [
                                _TableSection<SolarLeadsModel>(
                                  title: 'Last 7 Days',
                                  subtitle:
                                      'Installation pending in the last seven days',
                                  leads: recent,
                                  accentColor: LeadTheme.primary,
                                  minWidth: minW,
                                  showEmptyMessage: true,
                                  rowBuilder: (lead) => _solarRow(ctx, lead),
                                  columnBuilder: () => _solarColumns(),
                                ),
                                const SizedBox(height: 12),
                                _CollapsibleTableSection<SolarLeadsModel>(
                                  title: 'Older Pending',
                                  subtitle:
                                      'Older records collapsed by default',
                                  leads: older,
                                  accentColor: LeadTheme.primary,
                                  minWidth: minW,
                                  initiallyExpanded: _showOlderSolar,
                                  onExpansionChanged: (v) {
                                    if (mounted)
                                      setState(() => _showOlderSolar = v);
                                  },
                                  rowBuilder: (lead) => _solarRow(ctx, lead),
                                  columnBuilder: () => _solarColumns(),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // ── SPRINKLER ─────────────────────────────────────────────
                BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
                  builder: (ctx, state) {
                    if (state is SprinklerLeadLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: LeadTheme.secondary,
                        ),
                      );
                    }
                    if (state is SprinklerLeadsLoaded) {
                      final list = _spkPending(state.leads);
                      if (list.isEmpty) {
                        return _EmptyState(
                          svgAsset: AppSvgAssets.droplet,
                          message: _search.isNotEmpty
                              ? 'No results for "$_search"'
                              : 'No sprinkler leads awaiting installation',
                          sub: _search.isEmpty
                              ? 'Leads appear here after Deal Closed and stay until Installation Completed'
                              : null,
                        );
                      }

                      final recent = list
                          .where((l) => !l.createdAt.isBefore(_recentCutoff))
                          .toList();
                      final older = list
                          .where((l) => l.createdAt.isBefore(_recentCutoff))
                          .toList();

                      return RefreshIndicator(
                        color: LeadTheme.secondary,
                        onRefresh: () =>
                            ctx.read<SprinklerLeadCubit>().fetchAllLeads(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final minW = constraints.maxWidth < 900
                                ? 1000.0
                                : constraints.maxWidth;
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                              children: [
                                _TableSection<SprinklerLeadModel>(
                                  title: 'Last 7 Days',
                                  subtitle:
                                      'Installation pending in the last seven days',
                                  leads: recent,
                                  accentColor: LeadTheme.secondary,
                                  minWidth: minW,
                                  showEmptyMessage: true,
                                  rowBuilder: (lead) => _spkRow(ctx, lead),
                                  columnBuilder: () => _spkColumns(),
                                ),
                                const SizedBox(height: 12),
                                _CollapsibleTableSection<SprinklerLeadModel>(
                                  title: 'Older Pending',
                                  subtitle:
                                      'Older records collapsed by default',
                                  leads: older,
                                  accentColor: LeadTheme.secondary,
                                  minWidth: minW,
                                  initiallyExpanded: _showOlderSpk,
                                  onExpansionChanged: (v) {
                                    if (mounted)
                                      setState(() => _showOlderSpk = v);
                                  },
                                  rowBuilder: (lead) => _spkRow(ctx, lead),
                                  columnBuilder: () => _spkColumns(),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Solar column definitions ──────────────────────────────────────────────
  List<DataColumn> _solarColumns() => const [
    DataColumn(label: Text('Customer')),
    DataColumn(label: Text('Phone')),
    DataColumn(label: Text('Address')),
    DataColumn(label: Text('Step')),
    DataColumn(label: Text('Amount')),
    DataColumn(label: Text('Install Date')),
    DataColumn(label: Text('Waiting Since')),
  ];

  // ── Solar row builder ─────────────────────────────────────────────────────
  DataRow _solarRow(BuildContext ctx, SolarLeadsModel lead) {
    final stepLabel = solarStepToDisplay(lead.currentStep);
    final stepColor = _solarStepColor(lead.currentStep);

    return DataRow(
      cells: [
        DataCell(
          Text(
            lead.customerName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        DataCell(
          Text(
            lead.mobile,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              lead.address.isEmpty ? '—' : lead.address,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ),
        DataCell(_stepBadge(stepLabel, stepColor)),
        DataCell(
          Text(
            lead.finalAmount != null && lead.finalAmount! > 0
                ? 'Rs. ${LeadTheme.formatAmount(lead.finalAmount!)}'
                : lead.totalAmount > 0
                ? 'Rs. ${LeadTheme.formatAmount(lead.totalAmount)}'
                : '—',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        DataCell(_installDateCell(lead.expectedInstallDate)),
        DataCell(_waitingCell(lead.dealClosedAt ?? lead.createdAt)),
      ],
    );
  }

  // ── Sprinkler column definitions ──────────────────────────────────────────
  List<DataColumn> _spkColumns() => const [
    DataColumn(label: Text('Customer')),
    DataColumn(label: Text('Phone')),
    DataColumn(label: Text('Address')),
    DataColumn(label: Text('Step')),
    DataColumn(label: Text('Amount')),
    DataColumn(label: Text('Install Date')),
    DataColumn(label: Text('Waiting Since')),
  ];

  // ── Sprinkler row builder ─────────────────────────────────────────────────
  DataRow _spkRow(BuildContext ctx, SprinklerLeadModel lead) {
    final stepLabel = sprinklerStepToDisplay(lead.currentStep);
    final stepColor = _sprinklerStepColor(lead.currentStep);

    return DataRow(
      cells: [
        DataCell(
          Text(
            lead.customerName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        DataCell(
          Text(
            lead.phone,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              lead.address.isEmpty ? '—' : lead.address,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ),
        DataCell(_stepBadge(stepLabel, stepColor)),
        DataCell(
          Text(
            lead.totalAmount > 0
                ? 'Rs. ${LeadTheme.formatAmount(lead.totalAmount)}'
                : '—',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        DataCell(_installDateCell(lead.expectedInstallDate)),
        DataCell(_waitingCell(lead.dealData.closedAt ?? lead.createdAt)),
      ],
    );
  }

  Color _solarStepColor(SolarStep step) {
    switch (step) {
      case SolarStep.dealDone:
        return  AppColors.success;
      case SolarStep.installationAssigned:
        return AppColors.primaryLight;
      case SolarStep.installationStarted:
        return AppColors.primary;
      default:
        return  AppColors.textGray;
    }
  }

  Color _sprinklerStepColor(SprinklerStep step) {
    switch (step) {
      case SprinklerStep.dealDone:
        return  AppColors.success;
      case SprinklerStep.installationAssigned:
        return AppColors.primaryLight;
      case SprinklerStep.installationStarted:
        return AppColors.primary;
      default:
        return  AppColors.textGray;
    }
  }

  // ── Shared cell helpers ───────────────────────────────────────────────────
  Widget _stepBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _installDateCell(DateTime? dt) {
    if (dt == null) {
      return Text(
        'Not scheduled',
        style: TextStyle(fontSize: 11, color: AppColors.textLight),
      );
    }
    final diff = dt.difference(DateTime.now()).inDays;
    final Color color;
    if (diff < 0)
      color = AppColors.error;
    else if (diff == 0)
      color = AppColors.solar;
    else if (diff <= 3)
      color = AppColors.solar;
    else
      color = AppColors.primaryLight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('dd MMM yyyy').format(dt),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          DateFormat('hh:mm a').format(dt),
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _waitingCell(DateTime? dealDate) {
    if (dealDate == null) return const Text('—');
    final days = DateTime.now().difference(dealDate).inDays;
    final Color color;
    if (days > 14)
      color = AppColors.error;
    else if (days > 7)
      color = AppColors.solar;
    else
      color = AppColors.success;

    final label = days == 0
        ? 'Today'
        : days == 1
        ? '1 day'
        : '$days days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Generic Table Section (always expanded)
// ─────────────────────────────────────────────────────────────
class _TableSection<T> extends StatelessWidget {
  final String title, subtitle;
  final List<T> leads;
  final Color accentColor;
  final double minWidth;
  final bool showEmptyMessage;
  final DataRow Function(T) rowBuilder;
  final List<DataColumn> Function() columnBuilder;

  const _TableSection({
    required this.title,
    required this.subtitle,
    required this.leads,
    required this.accentColor,
    required this.minWidth,
    required this.rowBuilder,
    required this.columnBuilder,
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
                  '$title (${leads.length})',
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
                    color: LeadTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (leads.isEmpty && showEmptyMessage)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No leads in this section.',
                style: TextStyle(fontSize: 12, color: LeadTheme.textMuted),
              ),
            )
          else if (leads.isNotEmpty)
            _InstallDataTable(
              leads: leads,
              accentColor: accentColor,
              minWidth: minWidth,
              rowBuilder: rowBuilder,
              columnBuilder: columnBuilder,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Generic Collapsible Table Section
// ─────────────────────────────────────────────────────────────
class _CollapsibleTableSection<T> extends StatelessWidget {
  final String title, subtitle;
  final List<T> leads;
  final Color accentColor;
  final double minWidth;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final DataRow Function(T) rowBuilder;
  final List<DataColumn> Function() columnBuilder;

  const _CollapsibleTableSection({
    required this.title,
    required this.subtitle,
    required this.leads,
    required this.accentColor,
    required this.minWidth,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.rowBuilder,
    required this.columnBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.primary),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('install_older_$title'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(
            '$title (${leads.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: LeadTheme.textMuted),
          ),
          children: [
            if (leads.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No older leads found.',
                    style: TextStyle(fontSize: 12, color: LeadTheme.textMuted),
                  ),
                ),
              )
            else
              _InstallDataTable(
                leads: leads,
                accentColor: accentColor,
                minWidth: minWidth,
                rowBuilder: rowBuilder,
                columnBuilder: columnBuilder,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Generic DataTable renderer
// ─────────────────────────────────────────────────────────────
class _InstallDataTable<T> extends StatelessWidget {
  final List<T> leads;
  final Color accentColor;
  final double minWidth;
  final DataRow Function(T) rowBuilder;
  final List<DataColumn> Function() columnBuilder;

  const _InstallDataTable({
    required this.leads,
    required this.accentColor,
    required this.minWidth,
    required this.rowBuilder,
    required this.columnBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

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
            dataRowMaxHeight: 68,
            horizontalMargin: isDesktop ? 18 : 12,
            columnSpacing: isDesktop ? 24 : 14,
            headingRowColor: WidgetStateProperty.all(
              accentColor.withValues(alpha: 0.08),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accentColor.withValues(alpha: 0.05);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.divider),
              bottom: BorderSide(color: AppColors.divider),
              top: BorderSide(color: AppColors.divider),
            ),
            columns: columnBuilder(),
            rows: leads.map(rowBuilder).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String svgAsset;
  final String message;
  final String? sub;
  const _EmptyState({required this.svgAsset, required this.message, this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(svgAsset, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(
                sub!,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Count Chip
// ─────────────────────────────────────────────────────────────
class _CountChip extends StatelessWidget {
  final int count;
  final Color color;
  const _CountChip(this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.surface,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
