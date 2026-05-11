import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/Home/all_services_screen.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/core/app_colors.dart';

class ServiceDashboardPage extends StatefulWidget {
  const ServiceDashboardPage({super.key});
  @override
  State<ServiceDashboardPage> createState() => _State();
}

class _State extends State<ServiceDashboardPage> {
  // ── Profile ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _profileUser;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfilePreview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ServiceLeadCubit>().fetchAllServices();
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
              backgroundColor: AppColors.primaryTint,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? AppSvgIcon(
                      AppSvgAssets.userRound,
                      color: AppColors.primary,
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

  void _go(ServiceFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ServiceLeadCubit>(),
          child: AllServicesScreen(initialFilter: filter),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1200
        ? 4
        : width >= 800
        ? 3
        : 2;

    return BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
      builder: (ctx, state) {
        List<ServiceRequestModel> services = [];
        if (state is ServiceLeadsLoaded) services = state.services;

        final now = DateTime.now();
        final total = services.where((s) => !s.isComplete).length;
        final today = services.where((s) {
          final d = s.serviceDate ?? s.createdAt;
          return d.year == now.year &&
              d.month == now.month &&
              d.day == now.day &&
              !s.isComplete;
        }).length;
        final pending = services
            .where((s) => s.status == 'Open' || s.status == 'Pending')
            .length;
        final inProg = services.where((s) => s.status == 'In Progress').length;
        final completed = services.where((s) => s.isComplete).length;
        final free = services
            .where((s) => s.chargeType == 'Free' && !s.isComplete)
            .length;
        final paid = services
            .where((s) => s.chargeType == 'Paid' && !s.isComplete)
            .length;

        final isLoading = state is ServiceLeadLoading && services.isEmpty;
        final isRefreshing = state is ServiceLeadLoading && services.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                _buildProfileAvatar(size: 36), // ← size thoda kam karo
                const SizedBox(width: 8),
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
                        fontSize: 13, // ← size kam karo
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Service Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16, // ← 20 se 16 karo
                    color: AppColors.primary,
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
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () =>
                          ctx.read<ServiceLeadCubit>().fetchAllServices(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryTint),
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
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ctx.read<ServiceLeadCubit>().fetchAllServices(),
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
                          // ── Summary Strip ──────────────────────────
                          _ServiceSummaryStrip(
                            total: total,
                            free: free,
                            paid: paid,
                            completed: completed,
                          ),
                          const SizedBox(height: 12),

                          // ── Assignment Banner ──────────────────────
                          if (total > 0)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
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
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$total active service${total == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '🔧 $inProg in progress  ⏳ $pending pending',
                                    style: TextStyle(
                                      color: AppColors.background,
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
                            childAspectRatio: isMobile ? 1.3 : 1.4,
                            children: [
                              DashboardCard(
                                title: 'Total Services',
                                value: '$total',
                                svgAsset: AppSvgAssets.clipboardList,
                                cardColor: AppColors.primary,
                                onTap: () => _go(ServiceFilter.all),
                              ),
                              DashboardCard(
                                title: 'Today Services',
                                value: '$today',
                                svgAsset: AppSvgAssets.calendarDays,
                                cardColor: AppColors.primary,
                                onTap: () => _go(ServiceFilter.today),
                              ),
                              DashboardCard(
                                title: 'Pending',
                                value: '$pending',
                                svgAsset: AppSvgAssets.triangleAlert,
                                cardColor: AppColors.solar,
                                onTap: () => _go(ServiceFilter.pending),
                              ),
                              DashboardCard(
                                title: 'In Progress',
                                value: '$inProg',
                                svgAsset: AppSvgAssets.refreshCw,
                                cardColor: AppColors.primaryDark,
                                onTap: () => _go(ServiceFilter.inProgress),
                              ),
                              DashboardCard(
                                title: 'Completed',
                                value: '$completed',
                                svgAsset: AppSvgAssets.circleCheckBig,
                                cardColor: AppColors.success,
                                onTap: () => _go(ServiceFilter.completed),
                              ),
                              DashboardCard(
                                title: 'Free Service',
                                value: '$free',
                                svgAsset: AppSvgAssets.handshake,
                                cardColor: AppColors.error,
                                onTap: () => _go(ServiceFilter.free),
                              ),
                              DashboardCard(
                                title: 'Paid Service',
                                value: '$paid',
                                svgAsset: AppSvgAssets.indianRupee,
                                cardColor: AppColors.success,
                                onTap: () => _go(ServiceFilter.paid),
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
// Service Summary Strip
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceSummaryStrip extends StatelessWidget {
  final int total;
  final int free;
  final int paid;
  final int completed;

  const _ServiceSummaryStrip({
    required this.total,
    required this.free,
    required this.paid,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTint, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _StripStat(label: 'Total', value: '$total', color: AppColors.primary),
          _StripDivider(),
          _StripStat(label: 'Free', value: '$free', color: AppColors.error),
          _StripDivider(),
          _StripStat(label: 'Paid', value: '$paid', color: AppColors.success),
          _StripDivider(),
          _StripStat(
            label: 'Done',
            value: '$completed',
            color: AppColors.success,
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
              color: AppColors.textGray,
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
    return Container(width: 1, height: 22, color: AppColors.primaryTint);
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
