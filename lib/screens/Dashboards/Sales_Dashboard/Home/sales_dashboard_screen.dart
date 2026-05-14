// lib/screens/Dashboards/Sales/sales_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/pipeline_dashboard_screen.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/peding_payment.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/service_request.dart';
import 'package:solar_project/screens/Dashboards/Followups/followup_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/solar_leads_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_leads_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Material/material_list_screen.dart';
import 'package:solar_project/services/api_service.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  // ── Profile ───────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileUser;
  String? _profileImagePath;
  int _activeMaterialLeadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfilePreview();
    _loadActiveMaterialLeadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SolarLeadCubit>().fetchAllLeads();
      context.read<SprinklerLeadCubit>().fetchAllLeads();
      final svcState = context.read<ServiceLeadCubit>().state;
      if (svcState is! ServiceLeadsLoaded) {
        context.read<ServiceLeadCubit>().fetchAllServices();
      }
    });
  }

  Future<void> _loadProfilePreview() async {
    try {
      final user = await _apiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profileUser = user;
        _profileImagePath = user?['image'] as String?;
      });
    } catch (_) {}
  }

  Map<String, dynamic> _materialPipelineOf(Map<String, dynamic> customer) {
    final raw = customer['pipeline'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  String _materialStatusOf(Map<String, dynamic> customer) {
    final pipeline = _materialPipelineOf(customer);
    return '${pipeline['status'] ?? 'New'}';
  }

  bool _isCompletedMaterialCustomer(Map<String, dynamic> customer) {
    final pipeline = _materialPipelineOf(customer);
    final status = _materialStatusOf(customer).trim().toLowerCase();
    final dispatch = pipeline['dispatch'];
    final dispatchDate = dispatch is Map
        ? dispatch['dispatchDate']?.toString() ?? ''
        : '';

    if (pipeline['isCompleted'] == true) return true;
    if (dispatchDate.isNotEmpty) return true;

    return {
      'completed',
      'project completed',
      'payment completed',
      'payment',
      'won',
    }.contains(status);
  }

  Future<void> _loadActiveMaterialLeadCount() async {
    try {
      final count = await _apiService.getActiveMaterialLeadCount(
        isCompleted: _isCompletedMaterialCustomer,
        apiService: _apiService,
      );
      if (!mounted) return;
      setState(() {
        _activeMaterialLeadCount = count;
      });
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final local = date.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  Widget _buildProfileAvatar({double size = 40}) {
    final imageUrl = ApiService.buildImageUrl(_profileImagePath);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              backgroundColor:   AppColors.purpleLight1,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? AppSvgIcon(
                      AppSvgAssets.userRound,
                      color:   AppColors.purple500,
                      size: size * 0.52,
                    )
                  : null,
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color:   AppColors.successGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final width = MediaQuery.of(context).size.width;
    final serviceCount = context.select<ServiceLeadCubit, int>((cubit) {
      final state = cubit.state;
      return state is ServiceLeadsLoaded ? state.services.length : 0;
    });
    final crossAxisCount = width >= 1200
        ? 4
        : width >= 800
        ? 3
        : 2;

    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (ctx, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (ctx2, spkState) {
            final solarLeads = solarState is SolarLeadsLoaded
                ? solarState.leads
                : <SolarLeadsModel>[];
            final spkLeads = spkState is SprinklerLeadsLoaded
                ? spkState.leads
                : <SprinklerLeadModel>[];

            final isLoading =
                (solarState is SolarLeadLoading && solarLeads.isEmpty) ||
                (spkState is SprinklerLeadLoading && spkLeads.isEmpty);
            final isRefreshing =
                (solarState is SolarLeadLoading && solarLeads.isNotEmpty) ||
                (spkState is SprinklerLeadLoading && spkLeads.isNotEmpty);

            final totalLeads = solarLeads.length + spkLeads.length;

            final auth = context.read<AppStateCubit>().state;
            final currentUserId = auth is Authenticated
                ? auth.userId.trim().toLowerCase()
                : '';
            final currentUserName = auth is Authenticated
                ? auth.userName.trim().toLowerCase()
                : '';

            final todayVisits =
                solarLeads.where((l) {
                  if (!_isToday(l.visitDate)) return false;
                  final assigned = (l.salesAssigned ?? '').trim().toLowerCase();
                  if (assigned.isEmpty || currentUserName.isEmpty) return true;
                  return assigned == currentUserName;
                }).length +
                spkLeads.where((l) {
                  if (!_isToday(l.visitDate)) return false;
                  final visitPerson = (l.salesPerson ?? '')
                      .trim()
                      .toLowerCase();
                  if (visitPerson.isNotEmpty) {
                    if (currentUserName.isEmpty) return true;
                    return visitPerson == currentUserName;
                  }
                  final assignedId = (l.assignedToId ?? '')
                      .trim()
                      .toLowerCase();
                  final assigned = (l.assignedToName ?? '')
                      .trim()
                      .toLowerCase();
                  if (assignedId.isNotEmpty && currentUserId.isNotEmpty) {
                    return assignedId == currentUserId;
                  }
                  if (assigned.isEmpty || currentUserName.isEmpty) return true;
                  return assigned == currentUserName;
                }).length;

            final todayFollowups =
                solarLeads.where((l) => _isToday(l.nextFollowupDate)).length +
                spkLeads.where((l) => _isToday(l.nextFollowupDate)).length;

            final pendingSolarLeads = solarLeads.where((l) {
              final afterDeal =
                  l.currentStep == SolarStep.dealDone ||
                  l.currentStep == SolarStep.installationAssigned ||
                  l.currentStep == SolarStep.installationStarted ||
                  l.currentStep == SolarStep.installation ||
                  l.currentStep == SolarStep.meter ||
                  l.currentStep == SolarStep.portal ||
                  l.currentStep == SolarStep.subsidy ||
                  l.currentStep == SolarStep.payment;
              final isPaymentCompleted =
                  l.status == 'Payment Completed' || l.isCompleted == true;
              final pending =
                  (l.finalAmount ?? l.totalAmount) - (l.advancePayment ?? 0);
              return afterDeal && !isPaymentCompleted && pending > 0;
            }).toList();

            final pendingSpkLeads = spkLeads.where((l) {
              final afterDeal =
                  l.currentStep == SprinklerStep.dealDone ||
                  l.currentStep == SprinklerStep.installationAssigned ||
                  l.currentStep == SprinklerStep.installationCompleted ||
                  l.currentStep == SprinklerStep.systemTested ||
                  l.currentStep == SprinklerStep.fullPayment;
              final isPaymentCompleted =
                  l.status == 'Payment Completed' || l.isCompleted == true;
              final pending = l.totalAmount - (l.advancePayment ?? 0);
              return afterDeal && !isPaymentCompleted && pending > 0;
            }).toList();

            final pendingCount =
                pendingSolarLeads.length + pendingSpkLeads.length;

            return Scaffold(
              backgroundColor:   AppColors.veryLight3,
              appBar: AppBar(
                backgroundColor:   AppColors.veryLight3,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    // ── Profile Avatar ──────────────────────────────
                    _buildProfileAvatar(size: 40),
                    const SizedBox(width: 12),

                    // ── Name + Greeting ─────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileUser != null
                              ? (_profileUser!['name'] ??
                                        _profileUser!['fullName'] ??
                                        'Team Member')
                                    .toString()
                              : 'Team Member',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.grayDark2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.indigoVariant4,
                          ),
                        ),
                      ],
                    ),

                    // ── Center Title ────────────────────────────────
                    const Spacer(),
                    if (!isMobile)
                      const Text(
                        'Sales Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.purple500,
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
                actions: [
                  if (isRefreshing)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purple500,
                        ),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(
                        right: 12,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            ctx.read<SolarLeadCubit>().fetchAllLeads();
                            ctx2.read<SprinklerLeadCubit>().fetchAllLeads();
                            context.read<ServiceLeadCubit>().fetchAllServices();
                            _loadActiveMaterialLeadCount();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:   AppColors.indigoLight,
                              ),
                            ),
                            child: const AppSvgIcon(
                              AppSvgAssets.refreshCw,
                              color: AppColors.purple500,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              body: SafeArea(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple500,
                        ),
                      )
                    : RefreshIndicator(
                        color:   AppColors.purple500,
                        onRefresh: () async {
                          ctx.read<SolarLeadCubit>().fetchAllLeads();
                          ctx2.read<SprinklerLeadCubit>().fetchAllLeads();
                          context.read<ServiceLeadCubit>().fetchAllServices();
                          await _loadActiveMaterialLeadCount();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 28,
                            12,
                            isMobile ? 16 : 28,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Summary Strip ──────────────────────────────────────
                              _SalesSummaryStrip(
                                totalLeads: totalLeads,
                                solarLeads: solarLeads.length,
                                sprinklerLeads: spkLeads.length,
                              ),
                              const SizedBox(height: 12),

                              // ── Overview Heading ───────────────────
                              const _SectionHeading(title: 'Overview'),
                              const SizedBox(height: 12),

                              // ── Dashboard Grid ─────────────────────
                              GridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: isMobile ? 12 : 16,
                                mainAxisSpacing: isMobile ? 12 : 16,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isMobile ? 1.55 : 1.65,
                                children: [
                                  DashboardCard(
                                    title: 'Solar Leads',
                                    value: '${solarLeads.length}',
                                    svgAsset: AppSvgAssets.sun,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<SolarLeadCubit>(),
                                          child: const SolarLeadsListScreen(
                                            appBarColor: AppColors.amber,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DashboardCard(
                                    title: 'Sprinkler Leads',
                                    value: '${spkLeads.length}',
                                    svgAsset: AppSvgAssets.droplet,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: context
                                              .read<SprinklerLeadCubit>(),
                                          child: const SprinklerLeadsListScreen(
                                            appBarColor: AppColors.cyan,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DashboardCard(
                                    title: "Today's Visits",
                                    value: '$todayVisits',
                                    svgAsset: AppSvgAssets.handshake,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () => _openFilter(
                                      context,
                                      PipelineFilter.todayVisits,
                                    ),
                                  ),
                                  DashboardCard(
                                    title: 'Today Followups',
                                    value: '$todayFollowups',
                                    svgAsset: AppSvgAssets.calendarDays,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const FollowupListScreen(),
                                      ),
                                    ),
                                  ),
                                  DashboardCard(
                                    title: 'Service Requests',
                                    value: '$serviceCount',
                                    svgAsset: AppSvgAssets.cog,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: context
                                              .read<ServiceLeadCubit>(),
                                          child: const ServiceRequestPage(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DashboardCard(
                                    title: 'Add/Sell Material',
                                    value: '$_activeMaterialLeadCount',
                                    svgAsset: AppSvgAssets.packagePlus,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () =>
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MaterialListScreen(
                                                  appBarColor: Color(
                                                    0xFF6366F1,
                                                  ),
                                                ),
                                          ),
                                        ).then(
                                          (_) => _loadActiveMaterialLeadCount(),
                                        ),
                                  ),
                                  DashboardCard(
                                    title: 'Pending Payment',
                                    value: '$pendingCount',
                                    svgAsset: AppSvgAssets.indianRupee,
                                    cardColor:   AppColors.indigo500,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MultiBlocProvider(
                                          providers: [
                                            BlocProvider.value(
                                              value: context
                                                  .read<SolarLeadCubit>(),
                                            ),
                                            BlocProvider.value(
                                              value: context
                                                  .read<SprinklerLeadCubit>(),
                                            ),
                                          ],
                                          child: const AdminPendingPaymentPage(
                                            appBarColor: AppColors.indigo500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFilter(BuildContext ctx, PipelineFilter filter) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: ctx.read<SolarLeadCubit>()),
            BlocProvider.value(value: ctx.read<SprinklerLeadCubit>()),
          ],
          child: PipelineLeadsScreen(filter: filter),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Heading  (same as Installation Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color:   AppColors.purple500,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.grayDark2,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sales Summary Strip
// ─────────────────────────────────────────────────────────────────────────────
class _SalesSummaryStrip extends StatelessWidget {
  final int totalLeads;
  final int solarLeads;
  final int sprinklerLeads;

  const _SalesSummaryStrip({
    required this.totalLeads,
    required this.solarLeads,
    required this.sprinklerLeads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:   AppColors.indigoLight, width: 1),
        boxShadow: [
          BoxShadow(
            color:   AppColors.purple500.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _StripStat(
            label: 'Total Leads',
            value: '$totalLeads',
            color:   AppColors.indigo500,
          ),
          _StripDivider(),
          _StripStat(
            label: 'Solar',
            value: '$solarLeads',
            color:   AppColors.amber,
          ),
          _StripDivider(),
          _StripStat(
            label: 'Sprinkler',
            value: '$sprinklerLeads',
            color:   AppColors.cyan,
          ),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StripStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.purple800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 22, color:   AppColors.indigoLight);
  }
}







