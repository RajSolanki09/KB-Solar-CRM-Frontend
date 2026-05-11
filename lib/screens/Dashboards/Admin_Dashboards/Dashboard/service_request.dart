// lib/screens/Dashboards/Admin_Dashboards/Services/service_request_page.dart
// Admin view — list all service requests + add new

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/data/Models/admin_user_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/service_detail_screen.dart';
import 'package:solar_project/core/app_colors.dart';

// ── Brand colour for service ──────────────────────────────────────────────────
const _kGreen = AppColors.success;

class ServiceRequestPage extends StatefulWidget {
  final Color appBarColor;
  const ServiceRequestPage({super.key, this.appBarColor = _kGreen});
  @override
  State<ServiceRequestPage> createState() => _State();
}

class _State extends State<ServiceRequestPage> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _searchText = '';
  bool _showOlderServices = false;
  bool _showCompletedServices = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ServiceLeadCubit>().fetchAllServices();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _refresh() {
    if (mounted) context.read<ServiceLeadCubit>().fetchAllServices();
  }

  bool get _isAdmin {
    final authState = context.read<AppStateCubit>().state;
    return authState is Authenticated && authState.role == UserRole.admin;
  }

  DateTime get _recentCutoff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 6)); // last 7 days inclusive
  }

  // ── Filter for active services only (excludes completed) ──────────────────
  List<ServiceRequestModel> _filtered(List<ServiceRequestModel> all) {
    return all.where((s) {
      if (s.isComplete) return false; // Only active services

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

  // ── Filter for completed services only ───────────────────────────────────
  List<ServiceRequestModel> _filterCompleted(List<ServiceRequestModel> all) {
    return all.where((s) {
      if (!s.isComplete) return false; // Only completed services

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

  // ── Delete confirmation (admin only, any step) ────────────────────────────
  Future<void> _confirmDelete(ServiceRequestModel service) async {
    if (!_isAdmin) {
      AppFeedback.showInfo(context, 'Only admin can delete service requests.');
      return;
    }

    // ── Step 1: warning dialog ────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppSvgIcon(
                AppSvgAssets.trash2,
                size: 20,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Service Request?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  Text(
                    service.serviceId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSvgIcon(
                    AppSvgAssets.triangleAlert,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently remove ALL data including '
                      'service details, assignments, and records. '
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9A3412),
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Delete Permanently',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // ── Step 2: second confirmation ───────────────────────────────────────
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: const Text(
          'Are you absolutely sure?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'You are about to permanently delete the service request for '
          '"${service.customerName}". All records will be gone forever.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'No, Keep It',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7F1D1D),
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete Forever',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true || !mounted) return;

    // deleteService() internally calls fetchAllServices() on success
    // and emits ServiceLeadError on failure — the BlocConsumer listener
    // already shows the error snackbar, so we only need to handle success.
    await context.read<ServiceLeadCubit>().deleteService(service.id);

    if (!mounted) return;
    final latestState = context.read<ServiceLeadCubit>().state;
    if (latestState is! ServiceLeadError) {
      AppFeedback.showSuccess(
        context,
        '${service.customerName}\'s service request permanently deleted.',
      );
    }
  }

  // ── Open detail ───────────────────────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: AppColors.surface,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Row(
          children: [
            AppSvgIcon(AppSvgAssets.cog, color: AppColors.surface, size: 18),
            SizedBox(width: 8),
            Text(
              'Service Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.refreshCw,
              color: AppColors.surface,
            ),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddServicePage(context),
        backgroundColor: _kGreen,
        icon: const AppSvgIcon(AppSvgAssets.plus, color: AppColors.surface),
        label: const Text(
          'New Request',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<ServiceLeadCubit, ServiceLeadState>(
        listener: (ctx, state) {
          if (state is ServiceLeadError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state is ServiceLeadSaved) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Service saved successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is ServiceLeadLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _kGreen),
            );
          }

          if (state is ServiceLeadError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(
                    AppSvgAssets.triangleAlert,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const AppSvgIcon(AppSvgAssets.refreshCw, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: AppColors.surface,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ServiceLeadsLoaded) {
            final all = state.services;
            final filtered = _filtered(all);
            final open = all.where((s) => !s.isComplete).length;
            final done = all.where((s) => s.isComplete).length;

            return Column(
              children: [
                // ── Summary bar ──────────────────────────────────────────
                if (all.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat('Total', '${all.length}', _kGreen),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.divider,
                        ),
                        _Stat('Open', '$open', AppColors.solar),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.divider,
                        ),
                        _Stat('Done', '$done', AppColors.primary),
                      ],
                    ),
                  ),

                // ── Search + filter row ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchText = v),
                            decoration: const InputDecoration(
                              hintText: 'Search name / phone / ID / tech',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: AppSvgIcon(
                                  AppSvgAssets.search,
                                  size: 16,
                                  color: _kGreen,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _filter == 'All'
                                  ? AppColors.divider
                                  : _kGreen.withValues(alpha: 0.5),
                              width: _filter == 'All' ? 1 : 1.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filter,
                              isExpanded: true,
                              isDense: true,
                              icon: const AppSvgIcon(
                                AppSvgAssets.chevronDown,
                                size: 16,
                                color: _kGreen,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: _filter == 'All'
                                    ? AppColors.textGray
                                    : _kGreen,
                                fontWeight: _filter == 'All'
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                              items:
                                  [
                                        'All',
                                        'Open',
                                        'Assigned',
                                        'In Progress',
                                        'Completed',
                                        'Free',
                                        'Paid',
                                      ]
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _filter = v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Result count ─────────────────────────────────────────
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} request${filtered.length != 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),

                // ── Table sections / empty state ─────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppSvgIcon(
                                AppSvgAssets.cog,
                                size: 52,
                                color: AppColors.divider,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                all.isEmpty
                                    ? 'No service requests yet'
                                    : 'No requests match filter',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: _kGreen,
                          onRefresh: () async => _refresh(),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final sorted = [...filtered]
                                ..sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt),
                                );
                              final recent = sorted
                                  .where(
                                    (s) => !s.createdAt.isBefore(_recentCutoff),
                                  )
                                  .toList();
                              final older = sorted
                                  .where(
                                    (s) => s.createdAt.isBefore(_recentCutoff),
                                  )
                                  .toList();
                              final minW = constraints.maxWidth < 900
                                  ? 980.0
                                  : constraints.maxWidth;

                              // Filter completed services
                              final completed = _filterCompleted(all);
                              final sortedCompleted = [...completed]
                                ..sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt),
                                );

                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  120,
                                ),
                                children: [
                                  _TableSection(
                                    title: 'Last 7 Days',
                                    subtitle:
                                        'Service requests created in the last seven days',
                                    services: recent,
                                    isAdmin: _isAdmin,
                                    minWidth: minW,
                                    onTap: (s) => _openDetail(ctx, s),
                                    onDelete: _confirmDelete,
                                    showEmptyMessage: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _CollapsibleTableSection(
                                    title: 'Older Requests',
                                    subtitle:
                                        'Older records are collapsed by default',
                                    services: older,
                                    isAdmin: _isAdmin,
                                    minWidth: minW,
                                    initiallyExpanded: _showOlderServices,
                                    onExpansionChanged: (v) {
                                      if (mounted)
                                        setState(() => _showOlderServices = v);
                                    },
                                    onTap: (s) => _openDetail(ctx, s),
                                    onDelete: _confirmDelete,
                                  ),
                                  // ────────────────────────────────────
                                  // COMPLETED REQUESTS - SINGLE TABLE
                                  // ────────────────────────────────────
                                  if (sortedCompleted.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _CollapsibleTableSection(
                                      title: 'Completed Requests',
                                      subtitle:
                                          'All completed service requests listed by newest first',
                                      services: sortedCompleted,
                                      isAdmin: _isAdmin,
                                      minWidth: minW,
                                      initiallyExpanded: _showCompletedServices,
                                      onExpansionChanged: (v) {
                                        if (mounted)
                                          setState(
                                            () => _showCompletedServices = v,
                                          );
                                      },
                                      onTap: (s) => _openDetail(ctx, s),
                                      onDelete: _confirmDelete,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Open Add Service as Full Page ──────────────────────────────────────────
  Future<void> _openAddServicePage(BuildContext ctx) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: ctx.read<ServiceLeadCubit>(),
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: _kGreen,
              elevation: 0,
              leading: IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: AppColors.surface,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'New Service Request',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.surface),
            ),
            body: const SafeArea(child: _AddServiceSheet()),
          ),
        ),
      ),
    );
    if (mounted) _refresh();
  }
}

// ─────────────────────────────────────────────────────────────
//  Table Section (always expanded — last 7 days)
// ─────────────────────────────────────────────────────────────
class _TableSection extends StatelessWidget {
  final String title, subtitle;
  final List<ServiceRequestModel> services;
  final bool isAdmin, showEmptyMessage;
  final double minWidth;
  final ValueChanged<ServiceRequestModel> onTap;
  final ValueChanged<ServiceRequestModel> onDelete;

  const _TableSection({
    required this.title,
    required this.subtitle,
    required this.services,
    required this.isAdmin,
    required this.minWidth,
    required this.onTap,
    required this.onDelete,
    this.showEmptyMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
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
                  '$title (${services.length})',
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
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (services.isEmpty && showEmptyMessage)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No requests in the last 7 days.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            )
          else if (services.isNotEmpty)
            _ServiceDataTable(
              services: services,
              isAdmin: isAdmin,
              minWidth: minWidth,
              onTap: onTap,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Collapsible Table Section (older requests)
// ─────────────────────────────────────────────────────────────
class _CollapsibleTableSection extends StatelessWidget {
  final String title, subtitle;
  final List<ServiceRequestModel> services;
  final bool isAdmin, initiallyExpanded;
  final double minWidth;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<ServiceRequestModel> onTap;
  final ValueChanged<ServiceRequestModel> onDelete;

  const _CollapsibleTableSection({
    required this.title,
    required this.subtitle,
    required this.services,
    required this.isAdmin,
    required this.minWidth,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('service_older'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(
            '$title (${services.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          children: [
            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No older requests found.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              )
            else
              _ServiceDataTable(
                services: services,
                isAdmin: isAdmin,
                minWidth: minWidth,
                onTap: onTap,
                onDelete: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Service Data Table
// ─────────────────────────────────────────────────────────────
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
        return Colors.grey;
      case 'Assigned':
        return AppColors.primary;
      case 'In Progress':
        return AppColors.solar;
      case 'Completed':
        return AppColors.success;
      case 'Resolved':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _chargeBadge(ServiceRequestModel s) {
    final isPaid = s.chargeType == 'Paid';
    final color = isPaid ? AppColors.solar : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isPaid && s.amount > 0
            ? '₹${s.amount.toStringAsFixed(0)}'
            : s.chargeType,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${DateFormat('dd MMM yyyy').format(dt)}\n'
      '${DateFormat('hh:mm a').format(dt)}';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const rowStyle = TextStyle(fontSize: 12, color: AppColors.textDark);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 44,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 70,
            horizontalMargin: isDesktop ? 18 : 12,
            columnSpacing: isDesktop ? 24 : 14,
            headingRowColor: WidgetStateProperty.all(
              _kGreen.withValues(alpha: 0.08),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _kGreen.withValues(alpha: 0.05);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.primary),
              bottom: BorderSide(color: AppColors.primary),
              top: BorderSide(color: AppColors.primary),
            ),
            columns: [
              _buildColumn('Customer'),
              _buildColumn('Phone'),
              _buildColumn('Issue'),
              _buildColumn('Technician'),
              _buildColumn('Status'),
              _buildColumn('Charge'),
              _buildColumn('Service Date & Time'),
              if (isAdmin) _buildColumn('Actions'),
            ],
            rows: services.map((s) {
              // Admin can delete services at any step
              final canDelete = isAdmin;

              return DataRow(
                onSelectChanged: (_) => onTap(s),
                cells: [
                  // Customer
                  DataCell(
                    Text(
                      s.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Phone
                  DataCell(Text(s.phone, style: rowStyle)),
                  // Issue
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 180 : 140,
                      child: Text(
                        s.issueType?.isNotEmpty == true ? s.issueType! : '-',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: rowStyle,
                      ),
                    ),
                  ),
                  // Technician
                  DataCell(Text(s.assignedToName ?? '-', style: rowStyle)),
                  // Status badge
                  DataCell(_statusBadge(s.status)),
                  // Charge badge
                  DataCell(_chargeBadge(s)),
                  // Service date and time
                  DataCell(
                    s.serviceDate != null
                        ? Text(
                            _formatDate(s.serviceDate!),
                            style: rowStyle.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kGreen,
                            ),
                          )
                        : Text(
                            '-',
                            style: rowStyle.copyWith(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                  ),
                  // Actions (admin only)
                  if (isAdmin)
                    DataCell(
                      Tooltip(
                        message: canDelete ? 'Delete Request' : 'No permission',
                        child: IconButton(
                          onPressed: canDelete ? () => onDelete(s) : null,
                          icon: AppSvgIcon(
                            AppSvgAssets.trash2,
                            size: 18,
                            color: canDelete
                                ? AppColors.error
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

DataColumn _buildColumn(String title) => DataColumn(
  label: Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: AppColors.success,
    ),
  ),
);

// ─────────────────────────────────────────────────────────────
//  Add Service Bottom Sheet (unchanged)
// ─────────────────────────────────────────────────────────────
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
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Service Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _field(
                _name,
                'Customer Name',
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
              const SizedBox(height: 10),
              _field(_issue, 'Issue Type', AppSvgAssets.triangleAlert),
              const SizedBox(height: 10),
              _field(
                _desc,
                'Issue Description',
                AppSvgAssets.fileText,
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              const Text(
                'Service Date & Time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickServiceDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _serviceDate != null
                              ? _kGreen.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _serviceDate != null
                                ? _kGreen
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.calendarDays,
                              size: 16,
                              color: _serviceDate != null
                                  ? _kGreen
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serviceDate != null
                                    ? _fmtDate(_serviceDate!)
                                    : 'Select date *',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _serviceDate != null
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                  fontWeight: _serviceDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickServiceTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _serviceTime != null
                              ? _kGreen.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _serviceTime != null
                                ? _kGreen
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.clock,
                              size: 16,
                              color: _serviceTime != null
                                  ? _kGreen
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serviceTime != null
                                    ? _fmtTime(_serviceTime!)
                                    : 'Select time *',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _serviceTime != null
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                  fontWeight: _serviceTime != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Charge type
              Row(
                children: [
                  const Text(
                    'Charge Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _chip(
                    'Free',
                    _chargeType == 'Free',
                    AppColors.success,
                    () => setState(() => _chargeType = 'Free'),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    'Paid',
                    _chargeType == 'Paid',
                    AppColors.solar,
                    () => setState(() => _chargeType = 'Paid'),
                  ),
                ],
              ),

              if (_chargeType == 'Paid') ...[
                const SizedBox(height: 10),
                _field(
                  _amount,
                  'Charge Amount (₹)',
                  AppSvgAssets.indianRupee,
                  keyboardType: TextInputType.number,
                  required: true,
                ),
              ],

              const SizedBox(height: 10),
              const Text(
                'Assign Technician',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              _loadingTech
                  ? const Center(child: CircularProgressIndicator())
                  : _techList.isEmpty
                  ? const Text(
                      'No service technicians found',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _techId,
                          isExpanded: true,
                          hint: const Text(
                            'Select technician',
                            style: TextStyle(fontSize: 13),
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
              _field(_note, 'Notes', AppSvgAssets.fileText, maxLines: 3),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: AppColors.surface,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Create Service Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
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
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppSvgIcon(svgAsset, size: 16, color: _kGreen),
        ),
        counterStyle: isPhone
            ? const TextStyle(fontSize: 11, color: AppColors.textLight)
            : const TextStyle(fontSize: 0, height: 0),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kGreen),
        ),
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return '$label is required';
              if (isPhone) {
                final p = v.trim();
                if (p.length != 10)
                  return 'Phone number must be exactly 10 digits';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(p))
                  return 'Enter a valid mobile number (must start with 6-9)';
              }
              return null;
            }
          : null,
    );
  }

  Widget _chip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.divider,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : AppColors.textGray,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stat Widget
// ─────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textLight),
      ),
    ],
  );
}
