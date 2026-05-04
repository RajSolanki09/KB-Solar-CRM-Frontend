// lib/data/Repository/service_repository.dart

import 'package:dio/dio.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/service_request_model.dart';

// NOTE: DioClient.baseUrl already includes /api, so paths here are relative
// to that — e.g. ApiEndpoints.service = '/service' → resolves to /api/service.

class ServiceRepository {
  // ✅ Use shared DioClient — gets the web-safe timeout guard, JWT interceptor,
  //    and correct baseUrl automatically. No duplicate Dio setup needed.
  final DioClient _client;

  ServiceRepository({DioClient? client}) : _client = client ?? DioClient();

  Dio get _dio => _client.dio;

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
  Future<List<ServiceRequestModel>> getAllServices() async {
    try {
      final res = await _dio.get(ApiEndpoints.service);
      final list = res.data['services'] as List? ?? [];
      return list
          .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _error(e);
    }
  }

  // ── GET SINGLE ─────────────────────────────────────────────────────────────
  Future<ServiceRequestModel> getSingleService(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.serviceById(id));
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
      final res = await _dio.post(ApiEndpoints.service, data: data);
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
      final res = await _dio.put(ApiEndpoints.serviceById(id), data: data);
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
        ApiEndpoints.servicePayment(id),
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
        ApiEndpoints.servicePhotos(id),
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
      await _dio.delete(ApiEndpoints.serviceById(id));
    } catch (e) {
      throw _error(e);
    }
  }
}