import 'package:flutter/material.dart' hide Text;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Installation/installation_pending_screen.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/ManageUser/manage_user.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Profile/admin_profile.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/service_request.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/peding_payment.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/todays_work_screen.dart';
import 'package:solar_project/Cubits/Revenue/revenue_cubit.dart';
import 'package:solar_project/Cubits/Revenue/revenue_state.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Reports/owner_reports.dart';
import 'package:solar_project/screens/Dashboards/Followups/followup_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_leads_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Material/material_list_screen.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Helper/app_feedback.dart';

import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/admin_bottom_nav_bar.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/admin_sidebar.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_cubit.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_state.dart';
import 'package:solar_project/Helper/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _State();
}

class _State extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileUser;
  String? _profileImagePath;
  int _activeMaterialLeadCount = 0;
  List<Map<String, dynamic>> _materialCustomers = const [];

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
      final revState = context.read<RevenueCubit>().state;
      if (revState is! RevenueLoaded) {
        context.read<RevenueCubit>().fetchRevenue();
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

  Future<void> _loadActiveMaterialLeadCount({bool showError = false}) async {
    try {
      final customers = await _apiService.getMaterialCustomers();
      if (!mounted) return;
      setState(() {
        _materialCustomers = customers;
        _activeMaterialLeadCount = customers
            .where((customer) => !_isCompletedMaterialCustomer(customer))
            .length;
      });
    } catch (e) {
      if (!mounted || !showError) return;
      AppFeedback.showError(context, 'Failed to load material leads: $e');
    }
  }

  Future<void> _refreshDashboardData({bool showMaterialError = false}) async {
    context.read<SolarLeadCubit>().fetchAllLeads();
    context.read<SprinklerLeadCubit>().fetchAllLeads();
    context.read<ServiceLeadCubit>().fetchAllServices();
    context.read<RevenueCubit>().fetchRevenue();
    await _loadActiveMaterialLeadCount(showError: showMaterialError);
  }

  bool _isAvailableSolarLead(SolarLeadsModel lead) {
    if (lead.isCompleted) return false;
    if (lead.currentStep == SolarStep.projectCompleted) return false;
    final status = lead.status.trim().toLowerCase();
    if (status == 'project completed' || status == 'payment completed') {
      return false;
    }
    return true;
  }

  bool _isAvailableSprinklerLead(SprinklerLeadModel lead) {
    if (lead.isCompleted) return false;
    if (lead.currentStep == SprinklerStep.projectCompleted) return false;
    final status = lead.status.trim().toLowerCase();
    if (status == 'project completed' || status == 'payment completed') {
      return false;
    }
    return true;
  }

  bool _isSameDay(DateTime? date, DateTime dayStart) {
    if (date == null) return false;
    final local = date.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
    ).isAtSameMomentAs(dayStart);
  }

  DateTime? _solarInstallationDate(SolarLeadsModel lead) {
    return lead.installationData.completedDate ??
        lead.installationData.startDate ??
        lead.installationAssignData.scheduledDate;
  }

  DateTime? _sprinklerInstallationDate(SprinklerLeadModel lead) {
    return lead.installationData.completedAt ??
        lead.installationData.startedAt ??
        lead.installationAssignData.scheduledDate;
  }

  void _openProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerProfilePage()),
    ).then((_) => _loadProfilePreview());
  }

  Future<void> _logoutFromDrawer() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    try {
      final scaffoldState = Scaffold.maybeOf(context);
      if (scaffoldState != null && scaffoldState.isDrawerOpen) {
        Navigator.of(context).pop();
      }

      await _apiService.logout();
      if (!mounted) return;
      context.read<AppStateCubit>().logout();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Logout failed: $e');
    }
  }

  Widget _buildProfileAvatar({double size = 34}) {
    final imageUrl = ApiService.buildImageUrl(_profileImagePath);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              backgroundColor: AppColors.primaryLighter,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? AppSvgIcon(
                      AppSvgAssets.userRound,
                      color: AppColors.accent1,
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
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDrawer() {
    final name = (_profileUser?['name'] ?? _profileUser?['fullName'] ?? 'Admin')
        .toString();
    final email = (_profileUser?['email'] ?? 'No email').toString();
    final phone = (_profileUser?['phone'] ?? 'No phone').toString();

    return Drawer(
      child: SafeArea(
        child: Container(
          color: AppColors.bgSecondary,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    _buildProfileAvatar(size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.bgPrimary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const AppSvgIcon(
                              AppSvgAssets.mail,
                              color: AppColors.accent1,
                            ),
                            title: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const AppSvgIcon(
                              AppSvgAssets.phone,
                              color: AppColors.accent1,
                            ),
                            title: Text(
                              phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        final scaffoldState = Scaffold.maybeOf(context);
                        if (scaffoldState != null && scaffoldState.isDrawerOpen) {
                          Navigator.of(context).pop();
                        }
                        _openProfilePage();
                      },
                      icon: const AppSvgIcon(AppSvgAssets.userRound),
                      label: const Text('Open Full Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent1,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _logoutFromDrawer,
                      icon: const AppSvgIcon(AppSvgAssets.logOut),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width >= 1200
        ? 4
        : width >= 600
        ? 3
        : 2;

    return BlocBuilder<AdminNavCubit, AdminNavPage>(
      builder: (context, navState) {
        return Scaffold(
          backgroundColor: AppColors.primaryLightest,
          drawer: isMobile ? _buildProfileDrawer() : null,
          body: Row(
            children: [
              if (!isMobile) const Sidebar(),
              Expanded(
                child: _buildBody(navState, isMobile, width, crossAxisCount),
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? const AdminBottomNavBar() : null,
        );
      },
    );
  }

  Widget _buildBody(AdminNavPage navState, bool isMobile, double width,
      int crossAxisCount) {
    switch (navState) {
      case AdminNavPage.dashboard:
        return _buildDashboard(isMobile, width, crossAxisCount);
      case AdminNavPage.leads:
        return const SolarLeadsListScreen(appBarColor: AppColors.accent1);
      case AdminNavPage.service:
        return const ServiceRequestPage(appBarColor: AppColors.accent1);
      case AdminNavPage.reports:
        return const OwnerReportsPage();
      case AdminNavPage.profile:
        return const OwnerProfilePage();
    }
  }

  Widget _buildDashboard(bool isMobile, double width, int crossAxisCount) {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (ctx, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (ctx2, spkState) {
            return BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
              builder: (ctx3, svcState) {
                final solarLeads = solarState is SolarLeadsLoaded
                    ? solarState.leads
                    : <SolarLeadsModel>[];
                final spkLeads = spkState is SprinklerLeadsLoaded
                    ? spkState.leads
                    : <SprinklerLeadModel>[];

                final availableSolarLeads =
                    solarLeads.where(_isAvailableSolarLead).toList();
                final availableSprinklerLeads =
                    spkLeads.where(_isAvailableSprinklerLead).toList();

                final solarCount = availableSolarLeads.length;
                final spkCount = availableSprinklerLeads.length;
                final availableTotalCount = solarCount + spkCount;
                final svcServices = svcState is ServiceLeadsLoaded
                    ? svcState.services
                    : <ServiceRequestModel>[];
                final activeServices =
                    svcServices.where((s) => !s.isComplete).toList();
                final serviceCount = activeServices.length;

                final now = DateTime.now();
                final todayMid = DateTime(now.year, now.month, now.day);

                final todayMaterialFollowups = _materialCustomers.where((c) {
                  final pipeline = c['pipeline'];
                  if (pipeline is! Map<String, dynamic>) return false;
                  final followUp = pipeline['followUp'];
                  if (followUp is! Map<String, dynamic>) return false;
                  final followUpAt = followUp['followUpAt'];
                  if (followUpAt == null ||
                      followUpAt.toString().trim().isEmpty) {
                    return false;
                  }
                  final date = DateTime.tryParse(followUpAt.toString());
                  return _isSameDay(date, todayMid);
                }).length;

                final todayFollowups = [
                  ...availableSolarLeads.where((l) {
                    final d = l.nextFollowupDate?.toLocal();
                    if (d == null) return false;
                    return DateTime(
                      d.year,
                      d.month,
                      d.day,
                    ).isAtSameMomentAs(todayMid);
                  }),
                  ...availableSprinklerLeads.where((l) {
                    final d = l.nextFollowupDate?.toLocal();
                    if (d == null) return false;
                    return DateTime(
                      d.year,
                      d.month,
                      d.day,
                    ).isAtSameMomentAs(todayMid);
                  }),
                ].length;
                final todayFollowupsTotal =
                    todayFollowups + todayMaterialFollowups;

                final todayServicesCount = activeServices.where((s) {
                  final eventDate = s.serviceDate ?? s.createdAt;
                  return _isSameDay(eventDate, todayMid);
                }).length;

                final todaySiteVisitsCount =
                    availableSolarLeads
                        .where((l) => _isSameDay(l.visitDate, todayMid))
                        .length +
                    availableSprinklerLeads
                        .where((l) => _isSameDay(l.visitDate, todayMid))
                        .length;

                final todayInstallationsCount =
                    availableSolarLeads.where((l) {
                      final installDate = _solarInstallationDate(l);
                      return l.currentStep.index >=
                              SolarStep.installationAssigned.index &&
                          _isSameDay(installDate, todayMid);
                    }).length +
                    availableSprinklerLeads.where((l) {
                      final installDate = _sprinklerInstallationDate(l);
                      return l.currentStep.index >=
                              SprinklerStep.installationAssigned.index &&
                          _isSameDay(installDate, todayMid);
                    }).length;

                final todaysWorkCount = todayFollowups +
                    todayMaterialFollowups +
                    todayServicesCount +
                    todaySiteVisitsCount +
                    todayInstallationsCount;

                final installPendingSolar = solarLeads
                    .where(
                      (l) =>
                          l.currentStep.index >= SolarStep.dealDone.index &&
                          l.currentStep.index < SolarStep.installation.index,
                    )
                    .toList();
                final installPendingSprinkler = spkLeads
                    .where(
                      (l) =>
                          l.currentStep.index >= SprinklerStep.dealDone.index &&
                          l.currentStep.index <
                              SprinklerStep.installationCompleted.index,
                    )
                    .toList();
                final installPending =
                    installPendingSolar.length + installPendingSprinkler.length;

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
                  final pending = (l.finalAmount ?? l.totalAmount) -
                      (l.advancePayment ?? 0);
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
                final loading =
                    (solarState is SolarLeadLoading && solarLeads.isEmpty) ||
                    (spkState is SprinklerLeadLoading && spkLeads.isEmpty);

                return Scaffold(
                  backgroundColor: AppColors.primaryLightest,
                  appBar: AppBar(
                    backgroundColor: AppColors.primaryLightest,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    centerTitle: false,
                    leading: isMobile
                        ? Builder(builder: (scaffoldCtx) {
                            return IconButton(
                              icon: const Icon(Icons.menu,
                                  color: AppColors.textPrimary),
                              onPressed: () {
                                Scaffold.of(scaffoldCtx).openDrawer();
                              },
                            );
                          })
                        : null,
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        _buildProfileAvatar(size: 40),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _profileUser != null
                                    ? (_profileUser!['name'] ??
                                            _profileUser!['fullName'] ??
                                            'Admin')
                                        .toString()
                                    : 'Admin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getGreeting(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.accent1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: AppColors.accent1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              _refreshDashboardData(showMaterialError: true);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryLightest,
                                ),
                              ),
                              child: const AppSvgIcon(
                                AppSvgAssets.refreshCw,
                                color: AppColors.accent1,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent1,
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.accent1,
                            onRefresh: () async {
                              await _refreshDashboardData(
                                showMaterialError: true,
                              );
                              await Future.delayed(
                                const Duration(milliseconds: 800),
                              );
                            },
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : 28,
                                12,
                                isMobile ? 16 : 28,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SummaryStrip(
                                    totalLeads: availableTotalCount,
                                    solarLeads: solarCount,
                                    sprinklerLeads: spkCount,
                                  ),
                                  const SizedBox(height: 20),
                                  const _SectionHeading(title: 'Overview'),
                                  const SizedBox(height: 12),
                                  GridView.count(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: isMobile ? 12 : 16,
                                    mainAxisSpacing: isMobile ? 12 : 16,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    childAspectRatio: width >= 1200
                                        ? 1.8
                                        : width >= 900
                                        ? 2.2
                                        : width >= 600
                                        ? 1.7
                                        : 1.8,
                                    children: [
                                      DashboardCard(
                                        title: 'Project Leads',
                                        value: '$solarCount',
                                        svgAsset: AppSvgAssets.sun,
                                        cardColor: AppColors.accent1,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<SolarLeadCubit>(),
                                              child: const SolarLeadsListScreen(
                                                appBarColor: AppColors.accent1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Sprinkler Leads',
                                        value: '$spkCount',
                                        svgAsset: AppSvgAssets.droplet,
                                        cardColor: AppColors.accent1,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<SprinklerLeadCubit>(),
                                              child:
                                                  const SprinklerLeadsListScreen(
                                                appBarColor: AppColors.accent1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Service Requests',
                                        value: '$serviceCount',
                                        svgAsset: AppSvgAssets.cog,
                                        cardColor: AppColors.accent1,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<ServiceLeadCubit>(),
                                              child: const ServiceRequestPage(
                                                appBarColor: AppColors.accent1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Add/Sell Material',
                                        value: '$_activeMaterialLeadCount',
                                        svgAsset: AppSvgAssets.packagePlus,
                                        cardColor: AppColors.accent1,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MaterialListScreen(
                                              appBarColor: AppColors.accent1,
                                            ),
                                          ),
                                        ).then(
                                          (_) => _loadActiveMaterialLeadCount(),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Today\'s Work',
                                        value: '$todaysWorkCount',
                                        svgAsset: AppSvgAssets.calendarDays,
                                        cardColor: AppColors.accent1,
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
                                                BlocProvider.value(
                                                  value: context
                                                      .read<ServiceLeadCubit>(),
                                                ),
                                              ],
                                              child: const TodaysWorkScreen(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Today\'s Follow-ups',
                                        value: '$todayFollowupsTotal',
                                        svgAsset: AppSvgAssets.calendarDays,
                                        cardColor: AppColors.accent1,
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
                                              child: const FollowupListScreen(
                                                appBarColor: AppColors.accent1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Installation Pending',
                                        value: '$installPending',
                                        svgAsset: AppSvgAssets.hammer,
                                        cardColor: AppColors.accent1,
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
                                              child:
                                                  const InstallationPendingScreen(
                                                appBarColor: AppColors.accent1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DashboardCard(
                                        title: 'Pending Payment',
                                        value: '$pendingCount',
                                        svgAsset: AppSvgAssets.indianRupee,
                                        cardColor: AppColors.accent1,
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
                                              child:
                                                  const AdminPendingPaymentPage(
                                                appBarColor: AppColors.accent1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      BlocBuilder<RevenueCubit, RevenueState>(
                                        builder: (ctx, revState) {
                                          String revenueValue = '...';
                                          if (revState is RevenueLoaded) {
                                            final fmt = NumberFormat.compact(
                                              locale: 'en_IN',
                                            );
                                            revenueValue =
                                                '₹ ${fmt.format(revState.totalRevenue)}';
                                          }
                                          return DashboardCard(
                                            title: 'Revenue Summary',
                                            value: revenueValue,
                                            svgAsset: AppSvgAssets
                                                .chartNoAxisCombined,
                                            cardColor: AppColors.accent1,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const OwnerReportsPage(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      DashboardCard(
                                        title: 'Manage Users',
                                        value: '',
                                        svgAsset: AppSvgAssets.userRoundCog,
                                        cardColor: AppColors.accent1,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AdminManageUsersPage(
                                              appBarColor: AppColors.accent1,
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
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Summary Strip
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int totalLeads;
  final int solarLeads;
  final int sprinklerLeads;

  const _SummaryStrip({
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
        border: Border.all(color: AppColors.primaryLightest, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent1.withOpacity(0.05),
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
            color: AppColors.accent1,
          ),
          const _StripDivider(),
          _StripStat(
            label: 'Project',
            value: '$solarLeads',
            color: AppColors.accent1,
          ),
          const _StripDivider(),
          _StripStat(
            label: 'Sprinkler',
            value: '$sprinklerLeads',
            color: AppColors.accent1,
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
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.accent1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  const _StripDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 22, color: AppColors.primaryLightest);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Heading
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
            color: AppColors.accent1,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Card
// ─────────────────────────────────────────────────────────────────────────────
class _DashCard extends StatefulWidget {
  final String title;
  final String value;
  final String svgAsset;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _DashCard({
    required this.title,
    required this.value,
    required this.svgAsset,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_DashCard> createState() => _DashCardState();
}

class _DashCardState extends State<_DashCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -8,
                bottom: -16,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: AppSvgIcon(
                          widget.svgAsset,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}