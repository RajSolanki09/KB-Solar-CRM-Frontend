import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'add_followup_screen.dart';

class _FollowupItem {
  final String id;
  final String module;
  final String customerName;
  final String phone;
  final String address;
  final String stageName;
  final String? lastRemark;
  final DateTime nextFollowupDate;
  final String? assignedToId;

  _FollowupItem({
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

  factory _FollowupItem.fromSolar(SolarLeadsModel l) => _FollowupItem(
    id: l.id,
    module: 'solar',
    customerName: l.customerName,
    phone: l.mobile,
    address: l.address,
    stageName: l.status,
    lastRemark: l.lastRemark,
    nextFollowupDate: l.nextFollowupDate!,
  );

  factory _FollowupItem.fromSprinkler(SprinklerLeadModel l) => _FollowupItem(
    id: l.id,
    module: 'sprinkler',
    customerName: l.customerName,
    phone: l.phone,
    address: l.address,
    stageName: l.status,
    lastRemark: l.lastRemark,
    nextFollowupDate: l.nextFollowupDate!,
  );

  factory _FollowupItem.fromMaterialCustomer(Map<String, dynamic> customer) {
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
      final idValue = (assignedToRaw['_id'] ?? assignedToRaw['id'] ?? '')
          .toString()
          .trim();
      assignedToId = idValue.isEmpty ? null : idValue;
    } else {
      final idValue = (assignedToRaw ?? '').toString().trim();
      assignedToId = idValue.isEmpty ? null : idValue;
    }

    return _FollowupItem(
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

class FollowupListScreen extends StatefulWidget {
  final Color appBarColor;
  const FollowupListScreen({
    super.key,
    this.appBarColor = AppColors.primaryLight,
  });

  @override
  State<FollowupListScreen> createState() => _FollowupListScreenState();
}

class _FollowupListScreenState extends State<FollowupListScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _moduleTab;
  bool _materialLoading = true;
  List<_FollowupItem> _materialItems = const [];

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
    _loadMaterialFollowups();
  }

  Future<void> _loadMaterialFollowups() async {
    if (mounted) {
      setState(() => _materialLoading = true);
    }
    try {
      final customers = await _apiService.getMaterialCustomers();
      final materialItems = customers
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
          .map(_FollowupItem.fromMaterialCustomer)
          .toList();

      if (!mounted) return;
      setState(() {
        _materialItems = materialItems;
        _materialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _materialItems = const [];
        _materialLoading = false;
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

            final isLoading =
                solarState is SolarLeadLoading ||
                spkState is SprinklerLeadLoading ||
                _materialLoading;

            final solarItems = solarLeads
                .where((l) => l.nextFollowupDate != null)
                .map(_FollowupItem.fromSolar)
                .toList();

            final spkItems = spkLeads
                .where((l) => l.nextFollowupDate != null)
                .map(_FollowupItem.fromSprinkler)
                .toList();

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
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: const Text(
                  'Follow-ups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
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
                          color: AppColors.surface,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const AppSvgIcon(
                        AppSvgAssets.refreshCw,
                        color: AppColors.surface,
                      ),
                      onPressed: _load,
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: AppColors.surface,
                    child: TabBar(
                      controller: _moduleTab,
                      labelColor:  AppColors.primary,
                      unselectedLabelColor:  AppColors.textLight,
                      indicatorColor:  AppColors.primary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(text: 'Solar (${solarItems.length})'),
                        Tab(text: 'Sprinkler (${spkItems.length})'),
                        Tab(text: 'Material (${_materialItems.length})'),
                      ],
                    ),
                  ),
                ),
              ),
              body: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : TabBarView(
                      controller: _moduleTab,
                      children: [
                        _TabBody(items: solarItems, onRefresh: _load),
                        _TabBody(items: spkItems, onRefresh: _load),
                        _TabBody(items: _materialItems, onRefresh: _load),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _TabBody extends StatefulWidget {
  final List<_FollowupItem> items;
  final VoidCallback onRefresh;

  const _TabBody({required this.items, required this.onRefresh});

  @override
  State<_TabBody> createState() => _TabBodyState();
}

class _TabBodyState extends State<_TabBody> {
  final ApiService _apiService = ApiService();
  final _searchC = TextEditingController();
  String _searchQuery = '';
  bool _showOtherLeads = false;

  @override
  void initState() {
    super.initState();
    _searchC.addListener(
      () => setState(() => _searchQuery = _searchC.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<_FollowupItem> get _searched {
    var list = widget.items;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (i) =>
                i.customerName.toLowerCase().contains(_searchQuery) ||
                i.phone.contains(_searchQuery),
          )
          .toList();
    }

    list.sort((a, b) => a.nextFollowupDate.compareTo(b.nextFollowupDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searched;
    if (filtered.isEmpty) {
      return _EmptyState(query: _searchQuery);
    }

    final upcoming7Days = filtered
        .where((item) => item.daysFromToday >= 0 && item.daysFromToday <= 7)
        .toList();
    final otherLeads = filtered
        .where((item) => item.daysFromToday < 0 || item.daysFromToday > 7)
        .toList();

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color:  AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchC,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const AppSvgIcon(
                          AppSvgAssets.search,
                          size: 18,
                          color: AppColors.textLight,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchC.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const AppSvgIcon(
                                AppSvgAssets.x,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minW = constraints.maxWidth < 980
                    ? 980.0
                    : constraints.maxWidth;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: [
                    _TableSection<_FollowupItem>(
                      title: 'Upcoming 7 Days',
                      subtitle: 'Leads scheduled from today to the next 7 days',
                      rows: upcoming7Days,
                      minWidth: minW,
                      showEmptyMessage: true,
                      rowBuilder: (item) => _followupRow(
                        context: context,
                        item: item,
                        onRefresh: widget.onRefresh,
                      ),
                      columnBuilder: _followupColumns,
                    ),
                    const SizedBox(height: 12),
                    _CollapsibleTableSection<_FollowupItem>(
                      title: 'Other Leads',
                      subtitle: 'Overdue and beyond next 7 days',
                      rows: otherLeads,
                      minWidth: minW,
                      initiallyExpanded: _showOtherLeads,
                      onExpansionChanged: (v) {
                        if (mounted) {
                          setState(() => _showOtherLeads = v);
                        }
                      },
                      rowBuilder: (item) => _followupRow(
                        context: context,
                        item: item,
                        onRefresh: widget.onRefresh,
                      ),
                      columnBuilder: _followupColumns,
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

  List<String> _followupColumns() => const [
    'Customer',
    'Module',
    'Phone',
    'Address',
    'Next Follow-up',
    'Status',
    'Actions',
  ];

  List<Widget> _followupRow({
    required BuildContext context,
    required _FollowupItem item,
    required VoidCallback onRefresh,
  }) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.customerName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (item.lastRemark != null && item.lastRemark!.isNotEmpty)
            SizedBox(
              width: 180,
              child: Text(
                item.lastRemark!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textGray),
              ),
            ),
        ],
      ),
      Row(children: [_ModuleBadge(module: item.module)]),
      Text(
        item.phone,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
      ),
      SizedBox(
        width: 180,
        child: Text(
          item.address.isEmpty ? '-' : item.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textGray),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd MMM yyyy').format(item.nextFollowupDate.toLocal()),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (item.followupTime != null)
            Text(
              item.followupTime!,
              style: const TextStyle(fontSize: 11, color: AppColors.textGray),
            ),
        ],
      ),
      _StatusPill(item: item),
      Row(
        children: [
          _ActionIcon(
            svgAsset: AppSvgAssets.circleCheckBig,
            color:  AppColors.success,
            tooltip: 'Mark done',
            onTap: () => _markDone(context, item, onRefresh),
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            svgAsset: AppSvgAssets.phone,
            color: const Color(0xff0284C7),
            tooltip: 'Call',
            onTap: () => _call(item.phone),
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            svgAsset: AppSvgAssets.messageSquarePlus,
            color:  AppColors.primary,
            tooltip: 'Add follow-up',
            onTap: () => _openAddFollowup(context, item, onRefresh),
          ),
        ],
      ),
    ];
  }

  Future<void> _markDone(
    BuildContext context,
    _FollowupItem item,
    VoidCallback onRefresh,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as done?'),
        content: Text(
          'Mark follow-up for "${item.customerName}" as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Done'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (item.module == 'solar') {
      await context.read<SolarLeadCubit>().markFollowupDone(item.id);
    } else if (item.module == 'sprinkler') {
      await context.read<SprinklerLeadCubit>().markFollowupDone(item.id);
    } else {
      await _apiService.markMaterialCustomerFollowupDone(item.id);
    }

    if (!mounted) return;
    onRefresh();
  }

  Future<void> _openAddFollowup(
    BuildContext context,
    _FollowupItem item,
    VoidCallback onRefresh,
  ) async {
    final uiResult = await Navigator.push(
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

    final result = uiResult == true;

    if (result) {
      onRefresh();
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _TableSection<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> rows;
  final double minWidth;
  final bool showEmptyMessage;
  final List<Widget> Function(T) rowBuilder;
  final List<String> Function() columnBuilder;

  const _TableSection({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.minWidth,
    required this.rowBuilder,
    required this.columnBuilder,
    this.showEmptyMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.divider),
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
                  '$title (${rows.length})',
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
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty && showEmptyMessage)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No leads in this section.',
                style: TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            )
          else if (rows.isNotEmpty)
            _FollowupDataTable<T>(
              rows: rows,
              minWidth: minWidth,
              rowBuilder: rowBuilder,
              columnBuilder: columnBuilder,
            ),
        ],
      ),
    );
  }
}

class _CollapsibleTableSection<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> rows;
  final double minWidth;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> Function(T) rowBuilder;
  final List<String> Function() columnBuilder;

  const _CollapsibleTableSection({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.minWidth,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.rowBuilder,
    required this.columnBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onExpansionChanged(!initiallyExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title (${rows.length})',
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
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: initiallyExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: AppSvgIcon(
                      AppSvgAssets.chevronDown,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (initiallyExpanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No leads in this section.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                ),
              )
            else
              _FollowupDataTable<T>(
                rows: rows,
                minWidth: minWidth,
                rowBuilder: rowBuilder,
                columnBuilder: columnBuilder,
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _FollowupDataTable<T> extends StatelessWidget {
  final List<T> rows;
  final double minWidth;
  final List<Widget> Function(T) rowBuilder;
  final List<String> Function() columnBuilder;

  const _FollowupDataTable({
    required this.rows,
    required this.minWidth,
    required this.rowBuilder,
    required this.columnBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final headers = columnBuilder();
    final builtRows = rows.map(rowBuilder).toList();

    TableRow _headerRow() {
      return TableRow(
        decoration: BoxDecoration(
          color: const Color(0xffDBEAFE).withValues(alpha: 0.35),
        ),
        children: headers
            .map(
              (colTitle) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Text(
                  colTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    TableRow _dataRow(List<Widget> rowCells) {
      return TableRow(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        children: rowCells
            .map(
              (cellChild) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: cellChild,
              ),
            )
            .toList(),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.primary),
                bottom: BorderSide(color: AppColors.primary),
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
              children: [_headerRow(), ...builtRows.map(_dataRow)],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _FollowupItem item;
  const _StatusPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final days = item.daysFromToday;
    final String text;
    final Color color;

    if (days < 0) {
      text = '${-days} day${-days == 1 ? '' : 's'} overdue';
      color =  AppColors.error;
    } else if (days == 0) {
      text = 'Today';
      color =  AppColors.success;
    } else {
      text = 'In $days day${days == 1 ? '' : 's'}';
      color =  AppColors.primary;
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

class _ModuleBadge extends StatelessWidget {
  final String module;
  const _ModuleBadge({required this.module});

  @override
  Widget build(BuildContext context) {
    final isSolar = module == 'solar';
    final isSprinkler = module == 'sprinkler';

    final bgColor = isSolar
        ? const Color(0xffFEF9C3)
        : isSprinkler
        ? const Color(0xffDBEAFE)
        :  AppColors.successLight;

    final textColor = isSolar
        ? const Color(0xff854D0E)
        : isSprinkler
        ? const Color(0xff1D4ED8)
        :  AppColors.success;

    final label = isSolar
        ? 'Solar'
        : isSprinkler
        ? 'Sprinkler'
        : 'Material';

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

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final String title = query.isNotEmpty
        ? 'No results for "$query"'
        : 'No follow-ups yet';
    final String sub = query.isNotEmpty
        ? 'Try a different name or phone number.'
        : 'Follow-ups will appear here once scheduled.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            AppSvgAssets.calendarCheck,
            size: 44,
            color: AppColors.divider,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
