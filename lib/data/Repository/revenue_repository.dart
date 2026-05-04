import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';

class RevenueRepository {
  final DioClient client;
  RevenueRepository(this.client);

  /// Fetches owner dashboard: cards, revenue breakdown, revenueChart (last 6 months)
  Future<Map<String, dynamic>> getOwnerDashboard() async {
    final res = await client.dio.get(ApiEndpoints.dashboardOwner);
    return res.data as Map<String, dynamic>;
  }

  /// Fetches monthly report for a given year: 12-month array with per-category revenue
  Future<Map<String, dynamic>> getMonthlyReport({required int year}) async {
    final res = await client.dio.get(
      ApiEndpoints.reportsMonthly,
      queryParameters: {'year': year},
    );
    return res.data as Map<String, dynamic>;
  }

  /// Fetches payment report with optional date range
  Future<Map<String, dynamic>> getPaymentReport({
    String? from,
    String? to,
  }) async {
    final res = await client.dio.get(
      ApiEndpoints.reportsPayments,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return res.data as Map<String, dynamic>;
  }
}
