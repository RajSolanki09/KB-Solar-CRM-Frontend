// lib/data/Repositories/service_repository.dart

import 'package:dio/dio.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart'; // ← same TokenStorage as ApiService
import 'package:solar_project/data/Models/service_request_model.dart';

class ServiceRepository {
  late final Dio _dio;

  ServiceRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.serverUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // ✅ Use the same TokenStorage as ApiService — guarantees same key + same store
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Exception _error(dynamic e) {
    if (e is DioException) {
      final msg =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Network error';
      return Exception(msg);
    }
    return Exception(e.toString());
  }

  Future<FormData> _buildPhotoForm({
    List<PickedPhoto> beforePhotos = const [],
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    final form = FormData();

    for (final photo in beforePhotos) {
      form.files.add(
        MapEntry(
          'beforePhotos',
          MultipartFile.fromBytes(photo.bytes, filename: photo.filename),
        ),
      );
    }

    for (final photo in afterPhotos) {
      form.files.add(
        MapEntry(
          'afterPhotos',
          MultipartFile.fromBytes(photo.bytes, filename: photo.filename),
        ),
      );
    }

    return form;
  }

  // ── GET ALL ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAllServices({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    int tabIndex = 0, // 0=recent, 1=older, 2=completed
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        'tab': tabIndex, // backend uses this to filter recent/older/completed
      };
      final res = await _dio.get(
        ApiConstants.apiPath(ApiEndpoints.service),
        queryParameters: params,
      );
      final list = res.data['services'] as List? ?? [];
      return {
        'services': list
            .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        'total': res.data['total'] ?? 0,
        'page': res.data['page'] ?? 1,
        'pages': res.data['pages'] ?? 1,
        'tabCounts': res.data['tabCounts'] ?? {},
      };
    } catch (e) {
      throw _error(e);
    }
  }

  // ── GET SINGLE ─────────────────────────────────────────────────────────────
  Future<ServiceRequestModel> getSingleService(String id) async {
    try {
      final res = await _dio.get(
        ApiConstants.apiPath('${ApiEndpoints.service}/$id'),
      );
      return ServiceRequestModel.fromJson(
        res.data['service'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e);
    }
  }

  // ── CREATE ─────────────────────────────────────────────────────────────────
  Future<ServiceRequestModel> createService(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        ApiConstants.apiPath(ApiEndpoints.service),
        data: data,
      );
      return ServiceRequestModel.fromJson(
        res.data['service'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e);
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────
  Future<ServiceRequestModel> updateService(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put(
        ApiConstants.apiPath('${ApiEndpoints.service}/$id'),
        data: data,
      );
      return ServiceRequestModel.fromJson(
        res.data['service'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e);
    }
  }

  // ── ADD PAYMENT ────────────────────────────────────────────────────────────
  Future<ServiceRequestModel> addPayment(
    String id,
    double amount,
    String mode,
  ) async {
    try {
      final res = await _dio.post(
        ApiConstants.apiPath('${ApiEndpoints.service}/$id/payment'),
        data: {'amount': amount, 'paymentMode': mode},
      );
      return ServiceRequestModel.fromJson(
        res.data['service'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e);
    }
  }

  // ── UPLOAD PHOTOS ──────────────────────────────────────────────────────────
  Future<ServiceRequestModel> uploadPhotos(
    String id, {
    List<PickedPhoto> beforePhotos = const [],
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    try {
      final form = await _buildPhotoForm(
        beforePhotos: beforePhotos,
        afterPhotos: afterPhotos,
      );
      final res = await _dio.post(
        ApiConstants.apiPath('${ApiEndpoints.service}/$id/photos'),
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ServiceRequestModel.fromJson(
        res.data['service'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e);
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  Future<void> deleteService(String id) async {
    try {
      await _dio.delete(ApiConstants.apiPath('${ApiEndpoints.service}/$id'));
    } catch (e) {
      throw _error(e);
    }
  }
}