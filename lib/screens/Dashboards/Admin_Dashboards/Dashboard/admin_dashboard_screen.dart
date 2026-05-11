import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/core/app_colors.dart';
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
import 'package:solar_project/screens/Dashboards/Leads/Solar/solar_leads_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_leads_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Material/material_list_screen.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Helper/app_feedback.dart';

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
    final dispatchDate =
        dispatch is Map ? dispatch['dispatchDate']?.toString() ?? '' : '';
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
        _activeMaterialLeadCount =
            customers.where((c) => !_isCompletedMaterialCustomer(c)).length;
      });
    } catch (e) {
      if (!mounted || !showError) return;
      AppFeedback.showError(context, 'Failed to load material leads: $e');
    }
  }

  Future<void> _refreshDashboardData({bool showMaterialError = false}) async {
    if (!mounted) return;
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
    return DateTime(local.year, local.month, local.day)
        .isAtSameMomentAs(dayStart);
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
    ).then((_) {
      if (mounted) _loadProfilePreview();
    });
  }

  // ✅ FIX: All navigation methods moved to class level (NOT inside build/BlocBuilder)
  void _goSolarLeads() {
    final solarCubit = context.read<SolarLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: solarCubit,
          child: const SolarLeadsListScreen(appBarColor: AppColors.primary),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goSpkLeads() {
    final spkCubit = context.read<SprinklerLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: spkCubit,
          child: const SprinklerLeadsListScreen(
              appBarColor: LeadTheme.secondary),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goServiceRequests() {
    final svcCubit = context.read<ServiceLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: svcCubit,
          child:
              const ServiceRequestPage(appBarColor: AppColors.primary),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MaterialListScreen(appBarColor: AppColors.primaryDark),
      ),
    ).then((_) {
      if (mounted) _loadActiveMaterialLeadCount();
    });
  }

  void _goTodaysWork() {
    final solarCubit = context.read<SolarLeadCubit>();
    final spkCubit = context.read<SprinklerLeadCubit>();
    final svcCubit = context.read<ServiceLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: solarCubit),
            BlocProvider.value(value: spkCubit),
            BlocProvider.value(value: svcCubit),
          ],
          child: const TodaysWorkScreen(),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goFollowups() {
    final solarCubit = context.read<SolarLeadCubit>();
    final spkCubit = context.read<SprinklerLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: solarCubit),
            BlocProvider.value(value: spkCubit),
          ],
          child: const FollowupListScreen(
              appBarColor: AppColors.primaryLight),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goInstallPending() {
    final solarCubit = context.read<SolarLeadCubit>();
    final spkCubit = context.read<SprinklerLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: solarCubit),
            BlocProvider.value(value: spkCubit),
          ],
          child: const InstallationPendingScreen(
              appBarColor: AppColors.success),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goPendingPayment() {
    final solarCubit = context.read<SolarLeadCubit>();
    final spkCubit = context.read<SprinklerLeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: solarCubit),
            BlocProvider.value(value: spkCubit),
          ],
          child: const AdminPendingPaymentPage(
              appBarColor: AppColors.primary),
        ),
      ),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerReportsPage()),
    ).then((_) {
      if (mounted) _refreshDashboardData();
    });
  }

  void _goManageUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageUsersPage(
            appBarColor: AppColors.primary),
      ),
    );
  }

  Future<void> _logoutFromDrawer() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Sign Out',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.darkNavy),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    try {
      Navigator.pop(context);
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
              backgroundColor: AppColors.primaryTint,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? AppSvgIcon(AppSvgAssets.userRound,
                      color: AppColors.primary, size: size * 0.52)
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
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDrawer() {
    final name =
        (_profileUser?['name'] ?? _profileUser?['fullName'] ?? 'Admin')
            .toString();
    final email = (_profileUser?['email'] ?? 'No email').toString();
    final phone = (_profileUser?['phone'] ?? 'No phone').toString();

    return Drawer(
      child: SafeArea(
        child: Container(
          color: AppColors.background,
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
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          const Text('My Profile',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGray)),
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Profile Details',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textGray)),
                          const SizedBox(height: 10),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const AppSvgIcon(AppSvgAssets.mail,
                                color: AppColors.primary),
                            title: Text(email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const AppSvgIcon(AppSvgAssets.phone,
                                color: AppColors.primary),
                            title: Text(phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openProfilePage();
                      },
                      icon: const AppSvgIcon(AppSvgAssets.userRound),
                      label: const Text('Open Full Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        side: const BorderSide(color: AppColors.errorLight),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
    final int crossAxisCount =
        width >= 1200 ? 4 : width >= 600 ? 3 : 2;

    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (_, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (_, spkState) {
            return BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
              builder: (_, svcState) {
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
                final todayMid =
                    DateTime(now.year, now.month, now.day);

                final todayMaterialFollowups =
                    _materialCustomers.where((c) {
                  final pipeline = c['pipeline'];
                  if (pipeline is! Map<String, dynamic>) return false;
                  final followUp = pipeline['followUp'];
                  if (followUp is! Map<String, dynamic>) return false;
                  final followUpAt = followUp['followUpAt'];
                  if (followUpAt == null ||
                      followUpAt.toString().trim().isEmpty) return false;
                  final date =
                      DateTime.tryParse(followUpAt.toString());
                  return _isSameDay(date, todayMid);
                }).length;

                final todayFollowups = [
                  ...availableSolarLeads.where((l) {
                    final d = l.nextFollowupDate?.toLocal();
                    if (d == null) return false;
                    return DateTime(d.year, d.month, d.day)
                        .isAtSameMomentAs(todayMid);
                  }),
                  ...availableSprinklerLeads.where((l) {
                    final d = l.nextFollowupDate?.toLocal();
                    if (d == null) return false;
                    return DateTime(d.year, d.month, d.day)
                        .isAtSameMomentAs(todayMid);
                  }),
                ].length;

                final todayFollowupsTotal =
                    todayFollowups + todayMaterialFollowups;

                final todayServicesCount = activeServices
                    .where((s) => _isSameDay(
                        s.serviceDate ?? s.createdAt, todayMid))
                    .length;

                final todaySiteVisitsCount =
                    availableSolarLeads
                        .where(
                            (l) => _isSameDay(l.visitDate, todayMid))
                        .length +
                    availableSprinklerLeads
                        .where(
                            (l) => _isSameDay(l.visitDate, todayMid))
                        .length;

                final todayInstallationsCount =
                    availableSolarLeads.where((l) {
                          final installDate =
                              _solarInstallationDate(l);
                          return l.currentStep.index >=
                                  SolarStep
                                      .installationAssigned.index &&
                              _isSameDay(installDate, todayMid);
                        }).length +
                    availableSprinklerLeads.where((l) {
                      final installDate =
                          _sprinklerInstallationDate(l);
                      return l.currentStep.index >=
                              SprinklerStep
                                  .installationAssigned.index &&
                          _isSameDay(installDate, todayMid);
                    }).length;

                final todaysWorkCount = todayFollowups +
                    todayMaterialFollowups +
                    todayServicesCount +
                    todaySiteVisitsCount +
                    todayInstallationsCount;

                final installPendingSolar = solarLeads
                    .where((l) =>
                        l.currentStep.index >=
                            SolarStep.dealDone.index &&
                        l.currentStep.index <
                            SolarStep.installation.index)
                    .toList();
                final installPendingSprinkler = spkLeads
                    .where((l) =>
                        l.currentStep.index >=
                            SprinklerStep.dealDone.index &&
                        l.currentStep.index <
                            SprinklerStep
                                .installationCompleted.index)
                    .toList();
                final installPending = installPendingSolar.length +
                    installPendingSprinkler.length;

                final pendingSolarLeads = solarLeads.where((l) {
                  final afterDeal =
                      l.currentStep == SolarStep.dealDone ||
                      l.currentStep ==
                          SolarStep.installationAssigned ||
                      l.currentStep ==
                          SolarStep.installationStarted ||
                      l.currentStep == SolarStep.installation ||
                      l.currentStep == SolarStep.meter ||
                      l.currentStep == SolarStep.portal ||
                      l.currentStep == SolarStep.subsidy ||
                      l.currentStep == SolarStep.payment;
                  final isPaymentCompleted =
                      l.status == 'Payment Completed' ||
                          l.isCompleted == true;
                  final pending =
                      (l.finalAmount ?? l.totalAmount) -
                          (l.advancePayment ?? 0);
                  return afterDeal &&
                      !isPaymentCompleted &&
                      pending > 0;
                }).toList();

                final pendingSpkLeads = spkLeads.where((l) {
                  final afterDeal =
                      l.currentStep == SprinklerStep.dealDone ||
                      l.currentStep ==
                          SprinklerStep.installationAssigned ||
                      l.currentStep ==
                          SprinklerStep.installationCompleted ||
                      l.currentStep ==
                          SprinklerStep.systemTested ||
                      l.currentStep == SprinklerStep.fullPayment;
                  final isPaymentCompleted =
                      l.status == 'Payment Completed' ||
                          l.isCompleted == true;
                  final pending =
                      l.totalAmount - (l.advancePayment ?? 0);
                  return afterDeal &&
                      !isPaymentCompleted &&
                      pending > 0;
                }).toList();

                final pendingCount = pendingSolarLeads.length +
                    pendingSpkLeads.length;

                final loading =
                    (solarState is SolarLeadLoading &&
                        solarLeads.isEmpty) ||
                    (spkState is SprinklerLeadLoading &&
                        spkLeads.isEmpty);

                return Scaffold(
                  backgroundColor: AppColors.background,
                  drawer:
                      isMobile ? _buildProfileDrawer() : null,
                  appBar: AppBar(
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    centerTitle: false,
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        _buildProfileAvatar(size: 40),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profileUser != null
                                  ? (_profileUser!['name'] ??
                                          _profileUser![
                                              'fullName'] ??
                                          'Admin')
                                      .toString()
                                  : 'Admin',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.darkNavy,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: AppColors.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(
                            right: 16, top: 8, bottom: 8),
                        child: Material(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(10),
                            onTap: () => _refreshDashboardData(
                                showMaterialError: true),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.primaryTint),
                              ),
                              child: const AppSvgIcon(
                                AppSvgAssets.refreshCw,
                                color: AppColors.primary,
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
                                color: AppColors.primary))
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {
                              await _refreshDashboardData(
                                  showMaterialError: true);
                              await Future.delayed(const Duration(
                                  milliseconds: 800));
                            },
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                  isMobile ? 16 : 28,
                                  12,
                                  isMobile ? 16 : 28,
                                  24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _SummaryStrip(
                                    totalLeads:
                                        availableTotalCount,
                                    solarLeads: solarCount,
                                    sprinklerLeads: spkCount,
                                  ),
                                  const SizedBox(height: 20),
                                  const _SectionHeading(
                                      title: 'Overview'),
                                  const SizedBox(height: 12),
                                  GridView.count(
                                    crossAxisCount:
                                        crossAxisCount,
                                    crossAxisSpacing:
                                        isMobile ? 12 : 16,
                                    mainAxisSpacing:
                                        isMobile ? 12 : 16,
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
                                        title: 'Solar Leads',
                                        value: '$solarCount',
                                        svgAsset: AppSvgAssets.sun,
                                        cardColor: AppColors.primary,
                                        onTap: _goSolarLeads,
                                      ),
                                      DashboardCard(
                                        title: 'Sprinkler Leads',
                                        value: '$spkCount',
                                        svgAsset:
                                            AppSvgAssets.droplet,
                                        cardColor:
                                            AppColors.primary,
                                        onTap: _goSpkLeads,
                                      ),
                                      DashboardCard(
                                        title: 'Service Requests',
                                        value: '$serviceCount',
                                        svgAsset: AppSvgAssets.cog,
                                        cardColor: AppColors.primary,
                                        onTap: _goServiceRequests,
                                      ),
                                      DashboardCard(
                                        title: 'Add/Sell Material',
                                        value:
                                            '$_activeMaterialLeadCount',
                                        svgAsset:
                                            AppSvgAssets.packagePlus,
                                        cardColor:
                                            AppColors.primaryDark,
                                        onTap: _goMaterial,
                                      ),
                                      DashboardCard(
                                        title: "Today's Work",
                                        value: '$todaysWorkCount',
                                        svgAsset:
                                            AppSvgAssets.calendarDays,
                                        cardColor: AppColors.primary,
                                        onTap: _goTodaysWork,
                                      ),
                                      DashboardCard(
                                        title:
                                            "Today's Follow-ups",
                                        value:
                                            '$todayFollowupsTotal',
                                        svgAsset:
                                            AppSvgAssets.calendarDays,
                                        cardColor:
                                            AppColors.primary,
                                        onTap: _goFollowups,
                                      ),
                                      DashboardCard(
                                        title:
                                            'Installation Pending',
                                        value: '$installPending',
                                        svgAsset:
                                            AppSvgAssets.hammer,
                                        cardColor:
                                            AppColors.primary,
                                        onTap: _goInstallPending,
                                      ),
                                      DashboardCard(
                                        title: 'Pending Payment',
                                        value: '$pendingCount',
                                        svgAsset:
                                            AppSvgAssets.indianRupee,
                                        cardColor: AppColors.primary,
                                        onTap: _goPendingPayment,
                                      ),
                                      BlocBuilder<RevenueCubit,
                                          RevenueState>(
                                        builder: (_, revState) {
                                          String revenueValue =
                                              '...';
                                          if (revState
                                              is RevenueLoaded) {
                                            final fmt =
                                                NumberFormat.compact(
                                                    locale: 'en_IN');
                                            revenueValue =
                                                '₹ ${fmt.format(revState.totalRevenue)}';
                                          }
                                          return DashboardCard(
                                            title:
                                                'Revenue Summary',
                                            value: revenueValue,
                                            svgAsset: AppSvgAssets
                                                .chartNoAxisCombined,
                                            cardColor:
                                                AppColors.solar,
                                            onTap: _goReports,
                                          );
                                        },
                                      ),
                                      DashboardCard(
                                        title: 'Manage Users',
                                        value: '',
                                        svgAsset:
                                            AppSvgAssets.userRoundCog,
                                        cardColor: AppColors.primary,
                                        onTap: _goManageUsers,
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

// ── Summary Strip ─────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int totalLeads, solarLeads, sprinklerLeads;
  const _SummaryStrip({
    required this.totalLeads,
    required this.solarLeads,
    required this.sprinklerLeads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTint, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
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
              color: AppColors.primaryDark),
          _StripDivider(),
          _StripStat(
              label: 'Solar',
              value: '$solarLeads',
              color: AppColors.primary),
          _StripDivider(),
          _StripStat(
              label: 'Sprinkler',
              value: '$sprinklerLeads',
              color: AppColors.primaryLight),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StripStat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.4)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGray)),
          ],
        ),
      );
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 22, color: AppColors.primaryTint);
}

// ── Section Heading ───────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                  letterSpacing: -0.2)),
        ],
      );
}