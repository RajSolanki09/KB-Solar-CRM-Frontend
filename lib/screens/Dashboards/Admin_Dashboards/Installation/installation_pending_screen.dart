// lib/screens/Dashboards/Admin_Dashboards/Installation/installation_pending_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/pagiantionbar.dart';

// ✅ Brand color aliases — replaces LeadTheme.primary/secondary + teal
const _kSolar = AppColors.primary; // #5B4FCF — was LeadTheme.primary
const _kSprinkler = AppColors.primaryLight; // #7B6FE0 — was LeadTheme.secondary

class InstallationPendingScreen extends StatefulWidget {
  final Color appBarColor;
  const InstallationPendingScreen({
    super.key,
    // ✅ brand primary — was AppColors.tealAccent
    this.appBarColor = AppColors.primary,
  });
  @override
  State<InstallationPendingScreen> createState() => _State();
}

class _State extends State<InstallationPendingScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';

  int _solarCurrentPage = 1;
  int _solarTotalPages = 1;
  int _solarTotalLeads = 0;
  int _sprinklerCurrentPage = 1;
  int _sprinklerTotalPages = 1;
  int _sprinklerTotalLeads = 0;

  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchSolarPage(1);
    _fetchSprinklerPage(1);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSolarPage(int page) async {
    if (!mounted) return;
    final cubit = context.read<SolarLeadCubit>();
    try {
      final result = await cubit.fetchInstallationPendingPage(
        page: page,
        limit: _pageSize,
        search: _search.isNotEmpty ? _search : null,
      );
      if (mounted) {
        setState(() {
          _solarCurrentPage = result['page'] ?? 1;
          _solarTotalPages = result['pages'] ?? 1;
          _solarTotalLeads = result['total'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _fetchSprinklerPage(int page) async {
    if (!mounted) return;
    final cubit = context.read<SprinklerLeadCubit>();
    try {
      final result = await cubit.fetchInstallationPendingPage(
        page: page,
        limit: _pageSize,
        search: _search.isNotEmpty ? _search : null,
      );
      if (mounted) {
        setState(() {
          _sprinklerCurrentPage = result['page'] ?? 1;
          _sprinklerTotalPages = result['pages'] ?? 1;
          _sprinklerTotalLeads = result['total'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ tab color = brand purple shades — was LeadTheme.primary/secondary
    final tabColor = _kSolar;

    return Scaffold(
      // ✅ brand purple bg — was AppColors.lightBg
      backgroundColor: AppColors.purple50,
      appBar: AppBar(
        // ✅ brand primary — was AppColors.tealAccent
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: Colors.white,
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
                color: Colors.white,
              ),
            ),
            Text(
              'Deal done — awaiting installation',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
            onPressed: () {
              if (mounted) {
                _fetchSolarPage(1);
                _fetchSprinklerPage(1);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.primary, width: 3),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppSvgIcon(AppSvgAssets.sun, size: 14),
                      const SizedBox(width: 5),
                      const Text('Solar'),
                      if (_solarTotalLeads > 0) ...[
                        const SizedBox(width: 5),
                        // ✅ _kSolar = brand primary
                        _CountChip(_solarTotalLeads, _kSolar),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppSvgIcon(AppSvgAssets.droplet, size: 14),
                      const SizedBox(width: 5),
                      const Text('Sprinkler'),
                      if (_sprinklerTotalLeads > 0) ...[
                        const SizedBox(width: 5),
                        // ✅ _kSprinkler = brand primaryLight
                        _CountChip(_sprinklerTotalLeads, _kSprinkler),
                      ],
                    ],
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
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                // ✅ brand purple bg + border — was lightBg + grey.shade200
                color: AppColors.purple50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.purple200),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _search = v);
                  _solarCurrentPage = 1;
                  _sprinklerCurrentPage = 1;
                  if (_tab.index == 0) {
                    _fetchSolarPage(1);
                  } else {
                    _fetchSprinklerPage(1);
                  }
                },
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
                            _solarCurrentPage = 1;
                            _sprinklerCurrentPage = 1;
                            _fetchSolarPage(1);
                            _fetchSprinklerPage(1);
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
                        child: CircularProgressIndicator(color: _kSolar),
                      );
                    }
                    if (state is SolarLeadsLoaded) {
                      if (state.leads.isEmpty && _search.isEmpty) {
                        return _EmptyState(
                          svgAsset: AppSvgAssets.sun,
                          message: 'No solar leads awaiting installation',
                          sub:
                              'Leads appear here after Deal Closed and disappear when Installation Completed',
                        );
                      }
                      if (state.leads.isEmpty) {
                        return _EmptyState(
                          svgAsset: AppSvgAssets.sun,
                          message: 'No results for "$_search"',
                        );
                      }
                      return RefreshIndicator(
                        color: _kSolar,
                        onRefresh: () {
                          if (!ctx.mounted) return Future.value();
                          return _fetchSolarPage(_solarCurrentPage);
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final minW = constraints.maxWidth < 900
                                ? 1000.0
                                : constraints.maxWidth;
                            return Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      12,
                                    ),
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          // ✅ brand purple border
                                          border: Border.all(
                                            color: AppColors.purple200,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    14,
                                                    16,
                                                    10,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Pending Installation Leads (${state.total})',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Page $_solarCurrentPage of $_solarTotalPages (${state.leads.length} leads)',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _InstallDataTable<SolarLeadsModel>(
                                              leads: state.leads,
                                              // ✅ brand primary accent
                                              accentColor: _kSolar,
                                              minWidth: minW,
                                              rowBuilder: (lead) =>
                                                  _solarRow(ctx, lead),
                                              columnBuilder: () =>
                                                  _solarColumns(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PaginationBar(
                                  currentPage: _solarCurrentPage,
                                  totalPages: _solarTotalPages,
                                  totalItems: _solarTotalLeads,
                                  onPageChanged: _fetchSolarPage,
                                  activeColor: _kSolar,
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
                        child: CircularProgressIndicator(color: _kSprinkler),
                      );
                    }
                    if (state is SprinklerLeadsLoaded) {
                      if (state.leads.isEmpty && _search.isEmpty) {
                        return _EmptyState(
                          svgAsset: AppSvgAssets.droplet,
                          message: 'No sprinkler leads awaiting installation',
                          sub:
                              'Leads appear here after Deal Closed and disappear when Installation Completed',
                        );
                      }
                      if (state.leads.isEmpty) {
                        return _EmptyState(
                          svgAsset: AppSvgAssets.droplet,
                          message: 'No results for "$_search"',
                        );
                      }
                      return RefreshIndicator(
                        color: _kSprinkler,
                        onRefresh: () {
                          if (!ctx.mounted) return Future.value();
                          return _fetchSprinklerPage(_sprinklerCurrentPage);
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final minW = constraints.maxWidth < 900
                                ? 1000.0
                                : constraints.maxWidth;
                            return Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      12,
                                    ),
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.purple200,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    14,
                                                    16,
                                                    10,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Pending Installation Leads (${state.total})',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Page $_sprinklerCurrentPage of $_sprinklerTotalPages (${state.leads.length} leads)',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _InstallDataTable<
                                              SprinklerLeadModel
                                            >(
                                              leads: state.leads,
                                              accentColor: _kSprinkler,
                                              minWidth: minW,
                                              rowBuilder: (lead) =>
                                                  _spkRow(ctx, lead),
                                              columnBuilder: () =>
                                                  _spkColumns(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PaginationBar(
                                  currentPage: _sprinklerCurrentPage,
                                  totalPages: _sprinklerTotalPages,
                                  totalItems: _sprinklerTotalLeads,
                                  onPageChanged: _fetchSprinklerPage,
                                  activeColor: _kSprinkler,
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

  List<DataColumn> _solarColumns() => const [
    DataColumn(label: Text('Customer')),
    DataColumn(label: Text('Phone')),
    DataColumn(label: Text('Address')),
    DataColumn(label: Text('Step')),
    DataColumn(label: Text('Amount')),
    DataColumn(label: Text('Installation Date')),
    DataColumn(label: Text('Waiting Since')),
  ];

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
        DataCell(
          _installDateCell(
            lead.expectedInstallDate ??
                lead.installationAssignData.scheduledDate,
          ),
        ),
        DataCell(_waitingCell(lead.dealClosedAt ?? lead.createdAt)),
      ],
    );
  }

  List<DataColumn> _spkColumns() => const [
    DataColumn(label: Text('Customer')),
    DataColumn(label: Text('Phone')),
    DataColumn(label: Text('Address')),
    DataColumn(label: Text('Step')),
    DataColumn(label: Text('Amount')),
    DataColumn(label: Text('Installation Date')),
    DataColumn(label: Text('Waiting Since')),
  ];

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
        DataCell(
          _installDateCell(
            lead.expectedInstallDate ??
                lead.installationAssignData.scheduledDate,
          ),
        ),
        DataCell(_waitingCell(lead.dealData.closedAt ?? lead.createdAt)),
      ],
    );
  }

  // ✅ Step colors — all brand purple shades
  Color _solarStepColor(SolarStep step) {
    switch (step) {
      case SolarStep.dealDone:
        return AppColors.primary; // was: AppColors.greenSuccess
      case SolarStep.installationAssigned:
        return AppColors.primaryLight; // was: AppColors.cyan
      case SolarStep.installationStarted:
        return AppColors.purple400; // was: AppColors.amber
      default:
        return AppColors.textGray;
    }
  }

  Color _sprinklerStepColor(SprinklerStep step) {
    switch (step) {
      case SprinklerStep.dealDone:
        return AppColors.primary; // was: AppColors.greenSuccess
      case SprinklerStep.installationAssigned:
        return AppColors.primaryLight; // was: AppColors.cyan
      case SprinklerStep.installationStarted:
        return AppColors.purple400; // was: AppColors.amber
      default:
        return AppColors.textGray;
    }
  }

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

  // ✅ Install date urgency colors — brand purple scale
  // overdue = purple700 (dark), today/soon = primary, future = primaryLight
  Widget _installDateCell(DateTime? dt) {
    if (dt == null) {
      return const Text(
        'Not scheduled',
        style: TextStyle(fontSize: 11, color: AppColors.textLight),
      );
    }
    final diff = dt.difference(DateTime.now()).inDays;
    final Color color;
    if (diff < 0) {
      color = AppColors.purple700; // overdue — was Colors.red
    } else if (diff <= 3) {
      color = AppColors.primary; // urgent — was Colors.orange
    } else {
      color = AppColors.primaryLight; // future — was AppColors.cyan
    }
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

  // ✅ Waiting cell urgency — brand purple scale
  // >14 days = purple700 (dark/urgent), >7 = primary, else = primaryLight
  Widget _waitingCell(DateTime? dealDate) {
    if (dealDate == null) return const Text('—');
    final days = DateTime.now().difference(dealDate).inDays;
    final Color color;
    if (days > 14) {
      color = AppColors.purple700; // was Colors.red
    } else if (days > 7) {
      color = AppColors.primary; // was Colors.orange
    } else {
      color = AppColors.primaryLight; // was Colors.green
    }
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
            // ✅ header tint = brand purple
            headingRowColor: WidgetStateProperty.all(AppColors.purple100),
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.purple50;
              }
              return null;
            }),
            // ✅ table borders = brand purple — was blueGrey
            border: const TableBorder(
              horizontalInside: BorderSide(
                color: AppColors.purple200,
                width: 0.5,
              ),
              bottom: BorderSide(color: AppColors.purple200),
              top: BorderSide(color: AppColors.purple200),
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
            // ✅ brand purple — was Colors.grey.shade200
            AppSvgIcon(svgAsset, size: 64, color: AppColors.purple300),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(
                sub!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
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
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
