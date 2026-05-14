// lib/screens/Dashboards/Admin_Dashboards/Dashboard/pending_payment.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';

// ─── Brand color aliases ──────────────────────────────────────────────────────
// ✅ Solar tab  = brand primary      #5B4FCF
// ✅ Sprinkler  = brand primaryLight #7B6FE0
const _kSolar      = AppColors.primary;       // was: LeadTheme.orange
const _kSprinkler  = AppColors.primaryLight;  // was: AppColors.cyan

// ─── Unified pending payment entry ───────────────────────────────────────────
class _PayEntry {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final String projectType;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String? paymentMode;
  final DateTime? dealDate;
  final String? teamName;
  final SolarLeadsModel? solarLead;
  final SprinklerLeadModel? sprinklerLead;

  const _PayEntry({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.projectType,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    this.paymentMode,
    this.dealDate,
    this.teamName,
    this.solarLead,
    this.sprinklerLead,
  });

  factory _PayEntry.fromSolar(SolarLeadsModel l) {
    final total = l.paymentSummary.totalAmount > 0
        ? l.paymentSummary.totalAmount
        : (l.finalAmount ?? l.totalAmount);
    final paid = l.paymentSummary.amountReceived > 0
        ? l.paymentSummary.amountReceived
        : (l.advancePayment ?? 0);
    final pending = l.paymentSummary.remainingBalance > 0
        ? l.paymentSummary.remainingBalance
        : (total - paid).clamp(0, double.infinity).toDouble();
    return _PayEntry(
      id: l.id, customerName: l.customerName, phone: l.mobile,
      address: l.address, projectType: 'Solar',
      totalAmount: total, paidAmount: paid, pendingAmount: pending,
      paymentMode: l.paymentMode,
      dealDate: l.dealData.closedAt ?? l.createdAt,
      teamName: l.installationTeam, solarLead: l,
    );
  }

  factory _PayEntry.fromSprinkler(SprinklerLeadModel l) {
    final total = l.paymentSummary.totalAmount > 0
        ? l.paymentSummary.totalAmount : l.totalAmount;
    final paid = l.paymentSummary.amountReceived > 0
        ? l.paymentSummary.amountReceived : (l.advancePayment ?? 0);
    final pending = l.paymentSummary.remainingBalance > 0
        ? l.paymentSummary.remainingBalance
        : (total - paid).clamp(0, double.infinity).toDouble();
    return _PayEntry(
      id: l.id, customerName: l.customerName, phone: l.phone,
      address: l.address, projectType: 'Sprinkler',
      totalAmount: total, paidAmount: paid, pendingAmount: pending,
      paymentMode: l.paymentMode,
      dealDate: l.dealData.closedAt ?? l.createdAt,
      teamName: l.effectiveInstallerName ?? l.installerName,
      sprinklerLead: l,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class AdminPendingPaymentPage extends StatefulWidget {
  final Color appBarColor;
  const AdminPendingPaymentPage({
    super.key,
    // ✅ default = brand primary — was AppColors.error (red)
    this.appBarColor = AppColors.primary,
  });

  @override
  State<AdminPendingPaymentPage> createState() => _State();
}

class _State extends State<AdminPendingPaymentPage>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _sort = 'Highest';

  static final _currency = NumberFormat.currency(
    locale: 'en_IN', symbol: '₹', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SolarLeadCubit>().fetchAllLeadsForPendingPayment();
      context.read<SprinklerLeadCubit>().fetchAllLeadsForPendingPayment();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_PayEntry> _solarEntries(List<SolarLeadsModel> all) => all
      .where((l) {
        if (l.isCompleted) return false;
        if (l.currentStep == SolarStep.projectCompleted) return false;
        final afterDeal = l.currentStep.index >= SolarStep.dealDone.index;
        if (!afterDeal) return false;
        final remaining = l.paymentSummary.remainingBalance > 0
            ? l.paymentSummary.remainingBalance
            : ((l.finalAmount ?? l.totalAmount) - (l.advancePayment ?? 0))
                  .clamp(0, double.infinity).toDouble();
        return remaining > 0;
      })
      .map(_PayEntry.fromSolar)
      .toList();

  List<_PayEntry> _sprinklerEntries(List<SprinklerLeadModel> all) => all
      .where((l) {
        if (l.isCompleted) return false;
        if (l.currentStep == SprinklerStep.projectCompleted) return false;
        final afterDeal = l.currentStep.index >= SprinklerStep.dealDone.index;
        if (!afterDeal) return false;
        final remaining = l.paymentSummary.remainingBalance > 0
            ? l.paymentSummary.remainingBalance
            : (l.totalAmount - (l.advancePayment ?? 0))
                  .clamp(0, double.infinity).toDouble();
        return remaining > 0;
      })
      .map(_PayEntry.fromSprinkler)
      .toList();

  List<_PayEntry> _applyFilters(List<_PayEntry> entries) {
    var list = entries.where((e) {
      final q = _search.toLowerCase();
      if (q.isEmpty) return true;
      return e.customerName.toLowerCase().contains(q) ||
          e.phone.contains(q) ||
          e.address.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case 'Highest':
        list.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount)); break;
      case 'Lowest':
        list.sort((a, b) => a.pendingAmount.compareTo(b.pendingAmount)); break;
      case 'Oldest':
        list.sort((a, b) => (a.dealDate ?? DateTime(2000))
            .compareTo(b.dealDate ?? DateTime(2000))); break;
      case 'Newest':
        list.sort((a, b) => (b.dealDate ?? DateTime(2000))
            .compareTo(a.dealDate ?? DateTime(2000))); break;
    }
    return list;
  }

  double _totalPending(List<_PayEntry> entries) =>
      entries.fold(0, (s, e) => s + e.pendingAmount);

  // ✅ Both tabs use brand purple shades — no more orange/cyan
  Color _tabColor() => _tab.index == 0 ? _kSolar : _kSprinkler;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (ctx, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (ctx2, spkState) {
            final solarAll = solarState is SolarLeadsLoaded
                ? solarState.leads : <SolarLeadsModel>[];
            final spkAll = spkState is SprinklerLeadsLoaded
                ? spkState.leads : <SprinklerLeadModel>[];

            final solarEntries  = _applyFilters(_solarEntries(solarAll));
            final spkEntries    = _applyFilters(_sprinklerEntries(spkAll));
            final allEntries    = _applyFilters([
              ..._solarEntries(solarAll),
              ..._sprinklerEntries(spkAll),
            ]);

            final loading =
                (solarState is SolarLeadLoading && solarAll.isEmpty) ||
                (spkState is SprinklerLeadLoading && spkAll.isEmpty);

            final totalPending = _totalPending(allEntries);
            final solarPending = _totalPending(solarEntries);
            final spkPending   = _totalPending(spkEntries);

            return Scaffold(
              // ✅ brand purple-tinted background — was AppColors.lightBg
              backgroundColor: AppColors.purple50,
              appBar: AppBar(
                // ✅ brand primary — was AppColors.error (red)
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: const AppSvgIcon(
                          AppSvgAssets.chevronLeft,
                          color: Colors.white, size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending Payments',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Deal closed — balance outstanding',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
                    onPressed: () {
                      context.read<SolarLeadCubit>().fetchAllLeadsForPendingPayment();
                      context.read<SprinklerLeadCubit>().fetchAllLeadsForPendingPayment();
                    },
                  ),
                ],
              ),
              body: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : Column(
                      children: [
                        // ── 1. TabBar ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 8, offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tab,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                // ✅ selected tab = brand purple shade
                                color: _tabColor(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: AppColors.textGray,
                              labelStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.all(4),
                              tabs: [
                                // ✅ Solar tab = _kSolar (primary)
                                _TabItem('Solar',     solarEntries.length, _kSolar),
                                // ✅ Sprinkler tab = _kSprinkler (primaryLight)
                                _TabItem('Sprinkler', spkEntries.length,   _kSprinkler),
                              ],
                            ),
                          ),
                        ),

                        // ── 2. Search + Sort ───────────────────────────
                        _SearchSortBar(
                          ctrl: _searchCtrl,
                          sort: _sort,
                          tabColor: _tabColor(),
                          onSortChanged: (v) => setState(() => _sort = v),
                        ),

                        // ── 3. Total Outstanding Banner ────────────────
                        _SummaryBanner(
                          total: totalPending,
                          solar: solarPending,
                          sprinkler: spkPending,
                          currency: _currency,
                        ),

                        // ── 4. Result count ────────────────────────────
                        Builder(
                          builder: (context) {
                            final shown = _tab.index == 0 ? solarEntries : spkEntries;
                            if (shown.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${shown.length} record${shown.length != 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // ── 5. Tab views ───────────────────────────────
                        Expanded(
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              _PayTable(
                                entries: solarEntries,
                                currency: _currency,
                                // ✅ brand primary
                                accentColor: _kSolar,
                                emptyMessage: 'No pending solar payments',
                                emptyIcon: AppSvgAssets.sun,
                              ),
                              _PayTable(
                                entries: spkEntries,
                                currency: _currency,
                                // ✅ brand primaryLight
                                accentColor: _kSprinkler,
                                emptyMessage: 'No pending sprinkler payments',
                                emptyIcon: AppSvgAssets.droplet,
                              ),
                            ],
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Payment Table
// ─────────────────────────────────────────────────────────────────────────────
class _PayTable extends StatelessWidget {
  final List<_PayEntry> entries;
  final NumberFormat currency;
  final Color accentColor;
  final String emptyMessage;
  final String emptyIcon;

  const _PayTable({
    required this.entries,
    required this.currency,
    required this.accentColor,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  Color _typeColor(String type) => type == 'Solar' ? _kSolar : _kSprinkler;

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy').format(d);
  }

  String _modeLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    const map = {
      'cash': 'Cash', 'bankTransfer': 'Bank Transfer',
      'cheque': 'Cheque', 'upi': 'UPI', 'loan': 'Loan',
    };
    return map[raw] ?? raw;
  }

  Widget _typeBadge(String type) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            type == 'Solar' ? AppSvgAssets.sun : AppSvgAssets.droplet,
            size: 10, color: color,
          ),
          const SizedBox(width: 3),
          Text(type,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _amtCell(String value, Color color, {bool bold = false}) => Text(
    value,
    style: TextStyle(
      fontSize: 12,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: color,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ empty icon = brand purple — was grey
            AppSvgIcon(emptyIcon, size: 56, color: AppColors.purple300),
            const SizedBox(height: 12),
            Text(emptyMessage,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGray,
              )),
            const SizedBox(height: 6),
            const Text('All payments are settled!',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      );
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const minWidth = 980.0;
    const rowStyle = TextStyle(fontSize: 12, color: AppColors.textDark);

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () async {
        context.read<SolarLeadCubit>().fetchAllLeadsForPendingPayment();
        context.read<SprinklerLeadCubit>().fetchAllLeadsForPendingPayment();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // ✅ brand purple border
            border: Border.all(color: AppColors.purple200),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: isDesktop
                  ? MediaQuery.sizeOf(context).width - 24 : minWidth,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 44,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 72,
                horizontalMargin: isDesktop ? 18 : 12,
                columnSpacing: isDesktop ? 20 : 14,
                // ✅ heading row = brand purple tint
                headingRowColor: WidgetStateProperty.all(AppColors.purple100),
                headingTextStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                // ✅ table borders = brand purple — was blueGrey
                border: const TableBorder(
                  horizontalInside: BorderSide(color: AppColors.purple200, width: 0.5),
                  bottom: BorderSide(color: AppColors.purple200),
                  top: BorderSide(color: AppColors.purple200),
                ),
                columns: const [
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Pending')),
                  DataColumn(label: Text('Mode')),
                  DataColumn(label: Text('Team')),
                  DataColumn(label: Text('Deal Date')),
                ],
                rows: entries.map((e) {
                  return DataRow(cells: [
                    DataCell(_typeBadge(e.projectType)),
                    DataCell(Text(e.customerName,
                      style: rowStyle.copyWith(fontWeight: FontWeight.w600))),
                    DataCell(Text(e.phone, style: rowStyle)),
                    DataCell(SizedBox(
                      width: isDesktop ? 180 : 150,
                      child: Text(e.address.isEmpty ? '—' : e.address,
                        overflow: TextOverflow.ellipsis, maxLines: 2,
                        style: rowStyle),
                    )),
                    // ✅ Total = textGray — was Colors.grey.shade700
                    DataCell(_amtCell(currency.format(e.totalAmount), AppColors.textGray)),
                    // ✅ Paid = primary — was Colors.green.shade600
                    DataCell(_amtCell(currency.format(e.paidAmount), AppColors.primary)),
                    // ✅ Pending = purple700 (darker) — was Colors.red.shade500
                    DataCell(_amtCell(currency.format(e.pendingAmount),
                        AppColors.purple700, bold: true)),
                    DataCell(Text(_modeLabel(e.paymentMode), style: rowStyle)),
                    DataCell(Text(
                      e.teamName?.isNotEmpty == true ? e.teamName! : '—',
                      style: rowStyle)),
                    DataCell(Text(_formatDate(e.dealDate),
                      style: rowStyle.copyWith(fontSize: 11))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Summary Banner
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final double total, solar, sprinkler;
  final NumberFormat currency;
  const _SummaryBanner({
    required this.total, required this.solar,
    required this.sprinkler, required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ✅ brand gradient primary → primaryDark — was pink500/pinkAccent
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Outstanding',
            style: TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(currency.format(total),
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
            )),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _BannerStat('☀ Solar', currency.format(solar))),
              Container(width: 1, height: 28, color: Colors.white24),
              Expanded(child: _BannerStat('💧 Sprinkler', currency.format(sprinkler))),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label, value;
  const _BannerStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      const SizedBox(height: 2),
      Text(value,
        style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
        )),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search + Sort Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchSortBar extends StatelessWidget {
  final TextEditingController ctrl;
  final String sort;
  final Color tabColor;
  final ValueChanged<String> onSortChanged;
  const _SearchSortBar({
    required this.ctrl, required this.sort,
    required this.tabColor, required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                // ✅ brand purple border — was Colors.grey.shade200
                border: Border.all(color: AppColors.purple200),
              ),
              child: TextField(
                controller: ctrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search name / phone / address',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AppSvgIcon(AppSvgAssets.search, size: 16, color: tabColor),
                  ),
                  suffixIcon: ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const AppSvgIcon(AppSvgAssets.x, size: 14),
                          onPressed: ctrl.clear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
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
                // ✅ brand purple border
                border: Border.all(color: AppColors.purple200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sort,
                  isExpanded: true,
                  isDense: true,
                  icon: AppSvgIcon(AppSvgAssets.chevronDown, size: 16, color: tabColor),
                  style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                  items: ['Highest', 'Lowest', 'Newest', 'Oldest']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) { if (v != null) onSortChanged(v); },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab item helper
// ─────────────────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TabItem(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Tab(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
              style: const TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700,
              )),
          ),
        ],
      ],
    ),
  );
}