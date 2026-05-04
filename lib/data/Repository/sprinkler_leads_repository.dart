// lib/data/Repository/sprinkler_leads_repository.dart

import 'package:dio/dio.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import '../../Helper/picked_photo.dart';

class SprinklerLeadRepository {
  final DioClient client;
  SprinklerLeadRepository(this.client);

  SprinklerLeadModel _parse(dynamic data) {
    final body = data as Map<String, dynamic>;
    final lead = body.containsKey('lead') ? body['lead'] : body;
    return SprinklerLeadModel.fromJson(lead as Map<String, dynamic>);
  }

  Future<FormData> _buildForm(
    Map<String, String?> fields,
    List<PickedPhoto> photos,
    String fieldName,
  ) async {
    final form = FormData();
    fields.forEach((k, v) {
      if (v != null) form.fields.add(MapEntry(k, v));
    });
    for (final p in photos) {
      form.files.add(
        MapEntry(
          fieldName,
          MultipartFile.fromBytes(p.bytes, filename: p.filename),
        ),
      );
    }
    return form;
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<SprinklerLeadModel> createLead(SprinklerLeadModel lead) async {
    final res = await client.dio.post(
      ApiEndpoints.sprinklerLead,
      data: lead.toCreateJson(),
    );
    return _parse(res.data);
  }

  // ── GET ALL ───────────────────────────────────────────────────────────────
  Future<List<SprinklerLeadModel>> getAllLeads({
    String? status,
    String? search,
    int page = 1,
  }) async {
    final res = await client.dio.get(
      ApiEndpoints.sprinklerLead,
      queryParameters: {
        'page': page,
        'limit': 20,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final body = res.data as Map<String, dynamic>;
    return (body['leads'] as List? ?? [])
        .map((e) => SprinklerLeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET SINGLE ────────────────────────────────────────────────────────────
  Future<SprinklerLeadModel> getSingleLead(String id) async {
    final res = await client.dio.get('${ApiEndpoints.sprinklerLead}/$id');
    return _parse(res.data);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLead(String id) async =>
      client.dio.delete('${ApiEndpoints.sprinklerLead}/$id');

  // ── UPDATE BASIC INFO ─────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateBasicInfo(
    String id, {
    String? customerName,
    String? phone,
    String? address,
    String? village,
    double? farmSize,
    String? waterSource,
    String? cropType,
    String? source,
    String? referenceName,
    String? note,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id',
      data: {
        if (customerName != null) 'customerName': customerName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (village != null) 'village': village,
        if (farmSize != null) 'farmSize': farmSize,
        if (waterSource != null) 'waterSource': waterSource,
        if (cropType != null) 'cropType': cropType,
        if (source != null) 'source': source,
        if (source == 'reference' && referenceName != null)
          'referenceName': referenceName,
        if (source != null && source != 'reference') 'referenceName': null,
        if (source == null && referenceName != null)
          'referenceName': referenceName,
        if (note != null) 'note': note,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 2: SITE VISIT ────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateSiteVisit(
    String id, {
    DateTime? visitDate,
    String? visitTime,
    String? salesPerson,
    String? fieldConditionNotes,
    String? waterAvailabilityNotes,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    final form = await _buildForm(
      {
        // Send date as naive ISO string (no Z) so backend stores date in "local" context.
        // Backend will interpret it correctly regardless of timezone.
        'visitDate': visitDate?.toString().split(' ')[0],  // "2026-04-02" only
        'visitTime': visitTime,
        'salesPerson': salesPerson,
        'fieldConditionNotes': fieldConditionNotes,
        'waterAvailabilityNotes': waterAvailabilityNotes,
        'notes': notes,
      },
      photos,
      'photos',
    );
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/site-visit',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 3: VISIT DATA ────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateVisitData(
    String id, {
    int? noOfPanels,
    String? pumpCapacity,
    String? typeOfPump,
    double? deliveryPipeLength,
    int? noOfSprinklers,
    double? cableLength,
    String? typeOfSite,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    final form = await _buildForm(
      {
        if (noOfPanels != null) 'noOfPanels': noOfPanels.toString(),
        if (pumpCapacity != null) 'pumpCapacity': pumpCapacity,
        if (typeOfPump != null) 'typeOfPump': typeOfPump,
        if (deliveryPipeLength != null)
          'deliveryPipeLength': deliveryPipeLength.toString(),
        if (noOfSprinklers != null) 'noOfSprinklers': noOfSprinklers.toString(),
        if (cableLength != null) 'cableLength': cableLength.toString(),
        if (typeOfSite != null) 'typeOfSite': typeOfSite,
        if (notes != null) 'notes': notes,
      },
      photos,
      'photos',
    );

    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/visit-data',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 4: QUOTATION ─────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateQuotation(
    String id, {
    List<Map<String, dynamic>>? lineItems,
    int? noOfPanels,
    double? noOfKW,
    int? noOfSprinklerSet,
    String? typeOfSprinkler,
    String? pumpDetails,
    String? sprinkleType,
    String? upvcPipeSizes,
    String? cableDetails,
    String? upvcFittings,
    String? controlPanel,
    double? pipeLength,
    int? sprinklerQty,
    String? fittings,
    double? labourCost,
    double? transportCost,
    double? totalAmount,
    double? discount,
    double? advancePercent,
    double? balancePercent,
    String? warrantyNote,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/quotation',
      data: {
        if (lineItems != null) 'lineItems': lineItems,
        if (noOfPanels != null) 'noOfPanels': noOfPanels,
        if (noOfKW != null) 'noOfKW': noOfKW,
        if (noOfSprinklerSet != null) 'noOfSprinklerSet': noOfSprinklerSet,
        if (typeOfSprinkler != null) 'typeOfSprinkler': typeOfSprinkler,
        if (pumpDetails != null) 'pumpDetails': pumpDetails,
        if (sprinkleType != null) 'sprinkleType': sprinkleType,
        if (upvcPipeSizes != null) 'upvcPipeSizes': upvcPipeSizes,
        if (cableDetails != null) 'cableDetails': cableDetails,
        if (upvcFittings != null) 'upvcFittings': upvcFittings,
        if (controlPanel != null) 'controlPanel': controlPanel,
        if (pipeLength != null) 'pipeLength': pipeLength,
        if (sprinklerQty != null) 'sprinklerQty': sprinklerQty,
        if (fittings != null) 'fittings': fittings,
        if (labourCost != null) 'labourCost': labourCost,
        if (transportCost != null) 'transportCost': transportCost,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (discount != null) 'discount': discount,
        if (advancePercent != null) 'advancePercent': advancePercent,
        if (balancePercent != null) 'balancePercent': balancePercent,
        if (warrantyNote != null) 'warrantyNote': warrantyNote,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 4: TECHNICAL VISIT (legacy — kept for backward compat) ───────────
  Future<SprinklerLeadModel> updateTechnicalVisit(
    String id, {
    double? finalPipeLength,
    int? finalSprinklerCount,
    String? motorHP,
    String? pressureCheckNotes,
    String? layoutNotes,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    final form = await _buildForm(
      {
        'finalPipeLength': finalPipeLength?.toString(),
        'finalSprinklerCount': finalSprinklerCount?.toString(),
        'motorHP': motorHP,
        'pressureCheckNotes': pressureCheckNotes,
        'layoutNotes': layoutNotes,
        'notes': notes,
      },
      photos,
      'photos',
    );
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/technical-visit',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 5: FOLLOWUP ─────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateFollowup(
    String id, {
    DateTime? followupDate,
    String? response,
    String? customerType,
    String? remarks,
    String? notes,
    String? interestLevel,
    String? followupType,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/followup',
      data: {
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
        if (response != null) 'response': response,
        if (customerType != null) 'customerType': customerType,
        if (remarks != null) 'remarks': remarks,
        if (notes != null) 'notes': notes,
        if (interestLevel != null) 'interestLevel': interestLevel,
        if (followupType != null) 'followupType': followupType,
      },
    );
    return _parse(res.data);
  }

  // ── EDIT FOLLOWUP (PATCH — no step advance) ──────────────────────────────
  Future<SprinklerLeadModel> editFollowup(
    String id, {
    DateTime? followupDate,
    String? response,
    String? customerType,
    String? remarks,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.sprinklerLead}/$id/followup',
      data: {
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
        if (response != null) 'response': response,
        if (customerType != null) 'customerType': customerType,
        if (remarks != null) 'remarks': remarks,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── ADD FOLLOWUP ENTRY ────────────────────────────────────────────────────
  Future<SprinklerLeadModel> addFollowupEntry(
    String id, {
    required String remark,
    required String followupType,
    required DateTime nextFollowupDate,
    int? callDuration,
    String? attachment,
  }) async {
    final nextDateIso = nextFollowupDate.toIso8601String();
    final res = await client.dio.post(
      '${ApiEndpoints.sprinklerLead}/$id/followup-add',
      data: {
        'remark': remark,
        'followupType': followupType,
        'nextFollowupDate': nextDateIso,
        if (callDuration != null) 'callDuration': callDuration,
        if (attachment != null) 'attachment': attachment,
      },
    );

    await client.dio.post(
      '/followups/Sprinkler/$id',
      data: {
        'followupDate': DateTime.now().toIso8601String(),
        'nextFollowupDate': nextDateIso,
        'notes': remark,
      },
    );

    return _parse(res.data);
  }

  // ── GET FOLLOWUP HISTORY ──────────────────────────────────────────────────
  Future<List<FollowupHistoryEntry>> getFollowupHistory(String id) async {
    final res = await client.dio.get(
      '${ApiEndpoints.sprinklerLead}/$id/followup-history',
    );
    final body = res.data as Map<String, dynamic>;
    return (body['history'] as List? ?? [])
        .map((e) => FollowupHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── MARK FOLLOWUP DONE ───────────────────────────────────────────────────
  Future<SprinklerLeadModel> markFollowupDone(String id) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.sprinklerLead}/$id/followup-done',
    );
    return _parse(res.data);
  }

  // ── STEP 6: DEAL ──────────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateDeal(
    String id, {
    double? finalDealAmount,
    double? discountGiven,
    double? advancePayment,
    String? paymentMode,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/deal',
      data: {
        if (finalDealAmount != null) 'finalDealAmount': finalDealAmount,
        if (discountGiven != null) 'discountGiven': discountGiven,
        if (advancePayment != null) 'advancePayment': advancePayment,
        if (paymentMode != null) 'paymentMode': paymentMode,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 7 (ADMIN): ASSIGN INSTALLATION TEAM ──────────────────────────────
  Future<SprinklerLeadModel> assignInstaller(
    String id, {
    required List<String> installerIds,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/assign-installer',
      data: {
        'installerIds': installerIds,
        if (scheduledDate != null)
          'scheduledDate': scheduledDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 8: INSTALLATION STARTED ───────────────────────────────────────
  Future<SprinklerLeadModel> startInstallation(
    String id, {
    DateTime? startedAt,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
  }) async {
    final form = await _buildForm(
      {
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
      beforePhotos,
      'beforePhotos',
    );
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/installation-start',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 9 (INSTALLATION TEAM): COMPLETE INSTALLATION ────────────────────
  Future<SprinklerLeadModel> completeInstallation(
    String id, {
    String? technicianName,
    DateTime? installationDate,
    String? materialUsed,
    String? extraMaterial,
    String? workNotes,
    String? notes,
    bool? pendingWork,
    String? pendingWorkNote,
    bool? systemTested,
    bool? paymentReceived,
    DateTime? followUpDate,
    String? completedBy,
    String? customerReview,
    List<PickedPhoto> photos = const [],
  }) async {
    final form = await _buildForm(
      {
        if (technicianName != null) 'technicianName': technicianName,
        'installationDate': (installationDate ?? DateTime.now())
            .toIso8601String(),
        if (materialUsed != null) 'materialUsed': materialUsed,
        if (extraMaterial != null) 'extraMaterial': extraMaterial,
        if (workNotes != null) 'workNotes': workNotes,
        if (notes != null) 'notes': notes,
        if (pendingWork != null) 'pendingWork': pendingWork.toString(),
        if (pendingWorkNote != null) 'pendingWorkNote': pendingWorkNote,
        if (systemTested != null) 'systemTested': systemTested.toString(),
        if (paymentReceived != null) 'paymentReceived': paymentReceived.toString(),
        if (followUpDate != null) 'followUpDate': followUpDate.toIso8601String(),
        if (completedBy != null) 'completedBy': completedBy,
        if (customerReview != null) 'customerReview': customerReview,
      },
      photos,
      'installPhotos',
    );
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/installation-complete',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 10: PAYMENT ──────────────────────────────────────────────────────
  Future<SprinklerLeadModel> addPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? transactionId,
    String? notes,
  }) async {
    final res = await client.dio.post(
      '${ApiEndpoints.sprinklerLead}/$id/payment',
      data: {
        'amount': amount,
        'mode': mode,
        'type': type,
        if (transactionId != null) 'transactionId': transactionId,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 11: REVIEW ───────────────────────────────────────────────────────
  Future<SprinklerLeadModel> updateReview(
    String id, {
    required int rating,
    String? feedback,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.sprinklerLead}/$id/review',
      data: {
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── GET INSTALLATION TEAM LEADS ───────────────────────────────────────────
  Future<List<SprinklerLeadModel>> getMyInstallationLeads({
    String? status,
    String? search,
  }) async {
    final res = await client.dio.get(
      '${ApiEndpoints.sprinklerLead}/my-installation-leads',
      queryParameters: {
        'limit': 200,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final body = res.data as Map<String, dynamic>;
    return (body['leads'] as List? ?? [])
        .map((e) => SprinklerLeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
