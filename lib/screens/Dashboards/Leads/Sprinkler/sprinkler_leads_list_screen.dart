// lib/screens/Dashboards/Leads/Sprinkler/sprinkler_leads_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/date_time_helper.dart';
import 'package:solar_project/Helper/pagiantionbar.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/add_sprinkler_lead_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_lead_detail_screen.dart';

// ── Design tokens (matching service_request_page) ─────────────────────────────
const _kBlue = LeadTheme.secondary;
const _kBlueLight = AppColors.lightBg6;
const _kBg = AppColors.veryLight7;
const _kSurface = AppColors.veryLight7;
const _kBorder = AppColors.bgLight2;
const _kText = AppColors.grayDark3;
const _kTextMuted = AppColors.textGray;
const _kTextHint = AppColors.grayLight;

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

class _SprinklerLeadsListScreenState extends State<SprinklerLeadsListScreen>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _search = '';
  String _filter = 'All';
  DateTime? _selectedDate;
  int _tabIndex = 0;
  final Map<int, int> _tabPages = {0: 1, 1: 1, 2: 1};
  bool _isDisposed = false;
  Timer? _searchDebounce;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _searchFocus.addListener(() {
      if (mounted && !_isDisposed) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        context.read<SprinklerLeadCubit>().fetchAllLeads();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Refresh ────────────────────────────────────────────────────────────────
  void _refresh() {
    if (!mounted || _isDisposed) return;
    _fadeCtrl.reset();
    _tabPages.clear();
    _tabPages.addAll({0: 1, 1: 1, 2: 1});
    _tabIndex = 0;
    context.read<SprinklerLeadCubit>().fetchAllLeads(
      search: _search.isNotEmpty ? _search : null,
      status: _filter != 'All' && _filter != 'Active' && _filter != 'Completed'
          ? _filter
          : null,
      selectedDate: _selectedDate,
    );
    _fadeCtrl.forward();
  }

  // ── Search with debounce ───────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    setState(() => _search = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _isDisposed) return;
      _refresh();
    });
  }

  // ── Filter ─────────────────────────────────────────────────────────────────
  void _onFilterChanged(String label) {
    setState(() => _filter = label);
    _refresh();
  }

  // ── Date filter ───────────────────────────────────────────────────────────
  void _onDatePicked() async {
    final picked = await DateTimeHelper.pickPastDate(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _refresh();
    }
  }

  void _onDateCleared() {
    setState(() => _selectedDate = null);
    _refresh();
  }

  // ── Tab ────────────────────────────────────────────────────────────────────
  void _onTabChanged(int newTabIndex) {
    if (!mounted || _isDisposed) return;
    _fadeCtrl.reset();
    setState(() => _tabIndex = newTabIndex);
    context.read<SprinklerLeadCubit>().setTabAndFetch(newTabIndex);
    _fadeCtrl.forward();
  }

  // ── Page ───────────────────────────────────────────────────────────────────
  void _onPageChanged(int page) {
    if (!mounted || _isDisposed) return;
    setState(() => _tabPages[_tabIndex] = page);
    context.read<SprinklerLeadCubit>().fetchPage(page, tabIndex: _tabIndex);
  }

  String _dateLabel() => DateTimeHelper.leadDateFilterLabel(_selectedDate);

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

  // ── Delete ─────────────────────────────────────────────────────────────────
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
                color:   AppColors.lightPurple1,
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
                    lead.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.phone,
                    style: const TextStyle(fontSize: 12, color: _kTextMuted),
                  ),
                  Text(
                    lead.address,
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
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently remove ALL data including site visit, quotation, installation, payment records and photos. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
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
            child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:   AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Delete',
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
            color: AppColors.error,
          ),
        ),
        content: Text(
          'You are about to permanently delete the lead for "${lead.customerName}". All records will be gone forever.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.gray400,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
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
              backgroundColor:   AppColors.error,
              foregroundColor: Colors.white,
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

  // ── Open detail ───────────────────────────────────────────────────────────
  Future<void> _openDetail(SprinklerLeadModel lead) async {
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
    if (mounted) {
      setState(() {
        _filter = 'All';
        _selectedDate = null;
        _search = '';
        _searchCtrl.clear();
        _tabIndex = 0;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      cubit.fetchAllLeads();
    }
  }

  Future<void> _openAddLead() async {
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
    if (addedLead != null) await cubit.fetchAllLeads();
  }

  // ── Pagination bar ─────────────────────────────────────────────────────────
  // Widget _buildPaginationBar({
  //   required int currPage,
  //   required int totalPages,
  //   required int shownCount,
  // }) {
  //   return Container(
  //     height: 56,
  //     decoration: BoxDecoration(
  //       color: _kSurface,
  //       border: Border(top: BorderSide(color: _kBorder)),
  //     ),
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           '$shownCount results  ·  Page $currPage of $totalPages',
  //           style: const TextStyle(
  //             fontSize: 12,
  //             color: _kTextMuted,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         Row(
  //           children: [
  //             _PaginationBtn(
  //               icon: AppSvgAssets.chevronLeft,
  //               enabled: currPage > 1,
  //               onTap: () => _onPageChanged(currPage - 1),
  //             ),
  //             const SizedBox(width: 4),
  //             ...List.generate(totalPages, (i) {
  //               final p = i + 1;
  //               final isSel = p == currPage;
  //               if (totalPages > 5) {
  //                 if (p != 1 &&
  //                     p != totalPages &&
  //                     (p < currPage - 1 || p > currPage + 1)) {
  //                   if (p == currPage - 2 || p == currPage + 2) {
  //                     return const Padding(
  //                       padding: EdgeInsets.symmetric(horizontal: 4),
  //                       child: Text(
  //                         '…',
  //                         style: TextStyle(fontSize: 12, color: _kTextMuted),
  //                       ),
  //                     );
  //                   }
  //                   return const SizedBox.shrink();
  //                 }
  //               }
  //               return GestureDetector(
  //                 onTap: () => _onPageChanged(p),
  //                 child: AnimatedContainer(
  //                   duration: const Duration(milliseconds: 180),
  //                   margin: const EdgeInsets.symmetric(horizontal: 2),
  //                   width: 32,
  //                   height: 32,
  //                   decoration: BoxDecoration(
  //                     color: isSel ? _kBlue : Colors.transparent,
  //                     borderRadius: BorderRadius.circular(8),
  //                     border: Border.all(color: isSel ? _kBlue : _kBorder),
  //                   ),
  //                   child: Center(
  //                     child: Text(
  //                       '$p',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w600,
  //                         color: isSel ? Colors.white : _kText,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }),
  //             const SizedBox(width: 4),
  //             _PaginationBtn(
  //               icon: AppSvgAssets.chevronRight,
  //               enabled: currPage < totalPages,
  //               onTap: () => _onPageChanged(currPage + 1),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
      builder: (ctx, state) {
        if (state is SprinklerLeadLoading) {
          return const Center(child: _LoadingIndicator());
        }

        if (state is SprinklerLeadError) {
          return _ErrorView(message: state.message, onRetry: _refresh);
        }

        if (state is SprinklerLeadsLoaded) {
          final all = state.leads;
          final totalAll = state.total;
          final currPage = state.page;
          final totalPages = state.pages;
          final tabIndex = state.tabIndex;
          final displayLeads = all;
          final isEmpty = displayLeads.isEmpty;

          return FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ── Search + Date row ────────────────────────────────────────
                // ── Search + Date row ────────────────────────────────────────
                Container(
                  color: _kSurface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          hasFocus: _searchFocus.hasFocus,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DateFilterButton(
                        label: _dateLabel(),
                        hasDate: _selectedDate != null,
                        onTap: _selectedDate == null ? _onDatePicked : null,
                        onClear: _onDateCleared,
                      ),
                      const SizedBox(width: 8),

                      // ── Add Lead Button ──────────────────────────────
                      GestureDetector(
                        onTap: _openAddLead,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _kBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(
                                AppSvgAssets.plus,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add Lead',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Filter chips ─────────────────────────────────────────────
                Container(
                  color: _kSurface,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children:
                          [
                            'All',
                            'Active',
                            'Completed',
                            ...SprinklerLeadModel.workflowSteps,
                          ].asMap().entries.map((entry) {
                            final index = entry.key;
                            final label = entry.value;
                            final isSel = _filter == label;
                            final total =
                                3 + SprinklerLeadModel.workflowSteps.length;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == total - 1 ? 0 : 8,
                              ),
                              child: _FilterChip(
                                label: label,
                                selected: isSel,
                                onTap: () => _onFilterChanged(label),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                // ── Divider ──────────────────────────────────────────────────
                Container(height: 1, color: _kBorder),

                // ── Tabs + Table ─────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    // ← moved RefreshIndicator here (same as Solar)
                    color: _kBlue,
                    onRefresh: () async => _refresh(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cubit = context.read<SprinklerLeadCubit>();
                        final sortedDisplay = [...displayLeads]
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                        final tabData = [
                          (
                            label: 'Recent',
                            totalCount: cubit.getTabTotalLeads(0),
                            leads: tabIndex == 0
                                ? sortedDisplay
                                : <SprinklerLeadModel>[],
                            emptyMsg: 'No active leads in the last 7 days.',
                            color: _kBlue,
                          ),
                          (
                            label: 'Older',
                            totalCount: cubit.getTabTotalLeads(1),
                            leads: tabIndex == 1
                                ? sortedDisplay
                                : <SprinklerLeadModel>[],
                            emptyMsg: 'No older active leads.',
                            color:   AppColors.amber,
                          ),
                          (
                            label: 'Completed',
                            totalCount: cubit.getTabTotalLeads(2),
                            leads: tabIndex == 2
                                ? sortedDisplay
                                : <SprinklerLeadModel>[],
                            emptyMsg: 'No completed projects yet.',
                            color:   AppColors.success,
                          ),
                        ];

                        final currentLeads = tabData[_tabIndex].leads;
                        final currentEmpty = tabData[_tabIndex].emptyMsg;

                        return Column(
                          children: [
                            // ── Tab bar ──────────────────────────────────────
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
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? _kBlue
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSel
                                                      ? Colors.white.withValues(
                                                          alpha: 0.25,
                                                        )
                                                      : _kBg,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${tab.totalCount}',
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

                            // ── Table / empty ─────────────────────────────────
                            Expanded(
                              child: RefreshIndicator(
                                color: _kBlue,
                                onRefresh: () async => _refresh(),
                                child:
                                    isEmpty // ← isEmpty check moved inside
                                    ? _EmptyView(
                                        search: _search,
                                        filter: _filter,
                                        dateLabel: _dateLabel(),
                                        hasDate: _selectedDate != null,
                                        onRefresh: _refresh,
                                      )
                                    : currentLeads.isEmpty
                                    ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          SizedBox(
                                            height: 300,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 64,
                                                  height: 64,
                                                  decoration: BoxDecoration(
                                                    color: _kBlueLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: AppSvgIcon(
                                                      _tabIndex == 2
                                                          ? AppSvgAssets
                                                                .circleCheckBig
                                                          : AppSvgAssets
                                                                .droplet,
                                                      size: 28,
                                                      color: _kBlue,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  currentEmpty,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _kText,
                                                  ),
                                                ),
                                                if (_search.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Search: "$_search"',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: _kTextMuted,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                const Text(
                                                  'Pull down to refresh the list',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _kTextMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                GestureDetector(
                                                  onTap: _refresh,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _kBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: _kBorder,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Refresh',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _kTextMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          4,
                                          16,
                                          16,
                                        ),
                                        children: [
                                          _LeadsDataTable(
                                            leads: currentLeads,
                                            onLeadTap: _openDetail,
                                            onDeleteTap: _confirmDeleteLead,
                                            isAdmin: _isAdmin,
                                            fallbackCreatorName:
                                                _loggedInUserName,
                                            minWidth: constraints.maxWidth < 900
                                                ? 960
                                                : constraints.maxWidth,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            // ── Pagination ────────────────────────────────────
                            if (totalAll > 0)
                              PaginationBar(
                                currentPage: currPage,
                                totalPages: totalPages,
                                totalItems: totalAll,
                                activeColor: _kBlue,
                                onPageChanged: _onPageChanged,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        elevation: 0,
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
      ),
      body: _buildBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable UI components
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: _kBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: hasFocus ? _kBlue.withValues(alpha: 0.5) : _kBorder,
        width: hasFocus ? 1.5 : 1,
      ),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: const InputDecoration(
        hintText: 'Search name / phone / created by',
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

class _DateFilterButton extends StatelessWidget {
  final String label;
  final bool hasDate;
  final VoidCallback? onTap;
  final VoidCallback onClear;
  const _DateFilterButton({
    required this.label,
    required this.hasDate,
    required this.onTap,
    required this.onClear,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hasDate ? _kBlue : _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasDate ? _kBlue : _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            AppSvgAssets.calendarDays,
            size: 16,
            color: hasDate ? Colors.white : _kTextMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: hasDate ? Colors.white : _kTextMuted,
              fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasDate) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: const AppSvgIcon(
                AppSvgAssets.x,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
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
        color: selected ? _kBlue : _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? _kBlue : _kBorder,
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
        child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
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
              color: _kBlue,
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
  final String search, filter, dateLabel;
  final bool hasDate;
  final VoidCallback onRefresh;
  const _EmptyView({
    required this.search,
    required this.filter,
    required this.dateLabel,
    required this.hasDate,
    required this.onRefresh,
  });
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
                color: _kBlueLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: AppSvgIcon(
                  AppSvgAssets.droplet,
                  size: 28,
                  color: _kBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              search.isNotEmpty
                  ? 'No leads found for "$search"'
                  : filter != 'All'
                  ? 'No leads found for "$filter" filter'
                  : hasDate
                  ? 'No leads found for $dateLabel'
                  : 'No Sprinkler Leads yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a new lead using the button below.',
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

// class _PaginationBtn extends StatelessWidget {
//   final String icon;
//   final bool enabled;
//   final VoidCallback onTap;
//   const _PaginationBtn({
//     required this.icon,
//     required this.enabled,
//     required this.onTap,
//   });
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: enabled ? onTap : null,
//     child: Container(
//       width: 32,
//       height: 32,
//       decoration: BoxDecoration(
//         color: enabled ? _kSurface : _kBg,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: _kBorder),
//       ),
//       child: Center(
//         child: AppSvgIcon(icon, size: 13, color: enabled ? _kText : _kTextHint),
//       ),
//     ),
//   );
// }

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
              dataRowMinHeight: 56,
              dataRowMaxHeight: 70,
              horizontalMargin: isDesktop ? 16 : 12,
              columnSpacing: isDesktop ? 20 : 12,
              dividerThickness: 1,
              headingRowColor: WidgetStateProperty.all(  AppColors.gray100),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered))
                  return   AppColors.veryLight10;
                return _kSurface;
              }),
              border: TableBorder(
                horizontalInside: BorderSide(color: _kBorder, width: 0.8),
              ),
              columns: [
                _col('Customer'),
                _col('Mobile'),
                _col('Address'),
                _col('Status'),
                _col('Amount'),
                _col('Created By'),
                _col('Created At'),
                if (isAdmin) _col(''),
              ],
              rows: leads.map((lead) {
                final addressText = [
                  lead.address,
                  lead.village,
                ].where((s) => s.isNotEmpty).join(', ');
                return DataRow(
                  onSelectChanged: (_) => onLeadTap(lead),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _kBlueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                lead.customerName.isNotEmpty
                                    ? lead.customerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lead.customerName,
                            style: rowStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        lead.phone,
                        style: rowStyle.copyWith(color: _kTextMuted),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: isDesktop ? 200 : 160,
                        child: Text(
                          addressText.isEmpty ? '—' : addressText,
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
                          color: _kBlue,
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color:   AppColors.lightBg5,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    _creatorLabel(lead).isNotEmpty
                                        ? _creatorLabel(lead)[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.indigo600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(_creatorLabel(lead), style: rowStyle),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateTimeHelper.formatTime(lead.createdAt),
                            style: rowStyle.copyWith(
                              fontSize: 10,
                              color: _kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(_formatCreatedAt(lead.createdAt), style: rowStyle),
                    ),
                    if (isAdmin)
                      DataCell(
                        GestureDetector(
                          onTap: () => onDeleteTap(lead),
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
                );
              }).toList(),
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











