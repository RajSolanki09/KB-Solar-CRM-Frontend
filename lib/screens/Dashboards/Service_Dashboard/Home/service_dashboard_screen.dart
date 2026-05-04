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
import 'package:solar_project/Helper/app_colors.dart';

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
              backgroundColor: AppColors.primaryLightest,
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
                  color: AppColors.accent1,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.4),
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
        backgroundColor: AppColors.primaryLightest,
        body: SafeArea(
             child: isLoading
                 ? const Center(
                     child: CircularProgressIndicator(color: AppColors.accent2))
                 : RefreshIndicator(
                    color: AppColors.accent1,
                    onRefresh: () =>
                        context.read<ServiceLeadCubit>().fetchAllServices(),
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
                                 color: AppColors.bgPrimary,
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(
                                   color: AppColors.accent1.withOpacity(0.20),
                                 ),
                               ),
                               child: Row(
                                 children: [
                                   const AppSvgIcon(
                                     AppSvgAssets.idCard,
                                     color: AppColors.accent1,
                                   ),
                                   const SizedBox(width: 6),
                                   Text(
                                     '$total active service${total == 1 ? '' : \'s\'}',
                                     style: TextStyle(
                                       fontWeight: FontWeight.w800,
                                       color: AppColors.accent1,
                                       fontSize: 12),
                                   
                                   const Spacer(),
                                   Text(
                                     '🔧 $inProg in progress  ⏳ $pending pending',
                                     style: TextStyle(
                                       color: AppColors.textSecondary,
                                       fontSize: 11),
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
                                 title: 'Total Services',
                                 value: '$total',
                                 svgAsset: AppSvgAssets.clipboardList,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.all),
                               ),
                               DashboardCard(
                                 title: 'Today Services',
                                 value: '$today',
                                 svgAsset: AppSvgAssets.calendarDays,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.today),
                               ),
                               DashboardCard(
                                 title: 'Pending',
                                 value: '$pending',
                                 svgAsset: AppSvgAssets.triangleAlert,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.pending),
                               ),
                               DashboardCard(
                                 title: 'In Progress',
                                 value: '$inProg',
                                 svgAsset: AppSvgAssets.refreshCw,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.inProgress),
                               ),
                               DashboardCard(
                                 title: 'Completed',
                                 value: '$completed',
                                 svgAsset: AppSvgAssets.circleCheckBig,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.completed),
                               ),
                               DashboardCard(
                                 title: 'Free Service',
                                 value: '$free',
                                 svgAsset: AppSvgAssets.handshake,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.free),
                               ),
                               DashboardCard(
                                 title: 'Paid Service',
                                 value: '$paid',
                                 svgAsset: AppSvgAssets.indianRupee,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.paid),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
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
                                 color: AppColors.bgPrimary,
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(
                                   color: AppColors.accent1.withOpacity(0.20),
                                 ),
                               ),
                               child: Row(
                                 children: [
                                   const AppSvgIcon(
                                     AppSvgAssets.idCard,
                                     color: AppColors.accent1,
                                     ),
                                   const SizedBox(width: 6),
                                   Text(
                                     '$total active service${total == 1 ? '' : \'s\'},
                                     style: TextStyle(
                                       fontWeight: FontWeight.w800,
                                       color: AppColors.accent1,
                                       fontSize: 12),
                                   ),
                                   const Spacer(),
                                   Text(
                                     '🔧 $inProg in progress  ⏳ $pending pending',
                                     style: TextStyle(
                                       color: AppColors.textSecondary,
                                       fontSize: 11),
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
                                 title: 'Total Services',
                                 value: '$total',
                                 svgAsset: AppSvgAssets.clipboardList,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.all),
                               ),
                               DashboardCard(
                                 title: 'Today Services',
                                 value: '$today',
                                 svgAsset: AppSvgAssets.calendarDays,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.today),
                               ),
                               DashboardCard(
                                 title: 'Pending',
                                 value: '$pending',
                                 svgAsset: AppSvgAssets.triangleAlert,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.pending),
                               ),
                               DashboardCard(
                                 title: 'In Progress',
                                 value: '$inProg',
                                 svgAsset: AppSvgAssets.refreshCw,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.inProgress),
                               ),
                               DashboardCard(
                                 title: 'Completed',
                                 value: '$completed',
                                 svgAsset: AppSvgAssets.circleCheckBig,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.completed),
                               ),
                               DashboardCard(
                                 title: 'Free Service',
                                 value: '$free',
                                 svgAsset: AppSvgAssets.handshake,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.free),
                               ),
                               DashboardCard(
                                 title: 'Paid Service',
                                 value: '$paid',
                                 svgAsset: AppSvgAssets.indianRupee,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.paid),
                               ),
                             ],
                           ),
                         ],
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
                                 color: AppColors.bgPrimary,
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(
                                   color: const Color(
                                     AppColors.accent1,
                                   ).withValues(alpha: 0.20),
                                 ),
                               ),
                              child: Row(
                                children: [
                                  const AppSvgIcon(
                                    AppSvgAssets.idCard,
                                    color: AppColors.accent1),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$total active service${total == 1 ? '' : 's'}',
                   style: TextStyle(
                     fontWeight: FontWeight.w800,
                     fontSize: 20,
                     color: AppColors.accent1,
                                  
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '🔧 $inProg in progress  ⏳ $pending pending',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                                   )
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
                                 title: 'Total Services',
                                 value: '$total',
                                 svgAsset: AppSvgAssets.clipboardList,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.all),
                               ),
                               DashboardCard(
                                 title: 'Today Services',
                                 value: '$today',
                                 svgAsset: AppSvgAssets.calendarDays,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.today),
                               ),
                               DashboardCard(
                                 title: 'Pending',
                                 value: '$pending',
                                 svgAsset: AppSvgAssets.triangleAlert,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.pending),
                               ),
                              DashboardCard(
                                title: 'In Progress',
                                value: '$inProg',
                                svgAsset: AppSvgAssets.refreshCw,
                                cardColor: AppColors.accent1,
                                onTap: () => _go(ServiceFilter.inProgress),
                              ),
                               DashboardCard(
                                 title: 'Completed',
                                 value: '$completed',
                                 svgAsset: AppSvgAssets.circleCheckBig,
                                 cardColor: AppColors.accent1,
                                 onTap: () => _go(ServiceFilter.completed),
                               ),
                                DashboardCard(
                                  title: 'Free Service',
                                  value: '$free',
                                  svgAsset: AppSvgAssets.handshake,
                                  cardColor: AppColors.accent1,
                                  onTap: () => _go(ServiceFilter.free),
                                );
                                DashboardCard(
                                  title: 'Paid Service',
                                  value: '$paid',
                                  svgAsset: AppSvgAssets.indianRupee,
                                  cardColor: AppColors.accent1,
                                  onTap: () => _go(ServiceFilter.paid),
                                ),
                            ],
                          ),
                        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLightest, width: 1),
      ),
      child: Row(
        children: [
          _StripStat(
            label: 'Total',
            value: '$total',
            color: AppColors.accent1,
          ),
          _StripDivider(),
          _StripStat(
            label: 'Free',
            value: '$free',
            color: const Color(0xFFFF416C),
          ),
          _StripDivider(),
          _StripStat(
            label: 'Paid',
            value: '$paid',
            color: AppColors.success,
          ),
          _StripDivider(),
          _StripStat(
            label: 'Done',
            value: '$completed',
            color: const Color(0xFF11998e),
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
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.accent1),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}






