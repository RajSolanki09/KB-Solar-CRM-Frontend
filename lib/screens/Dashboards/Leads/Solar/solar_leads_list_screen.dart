// lib/screens/Dashboards/Leads/Solar/solar_leads_list_screen.dart

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/date_time_helper.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/add_solar_lead_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/solar_lead_detail_screen.dart';
import 'package:solar_project/core/app_colors.dart';

class SolarLeadsListScreen extends StatefulWidget {
  final Color appBarColor;
  final bool embedded; // If true, shows a smaller header suitable for embedding
  const SolarLeadsListScreen({
    super.key,
    this.appBarColor = LeadTheme.primary,
    this.embedded = false,
  });

  @override
  State<SolarLeadsListScreen> createState() => _State();
}

class _State extends State<SolarLeadsListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'All';
  DateTime? _selectedDate;
  bool _showOlderLeads = false;
  bool _showCompletedLeads = false;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolarLeadCubit>().fetchAllLeads();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Refresh helper — always uses the widget's own context ─────────────────
  void _refresh() {
    if (mounted) context.read<SolarLeadCubit>().fetchAllLeads();
  }

  // ── Filter for active leads only (respect status filter) ──────────────────
  List<SolarLeadsModel> _filterActive(List<SolarLeadsModel> all) {
    return all.where((l) {
      if (l.isCompleted) return false; // Only active leads

      final s = _search.toLowerCase();
      final matchSearch =
          s.isEmpty ||
          l.customerName.toLowerCase().contains(s) ||
          l.mobile.contains(s) ||
          l.address.toLowerCase().contains(s) ||
          (l.createdBy ?? '').toLowerCase().contains(s);

      // Only show if filter is 'All' or 'Active' or specific status
      final matchStatus =
          _filter == 'All' || _filter == 'Active' || l.status == _filter;

      bool matchDate = true;
      if (_selectedDate != null) {
        final created = l.createdAt;
        matchDate =
            created.year == _selectedDate!.year &&
            created.month == _selectedDate!.month &&
            created.day == _selectedDate!.day;
      }

      return matchSearch && matchStatus && matchDate;
    }).toList();
  }

  // ── Filter for completed leads only ────────────────────────────────────────
  List<SolarLeadsModel> _filterCompleted(List<SolarLeadsModel> all) {
    return all.where((l) {
      if (!l.isCompleted) return false; // Only completed leads

      // Hide if filter is specifically 'Active'
      if (_filter == 'Active') return false;

      final s = _search.toLowerCase();
      final matchSearch =
          s.isEmpty ||
          l.customerName.toLowerCase().contains(s) ||
          l.mobile.contains(s) ||
          l.address.toLowerCase().contains(s) ||
          (l.createdBy ?? '').toLowerCase().contains(s);

      // Show if filter is 'All' or 'Completed' or specific status
      final matchStatus =
          _filter == 'All' || _filter == 'Completed' || l.status == _filter;

      bool matchDate = true;
      if (_selectedDate != null) {
        final created = l.createdAt;
        matchDate =
            created.year == _selectedDate!.year &&
            created.month == _selectedDate!.month &&
            created.day == _selectedDate!.day;
      }

      return matchSearch && matchStatus && matchDate;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await DateTimeHelper.pickPastDate(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _clearDateFilter() {
    if (mounted) setState(() => _selectedDate = null);
  }

  String _dateLabel() {
    return DateTimeHelper.leadDateFilterLabel(_selectedDate);
  }

  DateTime get _recentCutoff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 6));
  }

  bool get _isAdmin {
    final authState = context.read<AppStateCubit>().state;
    return authState is Authenticated && authState.role == UserRole.admin;
  }

  String? get _loggedInUserName {
    final authState = context.read<AppStateCubit>().state;
    if (authState is Authenticated) {
      final name = authState.userName.trim();
      if (name.isNotEmpty) return name;
    }
    return null;
  }

  Future<void> _confirmDeleteLead(SolarLeadsModel lead) async {
    if (!_isAdmin) {
      if (!mounted) return;
      AppFeedback.showInfo(context, 'Only admin can delete leads.');
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
                color:  AppColors.errorLight,
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
              'Delete Lead?',
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
                    lead.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.mobile,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  Text(
                    lead.address,
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
                      'site visit, quotation, installation, payment records '
                      'and photos. This action cannot be undone.',
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
              backgroundColor:  AppColors.error,
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
          'You are about to permanently delete the lead for '
          '"${lead.customerName}". All records will be gone forever.',
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

    final cubit = context.read<SolarLeadCubit>();
    await cubit.deleteLead(lead.id);

    if (!mounted) return;
    final latestState = cubit.state;
    if (latestState is SolarLeadError) {
      AppFeedback.showInfo(context, latestState.message);
      return;
    }

    await cubit.fetchAllLeads();

    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      '${lead.customerName}\'s lead permanently deleted.',
      svgAsset: AppSvgAssets.trash2,
    );
  }

  // ── Navigate to detail then auto-refresh on return ────────────────────────

  Future<void> _openDetail(SolarLeadsModel lead) async {
    // Capture cubit BEFORE pushing so we hold a stable reference
    final cubit = context.read<SolarLeadCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: SolarLeadDetailScreen(lead: lead),
        ),
      ),
    );

    // Auto-refresh when returning — reset filters and refresh data
    if (mounted) {
      setState(() {
        _filter = 'All'; // Reset status filter
        _selectedDate = null; // Reset date filter
        _search = ''; // Reset search
        _searchCtrl.clear();
        _showOlderLeads = false;
      });
      // Wait a frame to ensure setState completes, then fetch fresh data
      await Future.delayed(const Duration(milliseconds: 100));
      cubit.fetchAllLeads();
    }
  }

  Future<void> _openAddLead() async {
    final cubit = context.read<SolarLeadCubit>();

    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const AddSolarLeadScreen()),
      ),
    );

    if (!mounted) return;
    if (added == true) {
      await cubit.fetchAllLeads();
    }
  }

  // ── Extracted body — reused by both embedded and full-screen modes ─────────
  Widget _buildBody() {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (ctx, state) {
        if (state is SolarLeadLoading) {
          return const Center(
            child: CircularProgressIndicator(color: LeadTheme.warning),
          );
        }

        if (state is SolarLeadError) {
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
                Text(state.message, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const AppSvgIcon(AppSvgAssets.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LeadTheme.primary,
                    foregroundColor: AppColors.surface,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SolarLeadsLoaded) {
          final all = state.leads;
          final filteredActive = _filterActive(all);
          final filteredCompleted = _filterCompleted(all);
          final active = all.where((l) => !l.isCompleted).length;
          final completed = all.where((l) => l.isCompleted).length;

          return Column(
            children: [
              // ── Summary bar ──────────────────────────────────
              if (all.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: LeadTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LeadTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('Total', '${all.length}', LeadTheme.warning),
                      Container(width: 1, height: 24, color: AppColors.divider),
                      _Stat('Active', '$active', LeadTheme.primary),
                      Container(width: 1, height: 24, color: AppColors.divider),
                      _Stat('Done', '$completed', AppColors.success),
                    ],
                  ),
                ),

              // ── Filters row ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _searchFocus.hasFocus
                                ? LeadTheme.warning.withValues(alpha: 0.5)
                                : AppColors.divider,
                            width: _searchFocus.hasFocus ? 1.5 : 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Search name / phone / created by',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: AppSvgIcon(
                                AppSvgAssets.search,
                                size: 16,
                                color: LeadTheme.warning,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status dropdown
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
                                : LeadTheme.orange.withValues(alpha: 0.5),
                            width: _filter == 'All' ? 1 : 1.5,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                value: _filter,
                                isExpanded: true,

                                buttonStyleData: const ButtonStyleData(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  height: 38,
                                ),

                                iconStyleData: const IconStyleData(
                                  icon: AppSvgIcon(
                                    AppSvgAssets.chevronDown,
                                    size: 16,
                                    color: LeadTheme.warning,
                                  ),
                                ),

                                dropdownStyleData: DropdownStyleData(
                                  width: constraints.maxWidth, // 👈 width fix
                                  maxHeight: 320,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),

                                items:
                                    [
                                      'All',
                                      'Active',
                                      'Completed',
                                      ...SolarLeadsModel
                                          .workflowSteps, // 👈 solar values same rahega
                                    ].map((s) {
                                      return DropdownMenuItem<String>(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      );
                                    }).toList(),

                                onChanged: (v) {
                                  if (v != null) setState(() => _filter = v);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Date filter chip
                    GestureDetector(
                      onTap: _selectedDate == null ? _pickDate : null,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _selectedDate == null
                              ? AppColors.surface
                              : LeadTheme.warning,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedDate == null
                                ? AppColors.divider
                                : LeadTheme.warning.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.calendarDays,
                              size: 16,
                              color: _selectedDate == null
                                  ? AppColors.textGray
                                  : AppColors.surface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dateLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedDate == null
                                    ? AppColors.textGray
                                    : AppColors.surface,
                                fontWeight: _selectedDate == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                            if (_selectedDate != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _clearDateFilter,
                                child: const AppSvgIcon(
                                  AppSvgAssets.x,
                                  size: 16,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Result count ─────────────────────────────────
              if (filteredActive.isNotEmpty || filteredCompleted.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredActive.length + filteredCompleted.length} lead${(filteredActive.length + filteredCompleted.length) != 1 ? "s" : ""}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: LeadTheme.textMuted,
                      ),
                    ),
                  ),
                ),

              // ── List / empty state ───────────────────────────
              Expanded(
                child: (filteredActive.isEmpty && filteredCompleted.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.sun,
                              size: 52,
                              color: AppColors.divider,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              all.isEmpty
                                  ? 'No Solar Leads yet'
                                  : _selectedDate != null
                                  ? 'No leads on ${_dateLabel()}'
                                  : 'No leads match filter',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: LeadTheme.primary,
                        onRefresh: () async => _refresh(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // ── ACTIVE LEADS ──────────────────────
                            final sortedActive = [...filteredActive]
                              ..sort(
                                (a, b) => b.createdAt.compareTo(a.createdAt),
                              );
                            final recentActive = sortedActive
                                .where(
                                  (lead) =>
                                      !lead.createdAt.isBefore(_recentCutoff),
                                )
                                .toList();
                            final olderActive = sortedActive
                                .where(
                                  (lead) =>
                                      lead.createdAt.isBefore(_recentCutoff),
                                )
                                .toList();

                            // ── COMPLETED LEADS - All in one list ──
                            final sortedCompleted = [...filteredCompleted]
                              ..sort(
                                (a, b) => b.createdAt.compareTo(a.createdAt),
                              );

                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
                              children: [
                                // ────────────────────────────────────
                                // ACTIVE PROJECTS
                                // ────────────────────────────────────
                                _TableSection(
                                  title: 'Active Leads - Last 7 Days',
                                  subtitle:
                                      'Showing newest active leads created in the last 7 days',
                                  leads: recentActive,
                                  onLeadTap: _openDetail,
                                  onDeleteTap: _confirmDeleteLead,
                                  isAdmin: _isAdmin,
                                  fallbackCreatorName: _loggedInUserName,
                                  minWidth: constraints.maxWidth < 900
                                      ? 920
                                      : constraints.maxWidth,
                                  showEmptyMessage: true,
                                ),
                                const SizedBox(height: 12),
                                _CollapsibleTableSection(
                                  title: 'Active Leads - Older',
                                  subtitle:
                                      'Older active records are collapsed by default',
                                  leads: olderActive,
                                  initiallyExpanded: _showOlderLeads,
                                  onExpansionChanged: (expanded) {
                                    if (mounted) {
                                      setState(
                                        () => _showOlderLeads = expanded,
                                      );
                                    }
                                  },
                                  onLeadTap: _openDetail,
                                  onDeleteTap: _confirmDeleteLead,
                                  isAdmin: _isAdmin,
                                  fallbackCreatorName: _loggedInUserName,
                                  minWidth: constraints.maxWidth < 900
                                      ? 920
                                      : constraints.maxWidth,
                                ),
                                const SizedBox(height: 20),

                                // ────────────────────────────────────
                                // COMPLETED PROJECTS - SINGLE TABLE
                                // ────────────────────────────────────
                                if (sortedCompleted.isNotEmpty) ...[
                                  _CollapsibleTableSection(
                                    title: 'Completed Projects',
                                    subtitle:
                                        'All completed projects listed by newest first',
                                    leads: sortedCompleted,
                                    initiallyExpanded: _showCompletedLeads,
                                    onExpansionChanged: (expanded) {
                                      if (mounted) {
                                        setState(
                                          () => _showCompletedLeads = expanded,
                                        );
                                      }
                                    },
                                    onLeadTap: _openDetail,
                                    onDeleteTap: _confirmDeleteLead,
                                    isAdmin: _isAdmin,
                                    fallbackCreatorName: _loggedInUserName,
                                    minWidth: constraints.maxWidth < 900
                                        ? 920
                                        : constraints.maxWidth,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Embedded mode: no Scaffold / AppBar / FAB ─────────────────────────
    if (widget.embedded) {
      return _buildBody();
    }

    // ── Full-screen mode ──────────────────────────────────────────────────
    return Scaffold(
      backgroundColor:  AppColors.background,
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
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Row(
          children: [
            AppSvgIcon(AppSvgAssets.sun, color: AppColors.surface, size: 18),
            SizedBox(width: 8),
            Text(
              'Solar Leads',
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
        onPressed: _openAddLead,
        backgroundColor: LeadTheme.primary,
        foregroundColor: AppColors.surface,
        icon: const AppSvgIcon(
          AppSvgAssets.plus,
          color: AppColors.surface,
          size: 18,
        ),
        label: const Text(
          'Solar Lead',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Leads Table Sections
// ─────────────────────────────────────────────────────────────
class _TableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SolarLeadsModel> leads;
  final ValueChanged<SolarLeadsModel> onLeadTap;
  final ValueChanged<SolarLeadsModel> onDeleteTap;
  final bool isAdmin;
  final String? fallbackCreatorName;
  final double minWidth;
  final bool showEmptyMessage;

  const _TableSection({
    required this.title,
    required this.subtitle,
    required this.leads,
    required this.onLeadTap,
    required this.onDeleteTap,
    required this.isAdmin,
    this.fallbackCreatorName,
    required this.minWidth,
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
                  '$title (${leads.length})',
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
                    color: LeadTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (leads.isEmpty && showEmptyMessage)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No leads available in this section.',
                style: TextStyle(fontSize: 12, color: LeadTheme.textMuted),
              ),
            )
          else if (leads.isNotEmpty)
            _LeadsDataTable(
              leads: leads,
              onLeadTap: onLeadTap,
              onDeleteTap: onDeleteTap,
              isAdmin: isAdmin,
              fallbackCreatorName: fallbackCreatorName,
              minWidth: minWidth,
            ),
        ],
      ),
    );
  }
}

class _CollapsibleTableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SolarLeadsModel> leads;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<SolarLeadsModel> onLeadTap;
  final ValueChanged<SolarLeadsModel> onDeleteTap;
  final bool isAdmin;
  final String? fallbackCreatorName;
  final double minWidth;

  const _CollapsibleTableSection({
    required this.title,
    required this.subtitle,
    required this.leads,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onLeadTap,
    required this.onDeleteTap,
    required this.isAdmin,
    this.fallbackCreatorName,
    required this.minWidth,
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
          // ── Unique key per section title to avoid Flutter confusing
          //    "Active Leads - Older" with "Completed Projects" ──────
          key: ValueKey('solar_section_$title'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(
            '$title (${leads.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: LeadTheme.textMuted),
          ),
          children: [
            if (leads.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No older leads found.',
                    style: TextStyle(fontSize: 12, color: LeadTheme.textMuted),
                  ),
                ),
              )
            else
              _LeadsDataTable(
                leads: leads,
                onLeadTap: onLeadTap,
                onDeleteTap: onDeleteTap,
                isAdmin: isAdmin,
                fallbackCreatorName: fallbackCreatorName,
                minWidth: minWidth,
              ),
          ],
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
      color: LeadTheme.primary,
    ),
  ),
);

class _LeadsDataTable extends StatelessWidget {
  final List<SolarLeadsModel> leads;
  final ValueChanged<SolarLeadsModel> onLeadTap;
  final ValueChanged<SolarLeadsModel> onDeleteTap;
  final bool isAdmin;
  final String? fallbackCreatorName;
  final double minWidth;

  const _LeadsDataTable({
    required this.leads,
    required this.onLeadTap,
    required this.onDeleteTap,
    required this.isAdmin,
    this.fallbackCreatorName,
    required this.minWidth,
  });

  String _creatorLabel(SolarLeadsModel lead) {
    final fromLead = lead.createdBy?.trim() ?? '';
    if (fromLead.isNotEmpty) return fromLead;
    final fromFallback = fallbackCreatorName?.trim() ?? '';
    if (fromFallback.isNotEmpty) return fromFallback;
    return 'Unknown';
  }

  String _formatCreatedAt(DateTime createdAt) {
    return DateTimeHelper.formatDateTime(createdAt);
  }

  String _amountLabel(SolarLeadsModel lead) {
    final amount = lead.finalAmount ?? lead.totalAmount;
    if (amount <= 0) return '-';
    return 'Rs. ${LeadTheme.formatAmount(amount)}';
  }

  Widget _statusBadge(String status) {
    final color = LeadTheme.statusColor(status);
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const rowTextStyle = TextStyle(fontSize: 12, color: AppColors.textDark);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 44,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 56,
            horizontalMargin: isDesktop ? 12 : 8,
            columnSpacing: isDesktop ? 14 : 8,
            headingRowColor: WidgetStateProperty.all(AppColors.primaryTint),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryTint;
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
              _buildColumn('Mobile'),
              _buildColumn('Address'),
              _buildColumn('Status'),
              _buildColumn('Amount'),
              _buildColumn('Created By'),
              _buildColumn('Created At'),
              if (isAdmin) _buildColumn('Actions'),
            ],
            rows: leads.map((lead) {
              return DataRow(
                onSelectChanged: (_) => onLeadTap(lead),
                cells: [
                  DataCell(
                    Text(
                      lead.customerName,
                      style: rowTextStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(lead.mobile, style: rowTextStyle)),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 240 : 180,
                      child: Text(
                        lead.address.isEmpty ? '-' : lead.address,
                        overflow: TextOverflow.ellipsis,
                        style: rowTextStyle,
                      ),
                    ),
                  ),
                  DataCell(_statusBadge(lead.status)),
                  DataCell(
                    Text(
                      _amountLabel(lead),
                      style: rowTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: LeadTheme.primary,
                      ),
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_creatorLabel(lead), style: rowTextStyle),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeHelper.formatTime(lead.createdAt),
                          style: rowTextStyle.copyWith(
                            fontSize: 10,
                            color: LeadTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(_formatCreatedAt(lead.createdAt), style: rowTextStyle),
                  ),
                  if (isAdmin)
                    DataCell(
                      IconButton(
                        tooltip: 'Delete Lead',
                        onPressed: () => onDeleteTap(lead),
                        icon: AppSvgIcon(
                          AppSvgAssets.trash2,
                          size: 18,
                          color:  AppColors.error,
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

// ─────────────────────────────────────────────────────────────
//  Stat Widget
// ─────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: const TextStyle(fontSize: 10, color: LeadTheme.textMuted),
        ),
      ],
    );
  }
}
