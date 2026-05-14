import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'add_followup_screen.dart';
import 'material_tab_body.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class FollowupItem {
  final String id;
  final String module;
  final String customerName;
  final String phone;
  final String address;
  final String stageName;
  final String? lastRemark;
  final DateTime nextFollowupDate;
  final String? assignedToId;

  FollowupItem({
    required this.id,
    required this.module,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.stageName,
    this.lastRemark,
    required this.nextFollowupDate,
    this.assignedToId,
  });

  factory FollowupItem.fromSolar(SolarLeadsModel l) => FollowupItem(
        id: l.id,
        module: 'solar',
        customerName: l.customerName,
        phone: l.mobile,
        address: l.address,
        stageName: l.status,
        lastRemark: l.lastRemark,
        nextFollowupDate: l.nextFollowupDate!,
      );

  factory FollowupItem.fromSprinkler(SprinklerLeadModel l) => FollowupItem(
        id: l.id,
        module: 'sprinkler',
        customerName: l.customerName,
        phone: l.phone,
        address: l.address,
        stageName: l.status,
        lastRemark: l.lastRemark,
        nextFollowupDate: l.nextFollowupDate!,
      );

  factory FollowupItem.fromMaterialCustomer(Map<String, dynamic> customer) {
    final id = (customer['_id'] ?? customer['id'] ?? '').toString();
    final pipeline = customer['pipeline'] is Map<String, dynamic>
        ? customer['pipeline'] as Map<String, dynamic>
        : <String, dynamic>{};
    final followUp = pipeline['followUp'] is Map<String, dynamic>
        ? pipeline['followUp'] as Map<String, dynamic>
        : <String, dynamic>{};
    final assignedToRaw = followUp['assignedTo'];

    String? assignedToId;
    if (assignedToRaw is Map<String, dynamic>) {
      final idValue =
          (assignedToRaw['_id'] ?? assignedToRaw['id'] ?? '').toString().trim();
      assignedToId = idValue.isEmpty ? null : idValue;
    } else {
      final idValue = (assignedToRaw ?? '').toString().trim();
      assignedToId = idValue.isEmpty ? null : idValue;
    }

    return FollowupItem(
      id: id,
      module: 'material',
      customerName: (customer['customerName'] ?? '-').toString(),
      phone: (customer['mobile'] ?? customer['phone'] ?? '-').toString(),
      address: (customer['address'] ?? '').toString(),
      stageName: (pipeline['status'] ?? 'Follow-up').toString(),
      lastRemark: null,
      nextFollowupDate: DateTime.parse(followUp['followUpAt'].toString()),
      assignedToId: assignedToId,
    );
  }

  int get daysFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDate = nextFollowupDate.toLocal();
    final next = DateTime(localDate.year, localDate.month, localDate.day);
    return next.difference(today).inDays;
  }

  String get followupStatus {
    final days = daysFromToday;
    if (days < 0) return 'overdue';
    if (days == 0) return 'today';
    return 'upcoming';
  }

  String? get followupTime {
    final localDate = nextFollowupDate.toLocal();
    if (localDate.hour == 0 && localDate.minute == 0) return null;
    final h = localDate.hour;
    final m = localDate.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class FollowupListScreen extends StatefulWidget {
  final Color appBarColor;
  const FollowupListScreen({
    super.key,
    this.appBarColor = AppColors.purpleDark,
  });

  @override
  State<FollowupListScreen> createState() => _FollowupListScreenState();
}

class _FollowupListScreenState extends State<FollowupListScreen>
    with TickerProviderStateMixin {
  int _solarPage = 1;
  int _solarTotalPages = 1;
  int _solarTotal = 0;
  int _sprinklerPage = 1;
  int _sprinklerTotalPages = 1;
  int _sprinklerTotal = 0;
  final ApiService _apiService = ApiService();
  late TabController _moduleTab;
  bool _materialLoading = true;
  List<FollowupItem> _materialItems = const [];
  int _materialPage = 1;
  int _materialTotalPages = 1;
  int _materialTotal = 0;
  int _materialTodayOverdueCount = 0;
  static const int _materialPageSize = 10;

  @override
  void initState() {
    super.initState();
    _moduleTab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _moduleTab.dispose();
    super.dispose();
  }

  void _load() {
    context.read<SolarLeadCubit>().fetchAllLeads();
    context.read<SprinklerLeadCubit>().fetchAllLeads();
    _loadMaterialFollowups(page: 1);
  }

  Future<void> _loadMaterialFollowups({int page = 1}) async {
    if (mounted) setState(() => _materialLoading = true);
    try {
      final response = await _apiService.getMaterialCustomers(
        page: page,
        limit: _materialPageSize,
      );
      final items = (response['customers'] as List)
          .where((c) {
            final pipeline = c['pipeline'];
            if (pipeline is! Map<String, dynamic>) return false;
            final followUp = pipeline['followUp'];
            if (followUp is! Map<String, dynamic>) return false;
            final followUpAt = followUp['followUpAt'];
            return followUpAt != null &&
                followUpAt.toString().trim().isNotEmpty &&
                DateTime.tryParse(followUpAt.toString()) != null;
          })
          .map((c) =>
              FollowupItem.fromMaterialCustomer(c as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _materialItems = items;
        _materialPage = response['page'] ?? 1;
        _materialTotalPages = response['totalPages'] ?? 1;
        _materialTotal = response['total'] ?? items.length;
        _materialTodayOverdueCount =
            items.where((i) => i.daysFromToday <= 0).length;
        _materialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _materialItems = const [];
        _materialLoading = false;
        _materialPage = 1;
        _materialTotalPages = 1;
        _materialTotal = 0;
        _materialTodayOverdueCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (context, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (context, spkState) {
            final solarLeads = solarState is SolarLeadsLoaded
                ? solarState.leads
                : <SolarLeadsModel>[];
            final spkLeads = spkState is SprinklerLeadsLoaded
                ? spkState.leads
                : <SprinklerLeadModel>[];

            final isLoading = solarState is SolarLeadLoading ||
                spkState is SprinklerLeadLoading ||
                _materialLoading;

            final solarCubit = context.read<SolarLeadCubit>();
            final spkCubit = context.read<SprinklerLeadCubit>();

            final solarItems = solarLeads
                .where((l) => l.nextFollowupDate != null)
                .map(FollowupItem.fromSolar)
                .toList();
            final spkItems = spkLeads
                .where((l) => l.nextFollowupDate != null)
                .map(FollowupItem.fromSprinkler)
                .toList();

            // Today + Overdue only (upcoming exclude)
            final solarTabCount =
                solarItems.where((i) => i.daysFromToday <= 0).length;
            final spkTabCount =
                spkItems.where((i) => i.daysFromToday <= 0).length;

            _solarPage = solarCubit.currentPage;
            _solarTotalPages = solarCubit.totalPages;
            _sprinklerPage = spkCubit.currentPage;
            _sprinklerTotalPages = spkCubit.totalPages;

            // total items from cubit if available, else use list length
            _solarTotal = solarCubit.totalLeads;
            _sprinklerTotal = spkCubit.totalLeads;

            return Scaffold(
              backgroundColor:  AppColors.slate50,
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
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: const Text(
                  'Follow-ups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const AppSvgIcon(
                        AppSvgAssets.refreshCw,
                        color: Colors.white,
                      ),
                      onPressed: _load,
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _moduleTab,
                      labelColor: AppColors.blue,
                      unselectedLabelColor: AppColors.slate300,
                      indicatorColor: AppColors.blue,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      tabs: [
                        _ModuleTab(
                          label: 'Solar',
                          count: solarTabCount,
                          color: AppColors.amber,
                        ),
                        _ModuleTab(
                          label: 'Sprinkler',
                          count: spkTabCount,
                          color: AppColors.blue,
                        ),
                        _ModuleTab(
                          label: 'Material',
                          count: _materialTodayOverdueCount,
                          color: AppColors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blue,
                      ),
                    )
                  : TabBarView(
                      controller: _moduleTab,
                      children: [
                        // ── Solar ──────────────────────────────────────────
                        Column(
                          children: [
                            Expanded(
                              child: TabBody(
                                items: solarItems,
                                onRefresh: _load,
                              ),
                            ),
                            FollowupPagiantionBar(
                              currentPage: _solarPage,
                              totalPages: _solarTotalPages,
                              totalItems: _solarTotal,
                              onPageChanged: (p) => solarCubit.fetchPage(p),
                            ),
                          ],
                        ),
                        // ── Sprinkler ──────────────────────────────────────
                        Column(
                          children: [
                            Expanded(
                              child: TabBody(
                                items: spkItems,
                                onRefresh: _load,
                              ),
                            ),
                            FollowupPagiantionBar(
                              currentPage: _sprinklerPage,
                              totalPages: _sprinklerTotalPages,
                              totalItems: _sprinklerTotal,
                              onPageChanged: (p) => spkCubit.fetchPage(p),
                            ),
                          ],
                        ),
                        // ── Material ───────────────────────────────────────
                        MaterialTabBody(
                          items: _materialItems,
                          onRefresh: _load,
                          page: _materialPage,
                          totalPages: _materialTotalPages,
                          totalItems: _materialTotal,
                          onPageChanged: (p) =>
                              _loadMaterialFollowups(page: p),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

// ─── TabBody — search bar + inner "Today / Overdue" tabs ─────────────────────

class TabBody extends StatefulWidget {
  final List<FollowupItem> items;
  final VoidCallback onRefresh;

  const TabBody({required this.items, required this.onRefresh, super.key});

  @override
  State<TabBody> createState() => _TabBodyState();
}

class _TabBodyState extends State<TabBody> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final _searchC = TextEditingController();
  String _searchQuery = '';
  late TabController _innerTab;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
    _searchC.addListener(
      () => setState(() => _searchQuery = _searchC.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _innerTab.dispose();
    _searchC.dispose();
    super.dispose();
  }

  List<FollowupItem> get _searched {
    var list = widget.items;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((i) =>
              i.customerName.toLowerCase().contains(_searchQuery) ||
              i.phone.contains(_searchQuery))
          .toList();
    }
    list.sort((a, b) => a.nextFollowupDate.compareTo(b.nextFollowupDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searched;
    final todayItems = filtered.where((i) => i.daysFromToday == 0).toList();
    final overdueItems = filtered.where((i) => i.daysFromToday < 0).toList();

    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────────────
        Container(
          color: AppColors.slate50,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color:  AppColors.slate200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color:   AppColors.slate800.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchC,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate900,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search customers by name or phone…',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate400,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(10),
                  child: AppSvgIcon(
                    AppSvgAssets.search,
                    size: 18,
                    color: AppColors.slate300,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchC.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:   AppColors.slate100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const AppSvgIcon(
                            AppSvgAssets.x,
                            size: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        // ── Inner TabBar: Today | Overdue ────────────────────────────────────
        Container(
          color:   AppColors.slate50,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color:   AppColors.blue50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _innerTab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color:   AppColors.slate800.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              padding: const EdgeInsets.all(4),
              labelColor:   AppColors.slate900,
              unselectedLabelColor:   AppColors.slate300,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Today'),
                      const SizedBox(width: 6),
                      _InnerBadge(
                        count: todayItems.length,
                        activeColor:   AppColors.greenSuccess,
                        inactiveColor:   AppColors.slate300,
                        isActive: _innerTab.index == 0,
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Overdue'),
                      const SizedBox(width: 6),
                      _InnerBadge(
                        count: overdueItems.length,
                        activeColor:   AppColors.redError,
                        inactiveColor:   AppColors.slate300,
                        isActive: _innerTab.index == 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1, thickness: 1, color: AppColors.slate200),

        // ── Inner TabBarView ─────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [
              _FollowupTabContent(
                items: todayItems,
                emptyMessage: 'No follow-ups scheduled for today.',
                onRefresh: widget.onRefresh,
                apiService: _apiService,
              ),
              _FollowupTabContent(
                items: overdueItems,
                emptyMessage: 'No overdue follow-ups — all caught up!',
                onRefresh: widget.onRefresh,
                apiService: _apiService,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Inner badge chip ─────────────────────────────────────────────────────────

class _InnerBadge extends StatelessWidget {
  final int count;
  final Color activeColor;
  final Color inactiveColor;
  final bool isActive;

  const _InnerBadge({
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Tab content ──────────────────────────────────────────────────────────────

class _FollowupTabContent extends StatelessWidget {
  final List<FollowupItem> items;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final ApiService apiService;

  const _FollowupTabContent({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(message: emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minW =
              constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color:   AppColors.slate200),
                ),
                clipBehavior: Clip.antiAlias,
                child: _FollowupDataTable(
                  rows: items,
                  minWidth: minW,
                  onRefresh: onRefresh,
                  apiService: apiService,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Data table ───────────────────────────────────────────────────────────────

class _FollowupDataTable extends StatelessWidget {
  final List<FollowupItem> rows;
  final double minWidth;
  final VoidCallback onRefresh;
  final ApiService apiService;

  const _FollowupDataTable({
    required this.rows,
    required this.minWidth,
    required this.onRefresh,
    required this.apiService,
  });

  List<String> get _columns => const [
        'Customer',
        'Module',
        'Phone',
        'Address',
        'Next Follow-up',
        'Status',
        'Actions',
      ];

  @override
  Widget build(BuildContext context) {
    TableRow headerRow() => TableRow(
          decoration: BoxDecoration(
            color:   AppColors.blue100.withValues(alpha: 0.35),
          ),
          children: _columns
              .map(
                (col) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  child: Text(
                    col,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                ),
              )
              .toList(),
        );

    TableRow dataRow(FollowupItem item) => TableRow(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.slate200)),
          ),
          children: _buildCells(context, item)
              .map(
                (cellChild) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  child: cellChild,
                ),
              )
              .toList(),
        );

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.blueGrey.shade100),
                bottom: BorderSide(color: Colors.blueGrey.shade100),
              ),
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(2.0),
                2: FlexColumnWidth(1.3),
                3: FlexColumnWidth(2.5),
                4: FlexColumnWidth(1.7),
                5: FlexColumnWidth(1.4),
                6: FlexColumnWidth(1.8),
              },
              children: [headerRow(), ...rows.map(dataRow)],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCells(BuildContext context, FollowupItem item) {
    return [
      // Customer
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.customerName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          if (item.lastRemark != null && item.lastRemark!.isNotEmpty)
            SizedBox(
              width: 180,
              child: Text(
                item.lastRemark!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
            ),
        ],
      ),
      // Module
      _ModuleBadge(module: item.module),
      // Phone
      Text(item.phone,
          style:
              const TextStyle(fontSize: 12, color: AppColors.slate900)),
      // Address
      SizedBox(
        width: 180,
        child: Text(
          item.address.isEmpty ? '-' : item.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.slate700),
        ),
      ),
      // Next Follow-up
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd MMM yyyy')
                .format(item.nextFollowupDate.toLocal()),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate800,
            ),
          ),
          if (item.followupTime != null)
            Text(
              item.followupTime!,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
        ],
      ),
      // Status pill
      _StatusPill(item: item),
      // Actions
      Row(
        children: [
          _ActionIcon(
            svgAsset: AppSvgAssets.circleCheckBig,
            color:   AppColors.greenSuccess,
            tooltip: 'Mark done',
            onTap: () => _markDone(context, item),
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            svgAsset: AppSvgAssets.phone,
            color:   AppColors.blueAccent,
            tooltip: 'Call',
            onTap: () => _call(item.phone),
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            svgAsset: AppSvgAssets.messageSquarePlus,
            color:   AppColors.purple,
            tooltip: 'Add follow-up',
            onTap: () => _openAddFollowup(context, item),
          ),
        ],
      ),
    ];
  }

  Future<void> _markDone(BuildContext context, FollowupItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as done?'),
        content: Text(
            'Mark follow-up for "${item.customerName}" as completed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark Done')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (item.module == 'solar') {
      await context.read<SolarLeadCubit>().markFollowupDone(item.id);
    } else if (item.module == 'sprinkler') {
      await context.read<SprinklerLeadCubit>().markFollowupDone(item.id);
    } else {
      await apiService.markMaterialCustomerFollowupDone(item.id);
    }

    if (!context.mounted) return;
    onRefresh();
  }

  Future<void> _openAddFollowup(
      BuildContext context, FollowupItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFollowupScreen(
          leadId: item.id,
          module: item.module,
          customerName: item.customerName,
          currentNextDate: item.nextFollowupDate,
          materialAssignedToId: item.assignedToId,
        ),
      ),
    );
    if (result == true) onRefresh();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.42,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color:   AppColors.slate100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:   AppColors.slate200,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: AppSvgIcon(
                      AppSvgAssets.calendarCheck,
                      size: 32,
                      color: AppColors.slate300,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Module tab with colored dot ─────────────────────────────────────────────

class _ModuleTab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ModuleTab({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final FollowupItem item;
  const _StatusPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final days = item.daysFromToday;
    final String text;
    final Color color;

    if (days < 0) {
      text = '${-days}d overdue';
      color =   AppColors.redError;
    } else if (days == 0) {
      text = 'Today';
      color =   AppColors.greenSuccess;
    } else {
      text = 'In ${days}d';
      color =   AppColors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Action icon ──────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final String svgAsset;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.svgAsset,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppSvgIcon(svgAsset, size: 15, color: color),
        ),
      ),
    );
  }
}

// ─── Module badge ─────────────────────────────────────────────────────────────

class _ModuleBadge extends StatelessWidget {
  final String module;
  const _ModuleBadge({required this.module});

  @override
  Widget build(BuildContext context) {
    final isSolar = module == 'solar';
    final isSprinkler = module == 'sprinkler';

    final bgColor = isSolar
        ?   AppColors.yellowLight
        : isSprinkler
            ?   AppColors.blue100
            :   AppColors.greenLight;

    final textColor = isSolar
        ?  AppColors.blueDark
        : isSprinkler
            ?   AppColors.blueDark
            :   AppColors.greenDark;

    final label = isSolar ? 'Solar' : isSprinkler ? 'Sprinkler' : 'Material';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Pagination Bar ───────────────────────────────────────────────────────────
// Service Requests jaisa — "X results · Page N of N" + < 1 2 3 > purple style

class FollowupPagiantionBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  const FollowupPagiantionBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: "X results · Page N of N"
          Text(
            '$totalItems results  ·  Page $currentPage of $totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate500,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Right: < pages >
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PagArrowBtn(
                icon: Icons.chevron_left,
                enabled: currentPage > 1,
                onTap: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 4),
              ..._buildPageNumbers(),
              const SizedBox(width: 4),
              _PagArrowBtn(
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages,
                onTap: () => onPageChanged(currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    if (totalPages <= 0) {
      return [
        FollowupPagNumButton(page: 1, current: currentPage, onTap: onPageChanged),
      ];
    }

    final pages = <Widget>[];

    // Show at most 5 page buttons with ellipsis
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (start + 4).clamp(1, totalPages);
    start = (end - 4).clamp(1, totalPages);

    if (start > 1) {
      pages.add(FollowupPagNumButton(page: 1, current: currentPage, onTap: onPageChanged));
      if (start > 2) {
        pages.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.slate300, fontSize: 13)),
        ));
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(FollowupPagNumButton(page: i, current: currentPage, onTap: onPageChanged));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) {
        pages.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.slate300, fontSize: 13)),
        ));
      }
      pages.add(
          FollowupPagNumButton(page: totalPages, current: currentPage, onTap: onPageChanged));
    }

    return pages;
  }
}

class FollowupPagNumButton extends StatelessWidget {
  final int page;
  final int current;
  final ValueChanged<int> onTap;

  const FollowupPagNumButton({
    super.key,
    required this.page,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = page == current;
    return GestureDetector(
      onTap: isActive ? null : () => onTap(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ?  AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ?  AppColors.purple
                :  AppColors.slate200,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color:  AppColors.purple.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white :  AppColors.slate600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PagArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PagArrowBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color:  AppColors.slate200),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ?  AppColors.purple
              :  AppColors.slate300,
        ),
      ),
    );
  }
}


