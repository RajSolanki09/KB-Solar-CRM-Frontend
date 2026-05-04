abstract class RevenueState {}

class RevenueInitial extends RevenueState {}

class RevenueLoading extends RevenueState {}

enum RevenueFilter { all, thisWeek, thisMonth, thisYear }

class RevenueLoaded extends RevenueState {
  // ── Overview revenue (all-time) ──
  final double totalRevenue;
  final double solarRevenue;
  final double sprinklerRevenue;
  final double serviceRevenue;

  // ── Payment report (pending) ──
  final double totalPending;
  final double serviceCollected;
  final double servicePending;

  // ── Last 6 months chart data from owner dashboard ──
  final List<Map<String, dynamic>> revenueChart;

  // ── Monthly report (12 months for selected year) ──
  final int year;
  final List<Map<String, dynamic>> months;
  final double yearTotalRevenue;
  final int yearTotalLeads;

  // ── Active period filter ──
  final RevenueFilter filter;

  // ── Filtered revenue (non-null only when filter != all) ──
  final double? filteredTotal;
  final double? filteredSolar;
  final double? filteredSprinkler;
  final double? filteredService;
  final double? filteredPending;
  final double? filteredServiceCollected;
  final double? filteredServicePending;

  // ── Display getters (use filtered values when available) ──
  double get displayTotal => filteredTotal ?? totalRevenue;
  double get displaySolar => filteredSolar ?? solarRevenue;
  double get displaySprinkler => filteredSprinkler ?? sprinklerRevenue;
  double get displayService => filteredService ?? serviceRevenue;
  double get displayPending => filteredPending ?? totalPending;
  double get displayServiceCollected =>
      filteredServiceCollected ?? serviceCollected;
  double get displayServicePending =>
      filteredServicePending ?? servicePending;

  RevenueLoaded({
    required this.totalRevenue,
    required this.solarRevenue,
    required this.sprinklerRevenue,
    required this.serviceRevenue,
    required this.totalPending,
    required this.serviceCollected,
    required this.servicePending,
    required this.revenueChart,
    required this.year,
    required this.months,
    required this.yearTotalRevenue,
    required this.yearTotalLeads,
    this.filter = RevenueFilter.all,
    this.filteredTotal,
    this.filteredSolar,
    this.filteredSprinkler,
    this.filteredService,
    this.filteredPending,
    this.filteredServiceCollected,
    this.filteredServicePending,
  });

  RevenueLoaded copyWith({
    double? totalRevenue,
    double? solarRevenue,
    double? sprinklerRevenue,
    double? serviceRevenue,
    double? totalPending,
    double? serviceCollected,
    double? servicePending,
    List<Map<String, dynamic>>? revenueChart,
    int? year,
    List<Map<String, dynamic>>? months,
    double? yearTotalRevenue,
    int? yearTotalLeads,
    RevenueFilter? filter,
    bool clearFilteredStats = false,
    double? filteredTotal,
    double? filteredSolar,
    double? filteredSprinkler,
    double? filteredService,
    double? filteredPending,
    double? filteredServiceCollected,
    double? filteredServicePending,
  }) {
    return RevenueLoaded(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      solarRevenue: solarRevenue ?? this.solarRevenue,
      sprinklerRevenue: sprinklerRevenue ?? this.sprinklerRevenue,
      serviceRevenue: serviceRevenue ?? this.serviceRevenue,
      totalPending: totalPending ?? this.totalPending,
      serviceCollected: serviceCollected ?? this.serviceCollected,
      servicePending: servicePending ?? this.servicePending,
      revenueChart: revenueChart ?? this.revenueChart,
      year: year ?? this.year,
      months: months ?? this.months,
      yearTotalRevenue: yearTotalRevenue ?? this.yearTotalRevenue,
      yearTotalLeads: yearTotalLeads ?? this.yearTotalLeads,
      filter: filter ?? this.filter,
      filteredTotal: clearFilteredStats ? null : (filteredTotal ?? this.filteredTotal),
      filteredSolar: clearFilteredStats ? null : (filteredSolar ?? this.filteredSolar),
      filteredSprinkler: clearFilteredStats ? null : (filteredSprinkler ?? this.filteredSprinkler),
      filteredService: clearFilteredStats ? null : (filteredService ?? this.filteredService),
      filteredPending: clearFilteredStats ? null : (filteredPending ?? this.filteredPending),
      filteredServiceCollected: clearFilteredStats ? null : (filteredServiceCollected ?? this.filteredServiceCollected),
      filteredServicePending: clearFilteredStats ? null : (filteredServicePending ?? this.filteredServicePending),
    );
  }
}

class RevenueError extends RevenueState {
  final String message;
  RevenueError(this.message);
}
