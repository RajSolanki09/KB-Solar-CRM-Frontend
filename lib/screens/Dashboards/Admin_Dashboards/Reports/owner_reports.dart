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
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/Helper/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
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
class OwnerReportsPage extends StatefulWidget {
  const OwnerReportsPage({super.key});
  @override
  State<OwnerReportsPage> createState() => _State();
}

class _State extends State<OwnerReportsPage> with TickerProviderStateMixin {
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

    // FIX: mounted check + try/catch added to prevent
    // "_elements.contains(element) is not true" assertion.
    // This fires when the postFrameCallback runs after the widget's element
    // has shifted in the tree during navigation transitions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchAll();
      _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Safe fetch — always guard with mounted + try/catch before calling
  /// context.read<>() because this screen is pushed without BlocProvider.value
  /// wrappers (unlike the payment/installation screens). The cubits are
  /// inherited from the root provider tree, so a context.read<>() call after
  /// an async gap or navigation transition can find the element detached.
  void _fetchAll() {
    if (!mounted) return;
    try {
      context.read<SolarLeadCubit>().fetchAllLeads();
      context.read<SprinklerLeadCubit>().fetchAllLeads();
      context.read<ServiceLeadCubit>().fetchAllServices();
      context.read<RevenueCubit>().fetchRevenue();
    } catch (_) {
      // Swallow ProviderNotFoundException if context leaves the tree.
    }
  }

  void _refresh() {
    if (!mounted) return;
    _anim.reset();
    _fetchAll();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent2)),
          child: child!,
        );
      },
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
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 164, 78, 78),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: AppColors.accent2,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        foregroundColor: Colors.black,
        title: const Text(
          'Revenue Summary',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.accent2),
          ),
        actions: [
          if (_selectedDate != null)
            TextButton.icon(
              onPressed: _clearDate,
              icon: const Icon(Icons.close, size: 14, color: AppColors.accent2),
              label: Text(
                '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accent2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              icon: const AppSvgIcon(
                AppSvgAssets.calendarDays,
                color: AppColors.accent2,
              ),
              onPressed: _pickDate,
              tooltip: 'Filter by date',
            ),
          IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.refreshCw,
              color: AppColors.accent2,
            ),
            onPressed: _refresh,
          ),
        ],
      ),
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
                      color: AppColors.accent2,
                    ),
                  );
                }

                final solar =
                    allSolar.where((l) => _inPeriod(l.createdAt)).toList();
                final spk =
                    allSpk.where((l) => _inPeriod(l.createdAt)).toList();
                final svc =
                    allSvc.where((s) => _inPeriod(s.createdAt)).toList();

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
}

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

  static String _fmtRev(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // ── Solar metrics ─────────────────────────────────────────────────────
    final sTotal = solar.length;
    final sDeals = solar
        .where((l) => l.currentStep.index >= SolarStep.dealDone.index)
        .length;
    final sInstalled = solar
        .where((l) => l.currentStep.index >= SolarStep.installation.index)
        .length;
    final sCompleted = solar.where((l) => l.isCompleted).length;

    // ── Sprinkler metrics ─────────────────────────────────────────────────
    final pTotal = spk.length;
    final pDeals = spk
        .where((l) => l.currentStep.index >= SprinklerStep.dealDone.index)
        .length;
    final pInstalled = spk
        .where(
          (l) =>
              l.currentStep.index >=
              SprinklerStep.installationAssigned.index,
        )
        .length;
    final pCompleted = spk.where((l) => l.isCompleted).length;

    // ── Revenue — RevenueCubit se ─────────────────────────────────────────
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

    // ── Combined ──────────────────────────────────────────────────────────
    final totalCollect = totalRev - totalPending;
    final payRate = totalRev > 0 ? totalCollect / totalRev : 0.0;

    // ── 7-day new leads ───────────────────────────────────────────────────
    final now = DateTime.now();
    final daily7 = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return solar.where((l) => _sameDay(l.createdAt, day)).length +
          spk.where((l) => _sameDay(l.createdAt, day)).length;
    });
    final maxD = daily7.reduce(math.max).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      children: [
        // ── Period chips ─────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: _Period.values.map((p) {
                final sel = p == period;
                return GestureDetector(
                  onTap: () => onPeriod(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.accent2 : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: sel
                            ? AppColors.accent2
                            : AppColors.borderPrimary,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Revenue hero card ─────────────────────────────────────────────
        _RevenueHero(
          total: totalRev,
          collected: totalCollect,
          pending: totalPending,
          payRate: payRate,
          progress: progress,
          fmt: _fmtRev,
        ),

        const SizedBox(height: 20),

        // ── Solar pipeline ────────────────────────────────────────────────
        _PipelineCard(
          title: '☀️  Solar Pipeline',
          accentColor: AppColors.primary,
          stages: [
            _S('New Lead', sTotal),
            _S(
              'Visited',
              solar
                  .where(
                    (l) =>
                        l.currentStep.index >=
                        SolarStep.technicalVisit.index,
                  )
                  .length,
            ),
            _S(
              'Quotation',
              solar
                  .where(
                    (l) =>
                        l.currentStep.index >= SolarStep.quotation.index,
                  )
                  .length,
            ),
            _S('Deal', sDeals),
            _S('Installed', sInstalled),
            _S('Completed', sCompleted),
          ],
          total: sTotal,
          progress: progress,
        ),

        const SizedBox(height: 14),

        // ── Sprinkler pipeline ────────────────────────────────────────────
        _PipelineCard(
          title: '💧  Sprinkler Pipeline',
          accentColor: AppColors.primary,
          stages: [
            _S('New Lead', pTotal),
            _S(
              'Site Visit',
              spk
                  .where(
                    (l) =>
                        l.currentStep.index >=
                        SprinklerStep.siteVisit.index,
                  )
                  .length,
            ),
            _S(
              'Quotation',
              spk
                  .where(
                    (l) =>
                        l.currentStep.index >=
                        SprinklerStep.quotation.index,
                  )
                  .length,
            ),
            _S('Deal', pDeals),
            _S('Installed', pInstalled),
            _S('Completed', pCompleted),
          ],
          total: pTotal,
          progress: progress,
        ),

        const SizedBox(height: 20),

        // ── 7-day trend ───────────────────────────────────────────────────
        _Card(
          title: 'New Leads — Last 7 Days',
          svgAsset: AppSvgAssets.trendingUp,
          child: _BarChart(
            daily: daily7,
            maxVal: maxD,
            color: AppColors.accent2,
            progress: progress,
          ),
        ),

        const SizedBox(height: 14),

        // ── Revenue by source ─────────────────────────────────────────────
        _Card(
          title: 'Revenue by Source',
          svgAsset: AppSvgAssets.chartNoAxisCombined,
          child: Column(
            children: [
              _RevBar(
                '☀️  Solar',
                sRevenue,
                totalRev,
                AppColors.primary,
                _fmtRev,
                progress,
              ),
              const SizedBox(height: 10),
              _RevBar(
                '💧  Sprinkler',
                pRevenue,
                totalRev,
                AppColors.primary,
                _fmtRev,
                progress,
              ),
              const SizedBox(height: 10),
              _RevBar(
                '🔧  Service',
                svRevenue,
                totalRev,
                AppColors.primary,
                _fmtRev,
                progress,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Payment collection ────────────────────────────────────────────
        _Card(
          title: 'Payment Collection',
          svgAsset: AppSvgAssets.indianRupee,
          child: Column(
            children: [
              _CollectRow(
                'Solar',
                sRevenue - sPending,
                sRevenue,
                AppColors.primary,
                progress,
              ),
              const SizedBox(height: 10),
              _CollectRow(
                'Sprinkler',
                pRevenue - pPending,
                pRevenue,
                AppColors.primary,
                progress,
              ),
              const SizedBox(height: 10),
              _CollectRow(
                'Service',
                svRevenue - svPending,
                svRevenue,
                AppColors.primary ,
                progress,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─ Tiny model for pipeline stage ─────────────────────────────────────────────
class _S {
  final String label;
  final int count;
  const _S(this.label, this.count);
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Revenue hero ──────────────────────────────────────────────────────────────
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
            colors: [AppColors.primary , AppColors.primaryLight],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Business Revenue',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                letterSpacing: 0.3,
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
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 5,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  FractionallySizedBox(
                    widthFactor: (payRate * progress).clamp(0.0, 1.0),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Pill(
                  'Collected',
                  fmt(collected),
                  Colors.white,
                  Colors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 10),
                _Pill(
                  'Pending',
                  fmt(pending),
                  AppColors.primaryLightest,
                  Colors.orange.withValues(alpha: 0.25),
                ),
                const Spacer(),
                Text(
                  '${(payRate * 100).toStringAsFixed(1)}% collected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label, value;
  final Color text, bg;
  const _Pill(this.label, this.value, this.text, this.bg);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: text.withValues(alpha: 0.65),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ],
        ),
      );
}

// ── Pipeline funnel ───────────────────────────────────────────────────────────
class _PipelineCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<_S> stages;
  final int total;
  final double progress;
  const _PipelineCard({
    required this.title,
    required this.accentColor,
    required this.stages,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => _Card(
        title: title,
        svgAsset: AppSvgAssets.filter,
        child: total == 0
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'No leads for this period',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : Column(
                children: stages.map((s) {
                  final pct = total > 0 ? s.count / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: Text(
                            s.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor:
                                    (pct * progress).clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.35,
                                        ),
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
                          width: 28,
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

// ── 7-day bar chart ───────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<int> daily;
  final double maxVal, progress;
  final Color color;
  const _BarChart({
    required this.daily,
    required this.maxVal,
    required this.color,
    required this.progress,
  });

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final val = daily[i];
          final h = maxVal > 0 ? (val / maxVal) * 58 * progress : 0.0;
          final isToday = i == 6;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      color: isToday ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  height: h.clamp(4.0, 58.0),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isToday
                        ? color
                        : color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _days[day.weekday - 1],
                  style: TextStyle(
                    fontSize: 9,
                    color: isToday ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Revenue bar ───────────────────────────────────────────────────────────────
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
          width: 92,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
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
                        color: color.withValues(alpha: 0.3),
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
        Text(
          fmt(value),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Collection row ────────────────────────────────────────────────────────────
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
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
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
          width: 40,
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

// ── White card wrapper ────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final String svgAsset;
  final Widget child;
  const _Card({
    required this.title,
    required this.svgAsset,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSvgIcon(
                  svgAsset,
                  size: 15,
                  color: AppColors.accent2,
                ),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}






