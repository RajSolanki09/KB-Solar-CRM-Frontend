// lib/screens/Dashboards/Leads/Sprinkler/sprinkler_leads_list_screen.dart

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/date_time_helper.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/add_sprinkler_lead_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_lead_detail_screen.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SprinklerLeadsListScreen extends StatefulWidget {
  final Color appBarColor;
  final bool embedded;
  const SprinklerLeadsListScreen({
    super.key,
    this.appBarColor = LeadTheme.secondary,
    this.embedded = false,
  });

  @override
  State<SprinklerLeadsListScreen> createState() =>
      _SprinklerLeadsListScreenState();
}

class _SprinklerLeadsListScreenState extends State<SprinklerLeadsListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'All';
  DateTime? _selectedDate;
  bool _showOlderLeads = false;
  bool _showCompletedLeads = false;

  @override
  void initState() {
    super.initState();
    // FIX: mounted check added — same pattern as solar_leads_list_screen.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchLeads();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Safe fetch helper — always guards with mounted + try/catch.
  void _fetchLeads() {
    if (!mounted) return;
    try {
      context.read<SprinklerLeadCubit>().fetchAllLeads();
    } catch (_) {}
  }

  void _refresh() => _fetchLeads();

  List<SprinklerLeadModel> _filterActive(List<SprinklerLeadModel> all) {
    return all.where((l) {
      if (l.isCompleted) return false;

      final s = _search.toLowerCase();
      final matchSearch =
          s.isEmpty ||
          l.customerName.toLowerCase().contains(s) ||
          l.phone.contains(s) ||
          l.address.toLowerCase().contains(s) ||
          l.village.toLowerCase().contains(s) ||
          (l.createdByName ?? '').toLowerCase().contains(s);

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

  List<SprinklerLeadModel> _filterCompleted(List<SprinklerLeadModel> all) {
    return all.where((l) {
      if (!l.isCompleted) return false;
      if (_filter == 'Active') return false;

      final s = _search.toLowerCase();
      final matchSearch =
          s.isEmpty ||
          l.customerName.toLowerCase().contains(s) ||
          l.phone.contains(s) ||
          l.address.toLowerCase().contains(s) ||
          l.village.toLowerCase().contains(s) ||
          (l.createdByName ?? '').toLowerCase().contains(s);

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

  String _dateLabel() => DateTimeHelper.leadDateFilterLabel(_selectedDate);

  DateTime get _recentCutoff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 2));
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

  Future<void> _confirmDeleteLead(SprinklerLeadModel lead) async {
    if (!_isAdmin) {
      if (!mounted) return;
      AppFeedback.showInfo(context, 'Only admin can delete leads.');
      return;
    }

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
                color: AppColors.primaryLightest),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppSvgIcon(
                AppSvgAssets.trash2,
                size: 20,
                color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Lead?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
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
                color: AppColors.bgSecondary),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.phone,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  Text(
                    lead.address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLightest)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSvgIcon(
                    AppSvgAssets.triangleAlert,
                    size: 16,
                    color: AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently remove ALL data including '
                      'site visit, quotation, installation, payment records '
                      'and photos. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary),
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            color: AppColors.primary),
          ),
        ),
        content: Text(
          'You are about to permanently delete the lead for '
          '"${lead.customerName}". All records will be gone forever.',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'No, Keep It',
              style: TextStyle(color: AppColors.textPrimary), fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Forever', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true || !mounted) return;

    // FIX: cubit captured before any async gap
    final cubit = context.read<SprinklerLeadCubit>();
    await cubit.deleteLead(lead.id);

    if (!mounted) return;
    final latestState = cubit.state;
    if (latestState is SprinklerLeadError) {
      AppFeedback.showError(context, latestState.message);
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

  // FIX: mounted check added after await + try/catch for safe fetch
  Future<void> _openDetail(SprinklerLeadModel lead) async {
    // Capture cubit BEFORE pushing — stable reference across async gap
    final cubit = context.read<SprinklerLeadCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: SprinklerLeadDetailScreen(lead: lead),
        ),
      ),
    );

    // FIX: mounted check before fetchAllLeads
    if (!mounted) return;
    setState(() {
      _filter = 'All';
      _selectedDate = null;
      _search = '';
      _searchCtrl.clear();
      _showOlderLeads = false;
    });
    try {
      cubit.fetchAllLeads();
    } catch (_) {}
  }

  Future<void> _openAddLead() async {
    // Capture cubit BEFORE pushing
    final cubit = context.read<SprinklerLeadCubit>();

    final addedLead = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const AddSprinklerLeadScreen(),
        ),
      ),
    );

    if (!mounted) return;
    if (addedLead != null) {
      try {
        await cubit.fetchAllLeads();
      } catch (_) {}
    }
  }

  Widget _buildBody() {
    return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
      builder: (ctx, state) {
        if (state is SprinklerLeadLoading) {
          return const Center(
            child: CircularProgressIndicator(color: LeadTheme.secondary),
          );
        }

        if (state is SprinklerLeadError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvgIcon(
                  AppSvgAssets.triangleAlert,
                  size: 48,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 12),
                Text(state.message, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const AppSvgIcon(AppSvgAssets.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LeadTheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SprinklerLeadsLoaded) {
          final all = state.leads;
          final filteredActive = _filterActive(all);
          final filteredCompleted = _filterCompleted(all);
          final active = all.where((l) => !l.isCompleted).length;
          final completed = all.where((l) => l.isCompleted).length;

          return Column(
            children: [
              if (all.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: LeadTheme.secondary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LeadTheme.secondary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('Total', '${all.length}', LeadTheme.secondary),
                      Container(width: 1, height: 24, color: AppColors.borderLight),
                      _Stat('Active', '$active', AppColors.warning),
                      Container(width: 1, height: 24, color: AppColors.borderLight),
                      _Stat('Done', '$completed', AppColors.success),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Search name / phone / created by',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary),
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: AppSvgIcon(
                                AppSvgAssets.search,
                                size: 16,
                                color: LeadTheme.secondary,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _filter == 'All'
                                ? AppColors.borderLight
                                : LeadTheme.secondary.withValues(alpha: 0.5),
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
                                    color: LeadTheme.secondary,
                                  ),
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  width: constraints.maxWidth,
                                  maxHeight: 320,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: [
                                  'All',
                                  'Active',
                                  'Completed',
                                  ...SprinklerLeadModel.workflowSteps,
                                ].map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(s),
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
                    GestureDetector(
                      onTap: _selectedDate == null ? _pickDate : null,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _selectedDate == null
                              ? Colors.white
                              : LeadTheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedDate == null
                                ? AppColors.borderLight
                                : LeadTheme.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.calendarDays,
                              size: 16,
                              color: _selectedDate == null
                                  ? AppColors.textSecondary)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dateLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedDate == null
                                    ? AppColors.textSecondary)
                                    : Colors.white,
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
                                  color: Colors.white,
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

              if (filteredActive.isNotEmpty || filteredCompleted.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredActive.length + filteredCompleted.length} lead${(filteredActive.length + filteredCompleted.length) != 1 ? "s" : ""}',
                      style: const TextStyle(fontSize: 11, color: LeadTheme.textMuted),
                    ),
                  ),
                ),

              Expanded(
                child: (filteredActive.isEmpty && filteredCompleted.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.droplet,
                              size: 52,
                              color: AppColors.borderLight,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              all.isEmpty
                                  ? 'No Sprinkler Leads yet'
                                  : _selectedDate != null
                                  ? 'No leads on ${_dateLabel()}'
                                  : 'No leads match filter',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: LeadTheme.secondary,
                        onRefresh: () async => _refresh(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final sortedActive = [...filteredActive]
                              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                            final recent = sortedActive
                                .where((l) => !l.createdAt.isBefore(_recentCutoff))
                                .toList();
                            final older = sortedActive
                                .where((l) => l.createdAt.isBefore(_recentCutoff))
                                .toList();
                            final sortedCompleted = [...filteredCompleted]
                              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
                              children: [
                                _TableSection(
                                  title: 'Last 3 Days Leads',
                                  subtitle:
                                      'Showing newest leads created in the last three days',
                                  leads: recent,
                                  onLeadTap: _openDetail,
                                  onDeleteTap: _confirmDeleteLead,
                                  isAdmin: _isAdmin,
                                  fallbackCreatorName: _loggedInUserName,
                                  minWidth: constraints.maxWidth < 900
                                      ? 960
                                      : constraints.maxWidth,
                                  showEmptyMessage: true,
                                ),
                                const SizedBox(height: 12),
                                _CollapsibleTableSection(
                                  title: 'Older Leads',
                                  subtitle: 'Older records are collapsed by default',
                                  leads: older,
                                  initiallyExpanded: _showOlderLeads,
                                  onExpansionChanged: (expanded) {
                                    if (mounted) setState(() => _showOlderLeads = expanded);
                                  },
                                  onLeadTap: _openDetail,
                                  onDeleteTap: _confirmDeleteLead,
                                  isAdmin: _isAdmin,
                                  fallbackCreatorName: _loggedInUserName,
                                  minWidth: constraints.maxWidth < 900
                                      ? 960
                                      : constraints.maxWidth,
                                ),
                                const SizedBox(height: 12),
                                if (sortedCompleted.isNotEmpty)
                                  _CollapsibleTableSection(
                                    title: 'Completed Projects',
                                    subtitle: 'All completed projects are listed here',
                                    leads: sortedCompleted,
                                    initiallyExpanded: _showCompletedLeads,
                                    onExpansionChanged: (expanded) {
                                      if (mounted) {
                                        setState(() => _showCompletedLeads = expanded);
                                      }
                                    },
                                    onLeadTap: _openDetail,
                                    onDeleteTap: _confirmDeleteLead,
                                    isAdmin: _isAdmin,
                                    fallbackCreatorName: _loggedInUserName,
                                    minWidth: constraints.maxWidth < 900
                                        ? 960
                                        : constraints.maxWidth,
                                  ),
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
    if (widget.embedded) {
      return _buildBody();
    }

    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Row(
          children: [
            AppSvgIcon(AppSvgAssets.droplet, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Sprinkler Leads',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLead,
        backgroundColor: LeadTheme.secondary,
        foregroundColor: Colors.white,
        icon: const AppSvgIcon(AppSvgAssets.plus, color: Colors.white, size: 18),
        label: const Text('Sprinkler Lead', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _buildBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Table Section (always expanded)
// ─────────────────────────────────────────────────────────────────────────────
class _TableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SprinklerLeadModel> leads;
  final ValueChanged<SprinklerLeadModel> onLeadTap;
  final ValueChanged<SprinklerLeadModel> onDeleteTap;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight)),
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
                    color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: LeadTheme.textMuted),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Table Section (collapsible)
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleTableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SprinklerLeadModel> leads;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<SprinklerLeadModel> onLeadTap;
  final ValueChanged<SprinklerLeadModel> onDeleteTap;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('sprinkler_section_$title'),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(
            '$title (${leads.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Data Table
// ─────────────────────────────────────────────────────────────────────────────
class _LeadsDataTable extends StatelessWidget {
  final List<SprinklerLeadModel> leads;
  final ValueChanged<SprinklerLeadModel> onLeadTap;
  final ValueChanged<SprinklerLeadModel> onDeleteTap;
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

  String _creatorLabel(SprinklerLeadModel lead) {
    final fromLead = (lead.createdByName ?? '').trim();
    if (fromLead.isNotEmpty) return fromLead;
    final fromFallback = (fallbackCreatorName ?? '').trim();
    if (fromFallback.isNotEmpty) return fromFallback;
    return 'Unknown';
  }

  String _formatCreatedAt(DateTime dt) => DateTimeHelper.formatDateTime(dt);

  String _amountLabel(SprinklerLeadModel lead) {
    if (lead.totalAmount <= 0) return '-';
    return 'Rs. ${LeadTheme.formatAmount(lead.totalAmount)}';
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
    const rowStyle = TextStyle(fontSize: 12, color: AppColors.textPrimary));

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
            headingRowColor: WidgetStateProperty.all(const Color(0XFFF1F8FE)),
            columnSpacing: isDesktop ? 14 : 8,
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return LeadTheme.secondary.withValues(alpha: 0.06);
              }
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.blueGrey.shade50),
              bottom: BorderSide(color: Colors.blueGrey.shade100),
              top: BorderSide(color: Colors.blueGrey.shade100),
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
              final addressText = [lead.address, lead.village]
                  .where((s) => s.isNotEmpty)
                  .join(', ');

              return DataRow(
                onSelectChanged: (_) => onLeadTap(lead),
                cells: [
                  DataCell(
                    Text(
                      lead.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(lead.phone, style: rowStyle)),
                  DataCell(
                    SizedBox(
                      width: isDesktop ? 200 : 160,
                      child: Text(
                        addressText.isEmpty ? '-' : addressText,
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle,
                      ),
                    ),
                  ),
                  DataCell(_statusBadge(lead.status)),
                  DataCell(
                    Text(
                      _amountLabel(lead),
                      style: rowStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: LeadTheme.secondary,
                      ),
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_creatorLabel(lead), style: rowStyle),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeHelper.formatTime(lead.createdAt),
                          style: rowStyle.copyWith(
                            fontSize: 10,
                            color: LeadTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(_formatCreatedAt(lead.createdAt), style: rowStyle)),
                  if (isAdmin)
                    DataCell(
                      Tooltip(
                        message: 'Permanently delete this lead',
                        child: IconButton(
                          onPressed: () => onDeleteTap(lead),
                          icon: const AppSvgIcon(
                            AppSvgAssets.trash2,
                            size: 18,
                            color: AppColors.primary),
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
          color: AppColors.primary),
        ),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  Stat Widget
// ─────────────────────────────────────────────────────────────────────────────
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: LeadTheme.textMuted),
        ),
      ],
    );
  }
}






