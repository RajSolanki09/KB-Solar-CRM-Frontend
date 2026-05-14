// lib/screens/Dashboards/Installation/installation_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_cubit.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_state.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/installation_model.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/Dashboard/todays-jobs_screen.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/Dashboard/pending_installation.dart';
import 'package:solar_project/services/api_service.dart';

class InstallationDashboardScreen extends StatefulWidget {
  const InstallationDashboardScreen({super.key});

  @override
  State<InstallationDashboardScreen> createState() =>
      _InstallationDashboardScreenState();
}

class _InstallationDashboardScreenState
    extends State<InstallationDashboardScreen> {
  bool _showTodaysJobs = false;
  bool _showPendingJobs = false;
  final Set<String> _locallyDeletedLeadIds = {};

  // ── Profile ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _profileUser;
  String? _profileImagePath;

  // ── Stats ─────────────────────────────────────────────────────────────────
  List<InstallationModel> _activeLeads = [];
  List<InstallationModel> _completedLeads = [];
  int _totalAssigned = 0;
  int _solarLeads = 0;
  int _sprinklerLeads = 0;
  int _pendingCount = 0;
  int _todayJobsCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfilePreview();
    Future.microtask(() {
      if (mounted) {
        context.read<InstallationCubit>().fetchInstallations();
      }
    });
  }

  Future<void> _loadProfilePreview() async {
    try {
      final user = await ApiService().getProfile();
      if (!mounted) return;
      setState(() {
        _profileUser = user;
        _profileImagePath = user?['image'] as String?;
      });
    } catch (_) {}
  }

  void _computeStats(List<InstallationModel> allLeads) {
    final now = DateTime.now();

    bool isToday(DateTime? dt) {
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }

    final leads = allLeads
        .where((l) => !_locallyDeletedLeadIds.contains(l.id))
        .toList();

    _activeLeads = leads
        .where(
          (m) =>
              !m.projectCompleted &&
              !(m.projectType.toLowerCase() == 'solar' &&
                  m.status == InstallationStatus.meterInstalled),
        )
        .toList();

    _completedLeads = leads.where((m) => m.projectCompleted).toList();

    _totalAssigned = _activeLeads.length;
    _solarLeads = _activeLeads
        .where((m) => m.projectType.toLowerCase() == 'solar')
        .length;
    _sprinklerLeads = _activeLeads
        .where((m) => m.projectType.toLowerCase() != 'solar')
        .length;
    _pendingCount = _activeLeads.where((m) {
      final dt = m.scheduledDate;
      if (dt == null) return false;
      final todayMid = DateTime(now.year, now.month, now.day);
      return DateTime(dt.year, dt.month, dt.day).isBefore(todayMid) &&
          m.status != InstallationStatus.installationStarted;
    }).length;
    _todayJobsCount = _activeLeads
        .where((m) => isToday(m.scheduledDate))
        .length;
    _completedCount = _completedLeads.length;
  }

  void _openPending() {
    setState(() {
      _showTodaysJobs = false;
      _showPendingJobs = true;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
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
              backgroundColor: AppColors.purpleLight1,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? AppSvgIcon(
                      AppSvgAssets.userRound,
                      color: AppColors.purple500,
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
                color: AppColors.successGreen,
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
    if (_showPendingJobs) {
      return PendingInstallationsScreen(
        appBarColor: AppColors.error,
        onBack: () => setState(() => _showPendingJobs = false),
      );
    }

    if (_showTodaysJobs) {
      return TodaysJobsScreen(
        appBarColor: AppColors.purpleDark,
        onBack: () => setState(() => _showTodaysJobs = false),
      );
    }

    final isMobile = Responsive.isMobile(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1400
        ? 5
        : width >= 1100
        ? 4
        : width >= 800
        ? 3
        : 2;

    return BlocBuilder<InstallationCubit, InstallationState>(
      buildWhen: (prev, curr) =>
          curr is InstallationsLoaded ||
          curr is InstallationLoading ||
          curr is InstallationError,
      builder: (ctx, state) {
        final allLeads = state is InstallationsLoaded
            ? state.installations
            : <InstallationModel>[];

        final loading = state is InstallationLoading && allLeads.isEmpty;

        if (state is InstallationsLoaded) {
          _computeStats(allLeads);
        }

        return Scaffold(
          backgroundColor: AppColors.veryLight3,
          appBar: AppBar(
            backgroundColor: AppColors.veryLight3,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true, // ✅ FIX: title ab center mein
            // ✅ FIX: Profile avatar + name/greeting leading mein move kiya
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  _buildProfileAvatar(size: 36),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            fontSize: 13,
                            color: AppColors.grayDark2,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.indigoVariant4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leadingWidth: 180, // ✅ FIX: left side ke liye fixed space
            // ✅ FIX: Sirf title text — koi Spacer nahi
            title: const Text(
              'Installation Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.purple500,
              ),
            ),
            actions: [
              if (state is InstallationLoading && allLeads.isNotEmpty)
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
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () =>
                          ctx.read<InstallationCubit>().fetchInstallations(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.indigoLight),
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
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.purple500),
                  )
                : state is InstallationError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSvgIcon(
                          AppSvgAssets.triangleAlert,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ctx
                              .read<InstallationCubit>()
                              .fetchInstallations(),
                          icon: const AppSvgIcon(AppSvgAssets.refreshCw),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple500,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.purple500,
                    onRefresh: () async =>
                        ctx.read<InstallationCubit>().fetchInstallations(),
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
                          // ── Assignment Banner ──────────────────────
                          if (_totalAssigned > 0)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.veryLight5,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF7B2FF7,
                                  ).withValues(alpha: 0.20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const AppSvgIcon(
                                    AppSvgAssets.idCard,
                                    color: AppColors.purple500,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_totalAssigned job${_totalAssigned == 1 ? '' : 's'} assigned',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.purple500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '☀ $_solarLeads  💧 $_sprinklerLeads',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ── Overview Heading ───────────────────────
                          const _SectionHeading(title: 'Overview'),
                          const SizedBox(height: 12),

                          // ── Dashboard Grid ─────────────────────────
                          GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: isMobile ? 12 : 16,
                            mainAxisSpacing: isMobile ? 12 : 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isMobile ? 1.55 : 1.65,
                            children: [
                              DashboardCard(
                                title: 'Solar Installation',
                                value: '$_solarLeads',
                                svgAsset: AppSvgAssets.hammer,
                                cardColor: AppColors.indigo500,
                                onTap: () => ctx
                                    .read<InstallationNavCubit>()
                                    .openMyInstallations(projectType: 'solar'),
                              ),
                              DashboardCard(
                                title: 'Sprinkler Installation',
                                value: '$_sprinklerLeads',
                                svgAsset: AppSvgAssets.idCard,
                                cardColor: AppColors.indigo500,
                                onTap: () => ctx
                                    .read<InstallationNavCubit>()
                                    .openMyInstallations(
                                      projectType: 'sprinkler',
                                    ),
                              ),
                              DashboardCard(
                                title: "Today's Jobs",
                                value: '$_todayJobsCount',
                                svgAsset: AppSvgAssets.calendarDays,
                                cardColor: AppColors.indigo500,
                                onTap: () => setState(() {
                                  _showPendingJobs = false;
                                  _showTodaysJobs = true;
                                }),
                              ),
                              DashboardCard(
                                title: 'Pending',
                                value: '$_pendingCount',
                                svgAsset: AppSvgAssets.triangleAlert,
                                cardColor: AppColors.indigo500,
                                onTap: _openPending,
                              ),
                              DashboardCard(
                                title: 'Completed',
                                value: '$_completedCount',
                                svgAsset: AppSvgAssets.circleCheckBig,
                                cardColor: AppColors.indigo500,
                                onTap: () => ctx
                                    .read<InstallationNavCubit>()
                                    .changePage(InstallationNavPage.history),
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
            color: AppColors.indigo500,
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