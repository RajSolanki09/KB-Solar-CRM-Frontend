// lib/data/Repository/installation_repository.dart

import 'package:dio/dio.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/installation_model.dart';

class InstallationRepository {
  final Dio _dio = DioClient().dio;

  static const _base = ApiEndpoints.installationMyLeads;

  Future<List<InstallationModel>> fetchMyInstallations({
    String? currentUserId,
  }) async {
    return _fetchFromEndpoint();
  }

  Future<List<InstallationModel>> _fetchFromEndpoint() async {
    try {
      final response = await _dio.get<dynamic>(
        _base,
        queryParameters: {'limit': 500},
      );

      final body = response.data;
      List<dynamic> raw = [];
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        raw =
            (body['leads'] as List?) ??
            (body['data'] as List?) ??
            (body['results'] as List?) ??
            [];
      }

      final List<InstallationModel> list = [];
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        // Backend already filters by ownership — no client-side ID check needed.
        // Only exclude statuses that are truly pre-installation pipeline.
        if (_shouldExclude(item['status']?.toString())) continue;
        final model = _mapToModel(item);
        if (model != null) list.add(model);
      }
      return list;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return [];
      return [];
    } catch (e) {
      print('fetchMyInstallations error: $e');
      return [];
    }
  }

  // Only exclude statuses that precede the installation workflow.
  // Everything from "Deal Closed" / "Installation Assigned" onwards is shown.
  // NOTE: Do NOT exclude Portal/Subsidy/Payment — the installation team
  // may need to see/collect payment on these leads.
  bool _shouldExclude(String? status) {
    const excluded = {
      'New Lead',
      'New',
      'Visit Scheduled',
      'Quotation Sent',
      'Follow-up',
      'Followup',
    };
    return excluded.contains(status);
  }

  InstallationModel? _mapToModel(Map<String, dynamic> lead) {
    try {
      final id = lead['_id']?.toString() ?? '';
      if (id.isEmpty) return null;

      // Delegate all parsing to InstallationModel.fromJson which handles
      // all sub-doc extraction, meter stage refinement, and status mapping.
      return InstallationModel.fromJson(lead);
    } catch (e, st) {
      print('_mapToModel error: $e\n$st');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parse a backend response body into an updated InstallationModel.
  /// The backend wraps the updated lead in { lead: {...} }.
  InstallationModel? _parseLeadResponse(dynamic data) {
    try {
      if (data == null) return null;
      final body = data as Map<String, dynamic>;
      final leadJson = (body['lead'] as Map<String, dynamic>?) ?? body;
      return InstallationModel.fromJson(leadJson);
    } catch (e) {
      print('_parseLeadResponse error: $e');
      return null;
    }
  }

  // ── markInstallationStarted ───────────────────────────────────────────────
  /// Marks the installation as started (step 7).
  /// Calls PUT /installation/my-leads/:id/start
  Future<InstallationModel?> markInstallationStarted({
    required String installationId,
    String? notes,
  }) async {
    final res = await _dio.put<dynamic>(
      '$_base/$installationId/start',
      data: {
        'startDate': DateTime.now().toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return _parseLeadResponse(res.data);
  }

  // ── markInstalled ─────────────────────────────────────────────────────────
  /// Marks installation as completed (step 8).
  /// Calls PUT /installation/my-leads/:id/installation
  Future<InstallationModel?> markInstalled({
    required String installationId,
    String? notes,
  }) async {
    final res = await _dio.put<dynamic>(
      '$_base/$installationId/installation',
      data: {
        'systemTested': true,
        'customerSigned': true,
        'installationDate': DateTime.now().toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return _parseLeadResponse(res.data);
  }

  // ── updateMeter ───────────────────────────────────────────────────────────
  /// Updates meter sub-stage (steps 9a/9b/9c).
  /// All three sub-stages call the same PUT /installation/my-leads/:id/meter.
  /// Backend keeps status = "Meter Process"; sub-stage is derived from dates.
  Future<InstallationModel?> updateMeter({
    required String installationId,
    required MeterStage stage,
  }) async {
    final now = DateTime.now().toIso8601String();
    final res = await _dio.put<dynamic>(
      '$_base/$installationId/meter',
      data: {
        if (stage == MeterStage.applied)    'applicationDate': now,
        if (stage == MeterStage.inspection) 'inspectionDate':  now,
        if (stage == MeterStage.installed)  'installedDate':   now,
      },
    );
    return _parseLeadResponse(res.data);
  }

  Future<void> collectPayment({
    required String installationId,
    required double amount,
    required String mode,
    required DateTime date,
  }) async {
    await _dio.post<dynamic>(
      '$_base/$installationId/payment',
      data: {
        'amount': amount,
        'mode': mode.toLowerCase().replaceAll(' ', ''),
        'date': date.toIso8601String(),
      },
    );
  }

  Future<void> uploadPhotos({
    required String installationId,
    required List<String> photoPaths,
    required String category,
  }) async {
    final formData = FormData.fromMap({
      category: [
        for (final path in photoPaths)
          await MultipartFile.fromFile(path, filename: path.split('/').last),
      ],
    });
    await _dio.put<dynamic>(
      '$_base/$installationId/installation',
      data: formData,
    );
  }

  Future<void> saveNotes({
    required String installationId,
    required String notes,
  }) async {
    await _dio.patch<dynamic>(
      '$_base/$installationId/notes',
      data: {'notes': notes},
    );
  }

  Future<void> completeProject({required String installationId}) async {
    await _dio.put<dynamic>('$_base/$installationId/complete');
  }

  // ── updateStatus ──────────────────────────────────────────────────────────
  /// Central dispatch: maps InstallationStatus enum → correct API call.
  /// Returns the updated InstallationModel from the API response (or null).
  List<int>? _coerceBytes(dynamic value) {
    if (value is List<int>) return value;
    if (value is List) {
      return value.whereType<num>().map((byte) => byte.toInt()).toList();
    }
    return null;
  }

  Future<MultipartFile?> _toMultipartFile(dynamic value) async {
    if (value is PickedPhoto) {
      return MultipartFile.fromBytes(value.bytes, filename: value.filename);
    }

    if (value is Map) {
      final bytes = _coerceBytes(value['bytes']);
      final filename = value['filename']?.toString();
      if (bytes != null && bytes.isNotEmpty) {
        return MultipartFile.fromBytes(
          bytes,
          filename: (filename == null || filename.trim().isEmpty)
              ? 'photo.jpg'
              : filename,
        );
      }
    }

    try {
      final dynamic any = value;
      final dynamic rawBytes = await any.readAsBytes();
      final bytes = _coerceBytes(rawBytes);
      final filename = any.name?.toString();
      if (bytes != null && bytes.isNotEmpty) {
        return MultipartFile.fromBytes(
          bytes,
          filename: (filename == null || filename.trim().isEmpty)
              ? 'photo.jpg'
              : filename,
        );
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, List<MultipartFile>>> _extractPhotos(
    Map<String, dynamic> extra,
    Map<String, String> keyToField,
  ) async {
    final result = <String, List<MultipartFile>>{};
    for (final entry in keyToField.entries) {
      final candidates = extra.remove(entry.key);
      if (candidates is! List || candidates.isEmpty) continue;

      for (final item in candidates) {
        final file = await _toMultipartFile(item);
        if (file == null) continue;
        result.putIfAbsent(entry.value, () => []).add(file);
      }
    }
    return result;
  }

  void _removePhotoKeys(Map<String, dynamic> extra) {
    extra.remove('beforePhotos');
    extra.remove('afterPhotos');
    extra.remove('productionPhotos');
    extra.remove('photos');
    extra.remove('site_photo');
    extra.remove('roof_photo');
    extra.remove('panel_photo');
    extra.remove('wiring_photo');
    extra.remove('inverter_photo');
    extra.remove('application_form');
    extra.remove('electricity_bill');
    extra.remove('inspection_photo');
    extra.remove('meter_photo');
    extra.remove('meter_reading_photo');
  }

  Future<InstallationModel?> updateStatus({
    required String installationId,
    required InstallationStatus status,
    Map<String, dynamic> extra = const {},
  }) async {
    // Work on a mutable copy so we can extract photo keys
    final ex = Map<String, dynamic>.of(extra);

    switch (status) {
      case InstallationStatus.installationStarted:
        // Step 7: Mark installation started
        // Photo keys from form → backend multer field
        final photos = await _extractPhotos(ex, {
          'beforePhotos': 'beforePhotos',
          'photos': 'beforePhotos',
          'site_photo': 'beforePhotos',
          'roof_photo': 'beforePhotos',
        });
        final formData = FormData.fromMap({
          'startDate': DateTime.now().toIso8601String(),
          ...ex,
        });
        for (final entry in photos.entries) {
          for (final file in entry.value) {
            formData.files.add(MapEntry(entry.key, file));
          }
        }
        final res = await _dio.put<dynamic>(
          '$_base/$installationId/start',
          data: formData,
        );
        return _parseLeadResponse(res.data);

      case InstallationStatus.installationCompleted:
        // Step 8: Mark installation completed
        // Photo keys from form → backend multer field
        final photos2 = await _extractPhotos(ex, {
          'afterPhotos': 'afterPhotos',
          'productionPhotos': 'afterPhotos',
          'photos': 'afterPhotos',
          'panel_photo': 'afterPhotos',
          'wiring_photo': 'afterPhotos',
          'inverter_photo': 'afterPhotos',
        });
        final formData2 = FormData.fromMap({
          'systemTested': true,
          'customerSigned': true,
          'installationDate': DateTime.now().toIso8601String(),
          ...ex,
        });
        for (final entry in photos2.entries) {
          for (final file in entry.value) {
            formData2.files.add(MapEntry(entry.key, file));
          }
        }
        final res2 = await _dio.put<dynamic>(
          '$_base/$installationId/installation',
          data: formData2,
        );
        return _parseLeadResponse(res2.data);

      case InstallationStatus.meterApplied:
        // Step 9a: Meter application submitted
        _removePhotoKeys(ex);
        final res = await _dio.put<dynamic>(
          '$_base/$installationId/meter',
          data: {'applicationDate': DateTime.now().toIso8601String(), ...ex},
        );
        return _parseLeadResponse(res.data);

      case InstallationStatus.meterInspection:
        // Step 9b: Meter inspection done
        _removePhotoKeys(ex);
        final res = await _dio.put<dynamic>(
          '$_base/$installationId/meter',
          data: {'inspectionDate': DateTime.now().toIso8601String(), ...ex},
        );
        return _parseLeadResponse(res.data);

      case InstallationStatus.meterInstalled:
        // Step 9c: Meter installed → also triggers project completion
        _removePhotoKeys(ex);
        final res = await _dio.put<dynamic>(
          '$_base/$installationId/meter',
          data: {'installedDate': DateTime.now().toIso8601String(), ...ex},
        );
        // completeProject is now handled automatically by the backend
        // when installedDate is provided, so no second call needed.
        return _parseLeadResponse(res.data);

      case InstallationStatus.installationAssigned:
      case InstallationStatus.projectCompleted:
        // These are set by the admin/backend — no action from installation team
        return null;
    }
  }
}