import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Revenue/revenue_cubit.dart';
import 'package:solar_project/Cubits/Revenue/revenue_state.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Models/service_request_model.dart';

// ─── Color tokens ─────────────────────────────────────────────────────────────
class _C {
  static const brand = AppColors.redVariant1;
  static const bg = AppColors.other4;
  static const surface = AppColors.veryLight7;
  static const border = AppColors.bgLight5;
  static const divider = AppColors.other2;
  static const ink1 = AppColors.gray800Custom;
  static const ink2 = AppColors.gray700Custom;
  static const ink3 = AppColors.gray600Custom;
  static const ink4 = AppColors.gray500Custom;
  static const solar = AppColors.amber;
  static const sprinkler = AppColors.cyan;
  static const service = AppColors.success;
}

// ─── Period enum ──────────────────────────────────────────────────────────────
enum _Period { today, week, month, all }

extension _PLabel on _Period {
  String get label => const {
    _Period.today: 'Today',
    _Period.week: 'This Week',
    _Period.month: 'This Month',
    _Period.all: 'All Time',
  }[this]!;
}

// ─────────────────────────────────────────────────────────────────────────────
class RevenueSummary extends StatefulWidget {
  const RevenueSummary({super.key});
  @override
  State<RevenueSummary> createState() => _State();
}

class _State extends State<RevenueSummary> with TickerProviderStateMixin {
  _Period _period = _Period.month;
  DateTime? _selectedDate;
  late AnimationController _anim;
  late Animation<double> _prog;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _prog = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolarLeadCubit>().fetchAllLeads();
      context.read<SprinklerLeadCubit>().fetchAllLeads();
      context.read<ServiceLeadCubit>().fetchAllServices();
      context.read<RevenueCubit>().fetchRevenue();
      _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _refresh() {
    _anim.reset();
    context.read<SolarLeadCubit>().fetchAllLeads();
    context.read<SprinklerLeadCubit>().fetchAllLeads();
    context.read<ServiceLeadCubit>().fetchAllServices();
    context.read<RevenueCubit>().fetchRevenue();
    _anim.forward();
  }

  bool _inPeriod(DateTime d) {
    if (_selectedDate != null) {
      return d.year == _selectedDate!.year &&
          d.month == _selectedDate!.month &&
          d.day == _selectedDate!.day;
    }
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case _Period.week:
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case _Period.month:
        return d.year == now.year && d.month == now.month;
      case _Period.all:
        return true;
    }
  }

  void _setPeriod(_Period p) {
    setState(() {
      _period = p;
      _selectedDate = null;
    });
    _anim.reset();
    _anim.forward();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _C.brand)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _anim.reset();
      _anim.forward();
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    _anim.reset();
    _anim.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: BlocBuilder<SolarLeadCubit, SolarLeadState>(
        builder: (_, ss) => BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (_, ps) => BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
            builder: (_, vs) => BlocBuilder<RevenueCubit, RevenueState>(
              builder: (_, revState) {
                final allSolar = ss is SolarLeadsLoaded
                    ? ss.leads
                    : <SolarLeadsModel>[];
                final allSpk = ps is SprinklerLeadsLoaded
                    ? ps.leads
                    : <SprinklerLeadModel>[];
                final allSvc = vs is ServiceLeadsLoaded
                    ? vs.services
                    : <ServiceRequestModel>[];

                final loading =
                    (ss is SolarLeadLoading && allSolar.isEmpty) ||
                    (ps is SprinklerLeadLoading && allSpk.isEmpty) ||
                    (vs is ServiceLeadLoading && allSvc.isEmpty);

                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _C.brand,
                      strokeWidth: 2,
                    ),
                  );
                }

                final solar = allSolar
                    .where((l) => _inPeriod(l.createdAt))
                    .toList();
                final spk = allSpk
                    .where((l) => _inPeriod(l.createdAt))
                    .toList();
                final svc = allSvc
                    .where((s) => _inPeriod(s.createdAt))
                    .toList();

                return AnimatedBuilder(
                  animation: _prog,
                  builder: (_, __) => _Body(
                    solar: solar,
                    spk: spk,
                    svc: svc,
                    period: _period,
                    progress: _prog.value,
                    onPeriod: _setPeriod,
                    revState: revState,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _C.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: Navigator.canPop(context)
        ? Padding(
            padding: const EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _C.border, width: 1.5),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: _C.brand,
                  size: 20,
                ),
              ),
            ),
          )
        : null,
    title: const Text(
      'Revenue Summary',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        color: _C.brand,
        letterSpacing: -0.3,
      ),
    ),
    actions: [
      if (_selectedDate != null)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _TopbarIconBtn(
            onTap: _clearDate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, size: 11, color: _C.brand),
                const SizedBox(width: 3),
                Text(
                  '${_selectedDate!.day}/${_selectedDate!.month}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _C.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            rounded: false,
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _TopbarIconBtn(
            onTap: _pickDate,
            child: const AppSvgIcon(
              AppSvgAssets.calendarDays,
              color: _C.brand,
              size: 14,
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _TopbarIconBtn(
          onTap: _refresh,
          child: const AppSvgIcon(
            AppSvgAssets.refreshCw,
            color: _C.brand,
            size: 14,
          ),
        ),
      ),
    ],
  );
}

// ─── Topbar icon button ───────────────────────────────────────────────────────
class _TopbarIconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool rounded;
  const _TopbarIconBtn({
    required this.child,
    required this.onTap,
    this.rounded = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: rounded ? 32 : null,
      height: 32,
      padding: rounded ? null : const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _C.border, width: 1.5),
      ),
      child: Center(child: child),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final List<SolarLeadsModel> solar;
  final List<SprinklerLeadModel> spk;
  final List<ServiceRequestModel> svc;
  final _Period period;
  final double progress;
  final ValueChanged<_Period> onPeriod;
  final RevenueState revState;

  const _Body({
    required this.solar,
    required this.spk,
    required this.svc,
    required this.period,
    required this.progress,
    required this.onPeriod,
    required this.revState,
  });

  static String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // Solar metrics
    final sTotal = solar.length;
    final sVisited = solar
        .where((l) => l.currentStep.index >= SolarStep.technicalVisit.index)
        .length;
    final sQuote = solar
        .where((l) => l.currentStep.index >= SolarStep.quotation.index)
        .length;
    final sDeals = solar
        .where((l) => l.currentStep.index >= SolarStep.dealDone.index)
        .length;
    final sInstalled = solar
        .where((l) => l.currentStep.index >= SolarStep.installation.index)
        .length;
    final sCompleted = solar.where((l) => l.isCompleted).length;

    // Sprinkler metrics
    final pTotal = spk.length;
    final pVisited = spk
        .where((l) => l.currentStep.index >= SprinklerStep.siteVisit.index)
        .length;
    final pQuote = spk
        .where((l) => l.currentStep.index >= SprinklerStep.quotation.index)
        .length;
    final pDeals = spk
        .where((l) => l.currentStep.index >= SprinklerStep.dealDone.index)
        .length;
    final pInstalled = spk
        .where(
          (l) =>
              l.currentStep.index >= SprinklerStep.installationAssigned.index,
        )
        .length;
    final pCompleted = spk.where((l) => l.isCompleted).length;

    // Revenue from cubit
    final sRevenue = revState is RevenueLoaded
        ? (revState as RevenueLoaded).displaySolar
        : 0.0;
    final pRevenue = revState is RevenueLoaded
        ? (revState as RevenueLoaded).displaySprinkler
        : 0.0;
    final svRevenue = revState is RevenueLoaded
        ? (revState as RevenueLoaded).displayService
        : 0.0;
    final totalRev = revState is RevenueLoaded
        ? (revState as RevenueLoaded).displayTotal
        : 0.0;
    final totalPending = revState is RevenueLoaded
        ? (revState as RevenueLoaded).displayPending
        : 0.0;

    final sPending = solar.fold<double>(
      0,
      (a, l) => a + l.pendingAmount.clamp(0, double.infinity),
    );
    final pPending = spk.fold<double>(
      0,
      (a, l) => a + l.pendingAmount.clamp(0, double.infinity),
    );
    final svPending = svc.fold<double>(
      0,
      (a, s) => a + s.remaining.clamp(0, double.infinity),
    );

    final totalCollect = totalRev - totalPending;
    final payRate = totalRev > 0 ? totalCollect / totalRev : 0.0;

    final now = DateTime.now();
    final daily7 = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return solar.where((l) => _sameDay(l.createdAt, day)).length +
          spk.where((l) => _sameDay(l.createdAt, day)).length;
    });
    final maxD = daily7.isEmpty ? 1.0 : daily7.reduce(math.max).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 48),
      children: [
        // Period chips
        _PeriodChips(period: period, onPeriod: onPeriod),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              _RevenueHero(
                total: totalRev,
                collected: totalCollect,
                pending: totalPending,
                payRate: payRate,
                progress: progress,
                fmt: _fmt,
              ),
              const SizedBox(height: 20),

              // Section label
              _SectionLabel('Pipeline'),
              const SizedBox(height: 10),

              // Solar pipeline
              _PipelineCard(
                emoji: '☀️',
                title: 'Solar Pipeline',
                accentColor: _C.solar,
                stages: [
                  _S('New Lead', sTotal),
                  _S('Visited', sVisited),
                  _S('Quotation', sQuote),
                  _S('Deal', sDeals),
                  _S('Installed', sInstalled),
                  _S('Completed', sCompleted),
                ],
                total: sTotal,
                progress: progress,
              ),
              const SizedBox(height: 12),

              // Sprinkler pipeline
              _PipelineCard(
                emoji: '💧',
                title: 'Sprinkler Pipeline',
                accentColor: _C.sprinkler,
                stages: [
                  _S('New Lead', pTotal),
                  _S('Site Visit', pVisited),
                  _S('Quotation', pQuote),
                  _S('Deal', pDeals),
                  _S('Installed', pInstalled),
                  _S('Completed', pCompleted),
                ],
                total: pTotal,
                progress: progress,
              ),
              const SizedBox(height: 20),

              _SectionLabel('Analytics'),
              const SizedBox(height: 10),

              // Bar chart
              _SurfaceCard(
                emoji: '📈',
                title: 'New Leads — Last 7 Days',
                child: _BarChart(
                  daily: daily7,
                  maxVal: maxD,
                  progress: progress,
                ),
              ),
              const SizedBox(height: 12),

              // Revenue by source
              _SurfaceCard(
                emoji: '📊',
                title: 'Revenue by Source',
                child: Column(
                  children: [
                    _RevBar(
                      '☀️  Solar',
                      sRevenue,
                      totalRev,
                      _C.solar,
                      _fmt,
                      progress,
                    ),
                    const SizedBox(height: 10),
                    _RevBar(
                      '💧  Sprinkler',
                      pRevenue,
                      totalRev,
                      _C.sprinkler,
                      _fmt,
                      progress,
                    ),
                    const SizedBox(height: 10),
                    _RevBar(
                      '🔧  Service',
                      svRevenue,
                      totalRev,
                      _C.service,
                      _fmt,
                      progress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment collection
              _SurfaceCard(
                emoji: '₹',
                emojiColor:   AppColors.other5,
                title: 'Payment Collection',
                child: Column(
                  children: [
                    _CollectRow(
                      'Solar',
                      sRevenue - sPending,
                      sRevenue,
                      _C.solar,
                      progress,
                    ),
                    const SizedBox(height: 10),
                    _CollectRow(
                      'Sprinkler',
                      pRevenue - pPending,
                      pRevenue,
                      _C.sprinkler,
                      progress,
                    ),
                    const SizedBox(height: 10),
                    _CollectRow(
                      'Service',
                      svRevenue - svPending,
                      svRevenue,
                      _C.service,
                      progress,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 2),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: _C.ink4,
      ),
    ),
  );
}

// ─── Period chips ─────────────────────────────────────────────────────────────
class _PeriodChips extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onPeriod;
  const _PeriodChips({required this.period, required this.onPeriod});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: _Period.values.map((p) {
        final sel = p == period;
        return GestureDetector(
          onTap: () => onPeriod(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _C.brand : _C.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: sel ? _C.brand : _C.border, width: 1.5),
            ),
            child: Text(
              p.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? Colors.white : _C.ink2,
                letterSpacing: sel ? -0.1 : 0,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

// ─── Revenue hero card ────────────────────────────────────────────────────────
class _RevenueHero extends StatelessWidget {
  final double total, collected, pending, payRate, progress;
  final String Function(double) fmt;
  const _RevenueHero({
    required this.total,
    required this.collected,
    required this.pending,
    required this.payRate,
    required this.progress,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.redVariant1, AppColors.redVariant2, AppColors.redVariant3],
        stops: [0, 0.55, 1],
      ),
    ),
    child: Stack(
      children: [
        // Decorative circles
        Positioned(
          top: -24,
          right: -24,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -16,
          right: 40,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TOTAL BUSINESS REVENUE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white60,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                fmt(v),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  FractionallySizedBox(
                    widthFactor: (payRate * progress).clamp(0.0, 1.0),
                    child: Container(height: 4, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _HeroPill(
                  label: 'Collected',
                  value: fmt(collected),
                  isWarn: false,
                ),
                const SizedBox(width: 10),
                _HeroPill(label: 'Pending', value: fmt(pending), isWarn: true),
                const Spacer(),
                Text(
                  '${(payRate * 100).toStringAsFixed(1)}% collected',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroPill extends StatelessWidget {
  final String label, value;
  final bool isWarn;
  const _HeroPill({
    required this.label,
    required this.value,
    required this.isWarn,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isWarn
          ? Colors.orange.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isWarn ?   AppColors.bgOther6 : Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ─── Pipeline card ────────────────────────────────────────────────────────────
class _S {
  final String label;
  final int count;
  const _S(this.label, this.count);
}

class _PipelineCard extends StatelessWidget {
  final String emoji, title;
  final Color accentColor;
  final List<_S> stages;
  final int total;
  final double progress;

  const _PipelineCard({
    required this.emoji,
    required this.title,
    required this.accentColor,
    required this.stages,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    emoji: emoji,
    title: title,
    child: total == 0
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No leads for this period',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          )
        : Column(
            children: stages.map((s) {
              final pct = total > 0 ? s.count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        s.label,
                        style: const TextStyle(fontSize: 11, color: _C.ink3),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color:   AppColors.other3,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (pct * progress).clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${s.count}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
  );
}

// ─── Bar chart ────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<int> daily;
  final double maxVal, progress;
  const _BarChart({
    required this.daily,
    required this.maxVal,
    required this.progress,
  });

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SizedBox(
      height: 108,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final val = daily[i];
          final h = maxVal > 0 ? (val / maxVal) * 64 * progress : 0.0;
          final isTd = i == 6;
          final color = isTd ? _C.brand : _C.brand.withValues(alpha: 0.18);
          final tc = isTd ? _C.brand : _C.ink4;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 14,
                  child: Text(
                    val > 0 ? '$val' : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: tc,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  height: h.clamp(3.0, 64.0),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _days[day.weekday - 1],
                  style: TextStyle(fontSize: 9, color: tc),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Revenue bar ──────────────────────────────────────────────────────────────
class _RevBar extends StatelessWidget {
  final String label;
  final double value, total, progress;
  final Color color;
  final String Function(double) fmt;
  const _RevBar(
    this.label,
    this.value,
    this.total,
    this.color,
    this.fmt,
    this.progress,
  );

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _C.ink2),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color:   AppColors.other3,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (pct * progress).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            fmt(value),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Collection row ───────────────────────────────────────────────────────────
class _CollectRow extends StatelessWidget {
  final String label;
  final double collected, total, progress;
  final Color color;
  const _CollectRow(
    this.label,
    this.collected,
    this.total,
    this.color,
    this.progress,
  );

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? collected / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _C.ink2),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color:   AppColors.other3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (pct * progress).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Surface card wrapper ─────────────────────────────────────────────────────
class _SurfaceCard extends StatelessWidget {
  final String emoji, title;
  final Color emojiColor;
  final Widget child;
  const _SurfaceCard({
    required this.emoji,
    required this.title,
    required this.child,
    this.emojiColor =   AppColors.other1,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: emojiColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.ink1,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: _C.divider),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}








