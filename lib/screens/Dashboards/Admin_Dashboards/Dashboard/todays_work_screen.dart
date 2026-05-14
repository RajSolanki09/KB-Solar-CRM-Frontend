import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/pagiantionbar.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/services/api_service.dart';

class TodaysWorkScreen extends StatefulWidget {
  const TodaysWorkScreen({super.key});

  @override
  State<TodaysWorkScreen> createState() => _TodaysWorkScreenState();
}

class _TodaysWorkScreenState extends State<TodaysWorkScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _materialCustomers = const [];

  final List<int> _pages      = [1, 1, 1, 1];
  final List<int> _totalPages = [1, 1, 1, 1];
  final List<int> _totalItems = [0, 0, 0, 0];
  final List<bool> _loading   = [false, false, false, false];
  static const int _limit = 10;

  late TabController _tabController;

  // ✅ Shorter tab labels so they don't overflow on small screens
  static const _tabs = ['Site Visits', 'Follow Ups', 'Install', 'Services'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchAllTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllTabs() async {
    await Future.wait([
      _fetchSiteVisits(),
      _fetchFollowUps(),
      _fetchInstallations(),
      _fetchServices(),
    ]);
  }

  Future<void> _loadMaterialCustomers({int page = 1}) async {
    try {
      final customers = await _apiService.getMaterialCustomers(
        page: page,
        limit: _limit,
      );
      if (mounted) {
        setState(() => _materialCustomers =
            List<Map<String, dynamic>>.from(customers['customers']));
        _totalPages[1] = customers['totalPages'] ?? 1;
      }
    } catch (_) {}
  }

  Future<void> _fetchSiteVisits() async {
    setState(() => _loading[0] = true);
    try {
      await Future.wait([
        context.read<SolarLeadCubit>().fetchPage(_pages[0]),
        context.read<SprinklerLeadCubit>().fetchPage(_pages[0]),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _loading[0] = false);
  }

  Future<void> _fetchFollowUps() async {
    setState(() => _loading[1] = true);
    try {
      await _loadMaterialCustomers(page: _pages[1]);
    } catch (_) {}
    if (mounted) setState(() => _loading[1] = false);
  }

  Future<void> _fetchInstallations() async {
    setState(() => _loading[2] = true);
    try {
      await Future.wait([
        context.read<SolarLeadCubit>().fetchPage(_pages[2]),
        context.read<SprinklerLeadCubit>().fetchPage(_pages[2]),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _loading[2] = false);
  }

  Future<void> _fetchServices() async {
    setState(() => _loading[3] = true);
    try {
      final serviceState = context.read<ServiceLeadCubit>().state;
      if (serviceState is! ServiceLeadsLoaded) {
        context.read<ServiceLeadCubit>().fetchAllServices();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading[3] = false);
  }

  void _onPageChanged(int tab, int newPage) async {
    if (newPage < 1 || newPage > _totalPages[tab]) return;
    setState(() => _pages[tab] = newPage);
    switch (tab) {
      case 0: await _fetchSiteVisits(); break;
      case 1: await _fetchFollowUps(); break;
      case 2: await _fetchInstallations(); break;
      case 3: await _fetchServices(); break;
    }
  }

  bool _isSameDay(DateTime? date, DateTime dayStart) {
    if (date == null) return false;
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day)
        .isAtSameMomentAs(dayStart);
  }

  DateTime? _solarInstallationDate(SolarLeadsModel lead) =>
      lead.installationData.completedDate ??
      lead.installationData.startDate ??
      lead.installationAssignData.scheduledDate;

  DateTime? _sprinklerInstallationDate(SprinklerLeadModel lead) =>
      lead.installationData.completedAt ??
      lead.installationData.startedAt ??
      lead.installationAssignData.scheduledDate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (ctx, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (ctx2, sprinklerState) {
            return BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
              builder: (ctx3, serviceState) {
                final solarLeads = solarState is SolarLeadsLoaded
                    ? solarState.leads : <SolarLeadsModel>[];
                final sprinklerLeads = sprinklerState is SprinklerLeadsLoaded
                    ? sprinklerState.leads : <SprinklerLeadModel>[];
                final services = serviceState is ServiceLeadsLoaded
                    ? serviceState.services : <ServiceRequestModel>[];

                final now = DateTime.now();
                final todayMid = DateTime(now.year, now.month, now.day);
                final dateFormat = DateFormat('dd MMM, hh:mm a');

                String formatDate(DateTime? d) =>
                    d == null ? '-' : dateFormat.format(d.toLocal());

                // ── Site Visits ───────────────────────────────────────────
                final siteVisitRows = <List<String>>[
                  ...solarLeads
                      .where((l) => _isSameDay(l.visitDate, todayMid))
                      .map((l) => [
                            'Solar', l.customerName, l.mobile,
                            solarStepToDisplay(l.currentStep),
                            formatDate(l.visitDate),
                            l.salesAssigned ?? '-',
                          ]),
                  ...sprinklerLeads
                      .where((l) => _isSameDay(l.visitDate, todayMid))
                      .map((l) => [
                            'Sprinkler', l.customerName, l.phone,
                            sprinklerStepToDisplay(l.currentStep),
                            formatDate(l.visitDate),
                            l.salesPerson ?? '-',
                          ]),
                ];

                // ── Follow Ups ────────────────────────────────────────────
                final followupRows = <List<String>>[
                  ...solarLeads
                      .where((l) => _isSameDay(l.nextFollowupDate, todayMid))
                      .map((l) => [
                            'Solar', l.customerName, l.mobile,
                            solarStepToDisplay(l.currentStep),
                            formatDate(l.nextFollowupDate),
                            l.salesAssigned ?? l.createdBy ?? '-',
                          ]),
                  ...sprinklerLeads
                      .where((l) => _isSameDay(l.nextFollowupDate, todayMid))
                      .map((l) => [
                            'Sprinkler', l.customerName, l.phone,
                            sprinklerStepToDisplay(l.currentStep),
                            formatDate(l.nextFollowupDate),
                            l.assignedToName ?? '-',
                          ]),
                  ..._materialCustomers
                      .where((c) {
                        final pipeline = c['pipeline'];
                        if (pipeline is! Map<String, dynamic>) return false;
                        final followUp = pipeline['followUp'];
                        if (followUp is! Map<String, dynamic>) return false;
                        final followUpAt = followUp['followUpAt'];
                        if (followUpAt == null ||
                            followUpAt.toString().trim().isEmpty) return false;
                        return _isSameDay(
                            DateTime.tryParse(followUpAt.toString()), todayMid);
                      })
                      .map((c) {
                        final pipeline =
                            c['pipeline'] as Map<String, dynamic>? ?? {};
                        final followUp =
                            pipeline['followUp'] as Map<String, dynamic>? ?? {};
                        final date = DateTime.tryParse(
                            followUp['followUpAt'].toString());
                        final assignedTo = followUp['assignedTo'];
                        final assignedName = assignedTo is Map
                            ? (assignedTo['name'] ??
                                    assignedTo['fullName'] ?? '-').toString()
                            : (assignedTo?.toString().isNotEmpty == true
                                ? assignedTo.toString() : '-');
                        return [
                          'Material',
                          (c['customerName'] ?? '-').toString(),
                          (c['mobile'] ?? c['phone'] ?? '-').toString(),
                          (pipeline['status'] ?? 'Follow-up').toString(),
                          formatDate(date),
                          assignedName,
                        ];
                      }),
                ];

                // ── Installations ─────────────────────────────────────────
                final installationRows = <List<String>>[
                  ...solarLeads
                      .where((l) {
                        final d = _solarInstallationDate(l);
                        return l.currentStep.index >=
                                SolarStep.installationAssigned.index &&
                            _isSameDay(d, todayMid);
                      })
                      .map((l) {
                        final names = l.installationTeamMemberNames;
                        return [
                          'Solar', l.customerName, l.mobile,
                          solarStepToDisplay(l.currentStep),
                          formatDate(_solarInstallationDate(l)),
                          names.isNotEmpty
                              ? names.join(', ') : (l.installationTeam ?? '-'),
                        ];
                      }),
                  ...sprinklerLeads
                      .where((l) {
                        final d = _sprinklerInstallationDate(l);
                        return l.currentStep.index >=
                                SprinklerStep.installationAssigned.index &&
                            _isSameDay(d, todayMid);
                      })
                      .map((l) => [
                            'Sprinkler', l.customerName, l.phone,
                            sprinklerStepToDisplay(l.currentStep),
                            formatDate(_sprinklerInstallationDate(l)),
                            l.effectiveInstallerNamesString ??
                                l.effectiveInstallerName ?? '-',
                          ]),
                ];

                // ── Services ──────────────────────────────────────────────
                final serviceRows = services
                    .where((s) =>
                        _isSameDay(s.serviceDate ?? s.createdAt, todayMid))
                    .map((s) => [
                          'Service', s.customerName, s.phone, s.status,
                          formatDate(s.serviceDate ?? s.createdAt),
                          s.assignedToName ?? '-',
                        ])
                    .toList();

                final allRows = [
                  siteVisitRows, followupRows, installationRows, serviceRows,
                ];
                final emptyTexts = [
                  'No site visits scheduled for today.',
                  'No follow ups scheduled for today.',
                  'No installations scheduled for today.',
                  'No services scheduled for today.',
                ];

                return Scaffold(
                  // ✅ Brand purple-tinted page background
                  backgroundColor: AppColors.purple50,
                  appBar: AppBar(
                    // ✅ Brand primary — not teal
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    title: const Text(
                      "Today's Work",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
                  ),
                  body: Column(
                    children: [
                      // ✅ TabBar — white bg, brand purple indicator & labels
                      // ✅ isScrollable: true — FIXES the overflow error
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,           // ← overflow fix
                          tabAlignment: TabAlignment.start,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textGray,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: List.generate(_tabs.length, (i) {
                            final count = allRows[i].length;
                            return Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_tabs[i]),
                                  if (count > 0) ...[
                                    const SizedBox(width: 6),
                                    // ✅ Badge — brand purple tint
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ),
                      ),

                      // ✅ Thin divider between tabs and content
                      Container(height: 1, color: AppColors.purple200),

                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: List.generate(_tabs.length, (i) {
                            return RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () => _fetchAllTabs(),
                              child: _loading[i]
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : allRows[i].isEmpty
                                      ? _EmptyState(text: emptyTexts[i])
                                      : Column(
                                          children: [
                                            Expanded(
                                              child: _WorkTable(
                                                  rows: allRows[i]),
                                            ),
                                            PaginationBar(
                                              currentPage: _pages[i],
                                              totalPages: _totalPages[i],
                                              onPageChanged: (p) =>
                                                  _onPageChanged(i, p),
                                              // ✅ Brand purple pagination
                                              activeColor: AppColors.primary,
                                            ),
                                          ],
                                        ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Brand purple icon — not grey
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: AppColors.purple300,
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Table ────────────────────────────────────────────────────────────────────
class _WorkTable extends StatelessWidget {
  final List<List<String>> rows;
  const _WorkTable({required this.rows});

  // ✅ All type badges use brand purple shades only
  Widget _typeBadge(String type) {
    // Different shades of the same purple for visual distinction
    final Color badgeColor;
    switch (type) {
      case 'Solar':
        badgeColor = AppColors.primary;       // #5B4FCF solid
        break;
      case 'Sprinkler':
        badgeColor = AppColors.primaryLight;  // #7B6FE0 lighter
        break;
      case 'Service':
        badgeColor = AppColors.purple700;     // #3B30A8 darker
        break;
      case 'Material':
        badgeColor = AppColors.purple400;     // #8F84E8 mid
        break;
      default:
        badgeColor = AppColors.textGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badgeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple200),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 44,
                    dataRowMinHeight: 46,
                    dataRowMaxHeight: 56,
                    horizontalMargin: isDesktop ? 12 : 8,
                    columnSpacing: isDesktop ? 14 : 8,
                    // ✅ Header — brand light purple tint
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.purple100,
                    ),
                    // ✅ Header text — brand primary
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    dataTextStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                    // ✅ Table borders — brand purple scale
                    border: const TableBorder(
                      horizontalInside: BorderSide(
                        color: AppColors.purple200,
                        width: 0.5,
                      ),
                      bottom: BorderSide(color: AppColors.purple200),
                      top: BorderSide(color: AppColors.purple200),
                    ),
                    columns: const [
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Date/Time')),
                      DataColumn(label: Text('Assigned To')),
                    ],
                    rows: rows.map((r) {
                      return DataRow(
                        color: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.purple50;
                          }
                          return null;
                        }),
                        cells: [
                          DataCell(_typeBadge(r[0])),
                          ...r.sublist(1).map(
                                (v) => DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 80,
                                      maxWidth: 160,
                                    ),
                                    child: Text(
                                      v,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}