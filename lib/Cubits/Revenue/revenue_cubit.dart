import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/data/Repository/revenue_repository.dart';
import 'revenue_state.dart';

class RevenueCubit extends Cubit<RevenueState> {
  final RevenueRepository _repo;
  RevenueCubit(this._repo) : super(RevenueInitial());

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');

  double _dbl(dynamic v) => (v is num) ? v.toDouble() : 0.0;
  int _int(dynamic v) => (v is num) ? v.toInt() : 0;

  /// Load all revenue data: owner dashboard + monthly report for [year]
  Future<void> fetchRevenue({int? year}) async {
    emit(RevenueLoading());
    try {
      final selectedYear = year ?? DateTime.now().year;

      final results = await Future.wait([
        _repo.getOwnerDashboard(),
        _repo.getMonthlyReport(year: selectedYear),
        _repo.getPaymentReport(),
      ]);

      final dashboard = results[0];
      final monthlyData = results[1];
      final paymentData = results[2];

      // ── Parse revenue from owner dashboard ──
      final rev = dashboard['revenue'] as Map<String, dynamic>? ?? {};
      final solarRev = _dbl(rev['solar']);
      final sprinklerRev = _dbl(rev['sprinkler']);
      final serviceRev = _dbl(rev['service']);
      final totalRev = _dbl(rev['total']);

      // ── Parse revenue chart (last 6 months) ──
      final rawChart = dashboard['revenueChart'] as List? ?? [];
      final chart = rawChart.map((e) => Map<String, dynamic>.from(e)).toList();

      // ── Parse monthly report ──
      final rawMonths = monthlyData['months'] as List? ?? [];
      final months =
          rawMonths.map((e) => Map<String, dynamic>.from(e)).toList();
      final yearTotal = monthlyData['yearTotal'] as Map<String, dynamic>? ?? {};

      // ── Parse payment report for pending ──
      final overall =
          paymentData['overall'] as Map<String, dynamic>? ?? {};
      final totalPending = _dbl(overall['pending']);
      final servicePayment =
          paymentData['service'] as Map<String, dynamic>? ?? {};
      final serviceCollected = _dbl(servicePayment['received']);
      final servicePending = _dbl(servicePayment['pending']);

      emit(RevenueLoaded(
        totalRevenue: totalRev,
        solarRevenue: solarRev,
        sprinklerRevenue: sprinklerRev,
        serviceRevenue: serviceRev,
        totalPending: totalPending,
        serviceCollected: serviceCollected,
        servicePending: servicePending,
        revenueChart: chart,
        year: selectedYear,
        months: months,
        yearTotalRevenue: _dbl(yearTotal['revenue']),
        yearTotalLeads: _int(yearTotal['leads']),
      ));
    } catch (e) {
      emit(RevenueError(_msg(e)));
    }
  }

  /// Apply a period filter (This Week / This Month / This Year / All)
  Future<void> applyFilter(RevenueFilter filter) async {
    final current = state;
    if (current is! RevenueLoaded) return;

    if (filter == RevenueFilter.all) {
      emit(current.copyWith(filter: filter, clearFilteredStats: true));
      return;
    }

    final now = DateTime.now();
    late DateTime from;
    final to = now;

    switch (filter) {
      case RevenueFilter.thisWeek:
        from = now.subtract(Duration(days: now.weekday - 1));
      case RevenueFilter.thisMonth:
        from = DateTime(now.year, now.month, 1);
      case RevenueFilter.thisYear:
        from = DateTime(now.year, 1, 1);
      case RevenueFilter.all:
        break;
    }

    // Optimistically show filter chip change, then fetch
    emit(current.copyWith(filter: filter, clearFilteredStats: true));

    try {
      final paymentData = await _repo.getPaymentReport(
        from: _fmtDate(from),
        to: _fmtDate(to),
      );

      final overall =
          paymentData['overall'] as Map<String, dynamic>? ?? {};
      final solar =
          paymentData['solar'] as Map<String, dynamic>? ?? {};
      final sprinkler =
          paymentData['sprinkler'] as Map<String, dynamic>? ?? {};
      final service =
          paymentData['service'] as Map<String, dynamic>? ?? {};

      final loaded = state;
      if (loaded is RevenueLoaded) {
        emit(loaded.copyWith(
          filter: filter,
          filteredTotal: _dbl(overall['received']),
          filteredSolar: _dbl(solar['received']),
          filteredSprinkler: _dbl(sprinkler['received']),
          filteredService: _dbl(service['received']),
          filteredPending: _dbl(overall['pending']),
          filteredServiceCollected: _dbl(service['received']),
          filteredServicePending: _dbl(service['pending']),
        ));
      }
    } catch (e) {
      // Silently fall back to all-time values on error
      final loaded = state;
      if (loaded is RevenueLoaded) {
        emit(loaded.copyWith(filter: RevenueFilter.all, clearFilteredStats: true));
      }
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Change year for monthly report while keeping existing revenue overview
  Future<void> changeYear(int year) async {
    final current = state;
    if (current is RevenueLoaded) {
      emit(RevenueLoading());
      try {
        final monthlyData = await _repo.getMonthlyReport(year: year);
        final rawMonths = monthlyData['months'] as List? ?? [];
        final months =
            rawMonths.map((e) => Map<String, dynamic>.from(e)).toList();
        final yearTotal =
            monthlyData['yearTotal'] as Map<String, dynamic>? ?? {};

        emit(current.copyWith(
          year: year,
          months: months,
          yearTotalRevenue: _dbl(yearTotal['revenue']),
          yearTotalLeads: _int(yearTotal['leads']),
        ));
      } catch (e) {
        emit(RevenueError(_msg(e)));
      }
    } else {
      await fetchRevenue(year: year);
    }
  }
}
