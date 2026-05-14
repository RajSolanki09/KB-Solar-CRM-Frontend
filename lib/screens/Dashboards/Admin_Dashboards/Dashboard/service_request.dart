// lib/screens/Dashboards/Admin_Dashboards/Services/service_request_page.dart
// Admin view — list all service requests + add new  [PROFESSIONAL REDESIGN]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/data/Models/admin_user_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/service_detail_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGreen = AppColors.greenLight2;
const _kGreenLight = AppColors.bgLight1;
const _kBg = AppColors.veryLight7;
const _kSurface = AppColors.veryLight7;
const _kBorder = AppColors.bgLight2;
const _kText = AppColors.grayDark3;
const _kTextMuted = AppColors.textGray;
const _kTextHint = AppColors.grayLight;

// Status palette
const _kStatusOpen = AppColors.orange5;
const _kStatusAssigned = AppColors.blue;
const _kStatusInProgress = AppColors.amber;
const _kStatusCompleted = AppColors.success;
const _kStatusResolved = AppColors.purpleDark;

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({super.key});
  @override
  State<ServiceRequestPage> createState() => _State();
}

class _State extends State<ServiceRequestPage> with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _searchText = '';
  int _tabIndex = 0;
  final Map<int, int> _tabPages = {0: 1, 1: 1, 2: 1};

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceLeadCubit>().fetchAllServices();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _refresh() {
    if (!mounted) return;
    _fadeCtrl.reset();
    setState(() {
      _tabIndex = 0;
      _tabPages.updateAll((_, __) => 1);
    });
    context.read<ServiceLeadCubit>().fetchAllServices(
      search: _searchText.isNotEmpty ? _searchText : null,
      status: _filter != 'All' ? _filter : null,
      tabIndex: 0,
    );
    _fadeCtrl.forward();
  }

  void _onTabChanged(int i) {
    if (!mounted) return;
    _fadeCtrl.reset();
    setState(() => _tabIndex = i);
    context.read<ServiceLeadCubit>().setTabAndFetch(i);
    _fadeCtrl.forward();
  }

  void _onPageChanged(int page) {
    if (!mounted) return;
    setState(() => _tabPages[_tabIndex] = page);
    context.read<ServiceLeadCubit>().fetchPage(page, tabIndex: _tabIndex);
  }

  bool get _isAdmin {
    final s = context.read<AppStateCubit>().state;
    return s is Authenticated && s.role == UserRole.admin;
  }

  List<ServiceRequestModel> _filtered(List<ServiceRequestModel> all) {
    final now = DateTime.now();
    final recentCutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    return all.where((s) {
      if (s.isComplete) return false;
      final q = _searchText.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          s.customerName.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.serviceId.toLowerCase().contains(q) ||
          (s.assignedToName ?? '').toLowerCase().contains(q);
      final matchFilter =
          _filter == 'All' ||
          (_filter == 'Free' && s.chargeType == 'Free') ||
          (_filter == 'Paid' && s.chargeType == 'Paid') ||
          s.status == _filter;
      // Tab-wise date filter
      if (_tabIndex == 0) {
        // Recent: last 7 days
        if (s.createdAt.isBefore(recentCutoff)) return false;
      } else if (_tabIndex == 1) {
        // Older: before last 7 days
        if (!s.createdAt.isBefore(recentCutoff)) return false;
      }
      return matchSearch && matchFilter;
    }).toList();
  }

  List<ServiceRequestModel> _filterCompleted(List<ServiceRequestModel> all) {
    return all.where((s) {
      if (!s.isComplete) return false;
      final q = _searchText.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          s.customerName.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.serviceId.toLowerCase().contains(q) ||
          (s.assignedToName ?? '').toLowerCase().contains(q);
      final matchFilter =
          _filter == 'All' ||
          (_filter == 'Free' && s.chargeType == 'Free') ||
          (_filter == 'Paid' && s.chargeType == 'Paid') ||
          s.status == _filter;
      return matchSearch && matchFilter;
    }).toList();
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(ServiceRequestModel service) async {
    if (!_isAdmin) {
      AppFeedback.showInfo(context, 'Only admin can delete service requests.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => _DeleteDialog(service: service),
    );
    if (confirmed != true || !mounted) return;

    final doubleConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: const Text(
          'Are you absolutely sure?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.redDarker,
          ),
        ),
        content: Text(
          'You are about to permanently delete the service request for "${service.customerName}". All records will be gone forever.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.gray400,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text(
              'No, Keep It',
              style: TextStyle(
                color: AppColors.gray400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:   AppColors.redDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text(
              'Delete Forever',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (doubleConfirmed != true || !mounted) return;
    await context.read<ServiceLeadCubit>().deleteService(service.id);
    if (!mounted) return;
    final latestState = context.read<ServiceLeadCubit>().state;
    if (latestState is! ServiceLeadError) {
      AppFeedback.showSuccess(
        context,
        '${service.customerName}\'s request deleted.',
      );
    }
  }

  Future<void> _openDetail(
    BuildContext ctx,
    ServiceRequestModel service,
  ) async {
    final cubit = ctx.read<ServiceLeadCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ServiceDetailScreen(service: service, isAdmin: true),
        ),
      ),
    );
    cubit.fetchAllServices();
  }

  // ── Pagination bar ────────────────────────────────────────────────────────
  Widget _buildPaginationBar({
    required int currPage,
    required int totalPages,
    required int shownCount,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$shownCount results  ·  Page $currPage of $totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: _kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _PaginationBtn(
                icon: AppSvgAssets.chevronLeft,
                enabled: currPage > 1,
                onTap: () => _onPageChanged(currPage - 1),
              ),
              const SizedBox(width: 4),
              ...List.generate(totalPages, (i) {
                final p = i + 1;
                final isSel = p == currPage;
                if (totalPages > 5) {
                  if (p != 1 &&
                      p != totalPages &&
                      (p < currPage - 1 || p > currPage + 1)) {
                    if (p == currPage - 2 || p == currPage + 2) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '…',
                          style: TextStyle(fontSize: 12, color: _kTextMuted),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }
                return GestureDetector(
                  onTap: () => _onPageChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSel ? _kGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? _kGreen : _kBorder),
                    ),
                    child: Center(
                      child: Text(
                        '$p',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : _kText,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              _PaginationBtn(
                icon: AppSvgAssets.chevronRight,
                enabled: currPage < totalPages,
                onTap: () => _onPageChanged(currPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
      builder: (ctx, state) {
        int currPage = 1, totalPages = 0, shownCount = 0;
        bool hasPagination = false;
        if (state is ServiceLeadsLoaded) {
          final filtered = _tabIndex == 2
              ? _filterCompleted(state.services)
              : _filtered(state.services);
          currPage = state.page;
          totalPages = state.pages;
          shownCount = filtered.length;
          hasPagination = state.services.isNotEmpty && totalPages > 0;
        }

        return Scaffold(
          backgroundColor: _kBg,
          bottomNavigationBar: hasPagination
              ? _buildPaginationBar(
                  currPage: currPage,
                  totalPages: totalPages,
                  shownCount: shownCount,
                )
              : null,
          appBar: _buildAppBar(),
          body: BlocConsumer<ServiceLeadCubit, ServiceLeadState>(
            listener: (ctx, state) {
              if (state is ServiceLeadError) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              if (state is ServiceLeadSaved) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Service saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            builder: (ctx, state) {
              if (state is ServiceLeadLoading) {
                return const Center(child: _LoadingIndicator());
              }
              if (state is ServiceLeadError) {
                return _ErrorView(message: state.message, onRetry: _refresh);
              }
              if (state is ServiceLeadsLoaded) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildBody(ctx, state),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kGreen,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
      title: Row(
        children: [
          const AppSvgIcon(AppSvgAssets.cog, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Service Requests',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.refreshCw,
            color: Colors.white,
            size: 18,
          ),
          onPressed: _refresh,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext ctx, ServiceLeadsLoaded state) {
    final cubit = context.read<ServiceLeadCubit>();

    return Column(
      children: [
        // ── Top toolbar: search + new request ──────────────────────────────
        Container(
          color: _kSurface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchText = v),
                ),
              ),
              const SizedBox(width: 10),
              _NewRequestButton(onTap: () => _openAddServicePage(context)),
            ],
          ),
        ),

        // ── Filter chips ────────────────────────────────────────────────────
        Container(
          color: _kSurface,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children:
                  [
                    'All',
                    'Open',
                    'Assigned',
                    'In Progress',
                    'Completed',
                    'Free',
                    'Paid',
                  ].asMap().entries.map((e) {
                    final label = e.value;
                    final isSel = _filter == label;
                    return Padding(
                      padding: EdgeInsets.only(right: e.key == 6 ? 0 : 8),
                      child: _FilterChip(
                        label: label,
                        selected: isSel,
                        onTap: () => setState(() => _filter = label),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),

        // ── Divider ─────────────────────────────────────────────────────────
        Container(height: 1, color: _kBorder),

        // ── Tabs ─────────────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final services = state.services;
              final filtered = _tabIndex == 2
                  ? _filterCompleted(services)
                  : _filtered(services);
              final sorted = [...filtered]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final minW = constraints.maxWidth < 900
                  ? 980.0
                  : constraints.maxWidth;

              final tabData = [
                (
                  label: 'Recent',
                  count: cubit.getTabTotal(0),
                  leads: _tabIndex == 0 ? sorted : <ServiceRequestModel>[],
                  emptyMsg: 'No requests in the last 7 days.',
                  color: _kGreen,
                ),
                (
                  label: 'Older',
                  count: cubit.getTabTotal(1),
                  leads: _tabIndex == 1 ? sorted : <ServiceRequestModel>[],
                  emptyMsg: 'No older requests found.',
                  color: _kStatusInProgress,
                ),
                (
                  label: 'Completed',
                  count: cubit.getTabTotal(2),
                  leads: _tabIndex == 2 ? sorted : <ServiceRequestModel>[],
                  emptyMsg: 'No completed requests yet.',
                  color: _kStatusCompleted,
                ),
              ];

              final currentLeads = tabData[_tabIndex].leads;
              final currentEmpty = tabData[_tabIndex].emptyMsg;

              return Column(
                children: [
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: List.generate(tabData.length, (i) {
                          final tab = tabData[i];
                          final isSel = _tabIndex == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabChanged(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? _kGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tab.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSel
                                            ? Colors.white
                                            : _kTextMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? Colors.white.withValues(
                                                alpha: 0.25,
                                              )
                                            : _kBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${tab.count}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSel
                                              ? Colors.white
                                              : _kTextMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Table / empty
                  Expanded(
                    child: RefreshIndicator(
                      color: _kGreen,
                      onRefresh: () async => _refresh(),
                      child: currentLeads.isEmpty
                          ? _EmptyView(
                              message: currentEmpty,
                              onRefresh: _refresh,
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              children: [
                                _ServiceDataTable(
                                  services: currentLeads,
                                  isAdmin: _isAdmin,
                                  minWidth: minW,
                                  onTap: (s) => _openDetail(ctx, s),
                                  onDelete: _confirmDelete,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Add service full page ─────────────────────────────────────────────────
  Future<void> _openAddServicePage(BuildContext ctx) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: ctx.read<ServiceLeadCubit>(),
          child: Scaffold(
            backgroundColor: _kBg,
            appBar: AppBar(
              backgroundColor: _kGreen,
              elevation: 0,
              leading: IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'New Service Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const SafeArea(child: _AddServiceSheet()),
          ),
        ),
      ),
    );
    if (mounted) _refresh();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small reusable UI components
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: _kBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBorder),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: const InputDecoration(
        hintText: 'Search name, phone, ID or technician…',
        hintStyle: TextStyle(fontSize: 13, color: _kTextHint),
        prefixIcon: Padding(
          padding: EdgeInsets.all(12),
          child: AppSvgIcon(AppSvgAssets.search, size: 16, color: _kTextMuted),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

class _NewRequestButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewRequestButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kGreen,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            'New Request',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? _kGreen : _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? _kGreen : _kBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _kTextMuted,
        ),
      ),
    ),
  );
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();
  @override
  Widget build(BuildContext context) => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5),
      ),
      SizedBox(height: 12),
      Text(
        'Loading…',
        style: TextStyle(
          fontSize: 13,
          color: _kTextMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color:   AppColors.lightPurple1,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: AppSvgIcon(
              AppSvgAssets.triangleAlert,
              size: 28,
              color: AppColors.error,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: _kTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _kGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  AppSvgAssets.refreshCw,
                  size: 14,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;
  const _EmptyView({required this.message, required this.onRefresh});
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: 280,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kGreenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: AppSvgIcon(AppSvgAssets.cog, size: 28, color: _kGreen),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pull down to refresh the list',
              style: TextStyle(fontSize: 12, color: _kTextMuted),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Delete dialog
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final ServiceRequestModel service;
  const _DeleteDialog({required this.service});
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:   AppColors.lightPurple1,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const AppSvgIcon(
            AppSvgAssets.trash2,
            size: 20,
            color: AppColors.redDarker,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Delete Request?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.customerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                service.phone,
                style: const TextStyle(fontSize: 12, color: _kTextMuted),
              ),
              Text(
                service.serviceId,
                style: const TextStyle(fontSize: 12, color: _kTextMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:   AppColors.lightBg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color:   AppColors.bgLight4),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSvgIcon(
                AppSvgAssets.triangleAlert,
                size: 15,
                color: AppColors.orange600,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will permanently remove ALL data. This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orange800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:   AppColors.redDarker,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => Navigator.pop(context, true),
        child: const Text(
          'Yes, Delete',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data Table
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceDataTable extends StatelessWidget {
  final List<ServiceRequestModel> services;
  final bool isAdmin;
  final double minWidth;
  final ValueChanged<ServiceRequestModel> onTap;
  final ValueChanged<ServiceRequestModel> onDelete;
  const _ServiceDataTable({
    required this.services,
    required this.isAdmin,
    required this.minWidth,
    required this.onTap,
    required this.onDelete,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Open':
        return _kStatusOpen;
      case 'Assigned':
        return _kStatusAssigned;
      case 'In Progress':
        return _kStatusInProgress;
      case 'Completed':
        return _kStatusCompleted;
      case 'Resolved':
        return _kStatusResolved;
      default:
        return _kTextMuted;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _chargeBadge(ServiceRequestModel s) {
    final isPaid = s.chargeType == 'Paid';
    final color = isPaid ? _kStatusInProgress : _kGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isPaid && s.amount > 0
            ? '₹${s.amount.toStringAsFixed(0)}'
            : s.chargeType,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${DateFormat('dd MMM yyyy').format(dt)}\n${DateFormat('hh:mm a').format(dt)}';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const rowStyle = TextStyle(fontSize: 12, color: _kText);

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 42,
              dataRowMinHeight: 58,
              dataRowMaxHeight: 72,
              horizontalMargin: isDesktop ? 16 : 12,
              columnSpacing: isDesktop ? 20 : 12,
              dividerThickness: 1,
              headingRowColor: WidgetStateProperty.all(  AppColors.gray100),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered))
                  return   AppColors.bgLight3;
                return _kSurface;
              }),
              border: TableBorder(
                horizontalInside: BorderSide(color: _kBorder, width: 0.8),
              ),
              columns: [
                _col('Customer'),
                _col('Phone'),
                _col('Issue'),
                _col('Technician'),
                _col('Status'),
                _col('Charge'),
                _col('Service Date & Time'),
                if (isAdmin) _col(''),
              ],
              rows: services
                  .map(
                    (s) => DataRow(
                      onSelectChanged: (_) => onTap(s),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _kGreenLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    s.customerName.isNotEmpty
                                        ? s.customerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.customerName,
                                style: rowStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            s.phone,
                            style: rowStyle.copyWith(color: _kTextMuted),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: isDesktop ? 180 : 140,
                            child: Text(
                              s.issueType?.isNotEmpty == true
                                  ? s.issueType!
                                  : '—',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: rowStyle,
                            ),
                          ),
                        ),
                        DataCell(
                          s.assignedToName != null
                              ? Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color:   AppColors.lightBg5,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          s.assignedToName![0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.indigo600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(s.assignedToName!, style: rowStyle),
                                  ],
                                )
                              : Text(
                                  '—',
                                  style: rowStyle.copyWith(color: _kTextHint),
                                ),
                        ),
                        DataCell(_statusBadge(s.status)),
                        DataCell(_chargeBadge(s)),
                        DataCell(
                          s.serviceDate != null
                              ? Text(
                                  _formatDate(s.serviceDate!),
                                  style: rowStyle.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kGreen,
                                    height: 1.5,
                                  ),
                                )
                              : Text(
                                  '—',
                                  style: rowStyle.copyWith(color: _kTextHint),
                                ),
                        ),
                        if (isAdmin)
                          DataCell(
                            GestureDetector(
                              onTap: () => onDelete(s),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color:   AppColors.lightPurple1,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Center(
                                  child: AppSvgIcon(
                                    AppSvgAssets.trash2,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

DataColumn _col(String title) => DataColumn(
  label: Text(
    title,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _kTextMuted,
      letterSpacing: 0.5,
    ),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
//  Pagination button
// ─────────────────────────────────────────────────────────────────────────────
class _PaginationBtn extends StatelessWidget {
  final String icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PaginationBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled ? _kSurface : _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: AppSvgIcon(icon, size: 13, color: enabled ? _kText : _kTextHint),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add Service Sheet  (unchanged logic, refreshed visuals)
// ─────────────────────────────────────────────────────────────────────────────
class _AddServiceSheet extends StatefulWidget {
  const _AddServiceSheet();
  @override
  State<_AddServiceSheet> createState() => _AddState();
}

class _AddState extends State<_AddServiceSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _issue = TextEditingController();
  final _desc = TextEditingController();
  final _note = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _serviceDate;
  TimeOfDay? _serviceTime;
  String _chargeType = 'Free';
  String? _techId;
  List<UserModel> _techList = [];
  bool _loadingTech = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _issue.dispose();
    _desc.dispose();
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicians() async {
    try {
      final data = await ApiService().getStaff(role: 'service');
      final all = data.map((e) => UserModel.fromJson(e)).toList();
      setState(() {
        _techList = all;
        _loadingTech = false;
      });
    } catch (_) {
      setState(() => _loadingTech = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_techId == null) {
      AppFeedback.showInfo(context, 'Please assign a technician');
      return;
    }
    if (_serviceDate == null) {
      AppFeedback.showInfo(context, 'Please select service date');
      return;
    }
    if (_serviceTime == null) {
      AppFeedback.showInfo(context, 'Please select service time');
      return;
    }
    final scheduledAt = DateTime(
      _serviceDate!.year,
      _serviceDate!.month,
      _serviceDate!.day,
      _serviceTime!.hour,
      _serviceTime!.minute,
    );
    setState(() => _saving = true);
    try {
      await context.read<ServiceLeadCubit>().createService({
        'customerName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'issueType': _issue.text.trim(),
        'issueDescription': _desc.text.trim(),
        if (_note.text.trim().isNotEmpty) 'serviceNotes': _note.text.trim(),
        'chargeType': _chargeType,
        'chargeAmount': _chargeType == 'Paid'
            ? double.tryParse(_amount.text) ?? 0
            : 0,
        'assignedTo': _techId,
        'serviceDate': scheduledAt.toIso8601String(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _serviceDate = picked);
  }

  Future<void> _pickServiceTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _serviceTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _serviceTime = picked);
  }

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Customer Details'),
              const SizedBox(height: 10),
              _field(
                _name,
                'Full Name',
                AppSvgAssets.userRound,
                required: true,
              ),
              const SizedBox(height: 10),
              _field(
                _phone,
                'Phone Number',
                AppSvgAssets.phone,
                keyboardType: TextInputType.phone,
                required: true,
              ),
              const SizedBox(height: 10),
              _field(_address, 'Address', AppSvgAssets.mapPin, required: true),
              const SizedBox(height: 16),
              _sectionLabel('Issue Details'),
              const SizedBox(height: 10),
              _field(_issue, 'Issue Type', AppSvgAssets.triangleAlert),
              const SizedBox(height: 10),
              _field(_desc, 'Description', AppSvgAssets.fileText, maxLines: 2),
              const SizedBox(height: 16),
              _sectionLabel('Schedule'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateTimePicker(
                      label: _serviceDate != null
                          ? _fmtDate(_serviceDate!)
                          : 'Select date *',
                      icon: AppSvgAssets.calendarDays,
                      active: _serviceDate != null,
                      onTap: _pickServiceDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateTimePicker(
                      label: _serviceTime != null
                          ? _fmtTime(_serviceTime!)
                          : 'Select time *',
                      icon: AppSvgAssets.clock,
                      active: _serviceTime != null,
                      onTap: _pickServiceTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionLabel('Charge Type'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ChargeChip(
                    label: 'Free',
                    selected: _chargeType == 'Free',
                    color: _kGreen,
                    onTap: () => setState(() => _chargeType = 'Free'),
                  ),
                  const SizedBox(width: 8),
                  _ChargeChip(
                    label: 'Paid',
                    selected: _chargeType == 'Paid',
                    color: _kStatusInProgress,
                    onTap: () => setState(() => _chargeType = 'Paid'),
                  ),
                ],
              ),
              if (_chargeType == 'Paid') ...[
                const SizedBox(height: 10),
                _field(
                  _amount,
                  'Amount (₹)',
                  AppSvgAssets.indianRupee,
                  keyboardType: TextInputType.number,
                  required: true,
                ),
              ],
              const SizedBox(height: 16),
              _sectionLabel('Assign Technician'),
              const SizedBox(height: 10),
              _loadingTech
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: _kGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _techList.isEmpty
                  ? const Text(
                      'No service technicians found.',
                      style: TextStyle(color: _kTextMuted, fontSize: 13),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _techId,
                          isExpanded: true,
                          hint: const Text(
                            'Select technician',
                            style: TextStyle(fontSize: 13, color: _kTextHint),
                          ),
                          items: _techList
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text(
                                    u.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _techId = v);
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 10),
              _field(
                _note,
                'Notes (optional)',
                AppSvgAssets.fileText,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Service Request',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _kTextMuted,
      letterSpacing: 0.8,
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    String svgAsset, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    final isPhone = keyboardType == TextInputType.phone;
    return TextFormField(
      controller: ctrl,
      keyboardType: isPhone
          ? const TextInputType.numberWithOptions(decimal: false, signed: false)
          : keyboardType,
      maxLines: maxLines,
      maxLength: isPhone ? 10 : null,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kTextMuted),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: AppSvgIcon(svgAsset, size: 16, color: _kGreen),
        ),
        counterStyle: isPhone
            ? const TextStyle(fontSize: 11, color: _kTextHint)
            : const TextStyle(fontSize: 0, height: 0),
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return '$label is required';
              if (isPhone) {
                if (v.trim().length != 10) return 'Must be exactly 10 digits';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim()))
                  return 'Enter a valid mobile number';
              }
              return null;
            }
          : null,
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;
  const _DateTimePicker({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: active ? _kGreenLight : _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? _kGreen : _kBorder,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          AppSvgIcon(icon, size: 15, color: active ? _kGreen : _kTextMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? _kText : _kTextHint,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChargeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ChargeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : _kBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? color : _kTextMuted,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// All unused classes and widgets have been removed.
// ─────────────────────────────────────────────────────────────────────────────













