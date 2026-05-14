// lib/data/Repository/solar_leads_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/core/constants/api_constants.dart';

import '../../Helper/picked_photo.dart';

class SolarLeadRepository {
  final DioClient client;
  SolarLeadRepository(this.client);

  SolarLeadsModel _parse(dynamic data) {
    if (data is String) data = json.decode(data);
    final body = data as Map<String, dynamic>;
    final lead = body.containsKey('lead') ? body['lead'] : body;
    return SolarLeadsModel.fromJson(lead as Map<String, dynamic>);
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
  // referenceName is included via lead.toCreateJson() when source == 'reference'
  Future<SolarLeadsModel> createLead(SolarLeadsModel lead) async {
    final res = await client.dio.post(
      ApiEndpoints.solarLead,
      data: lead.toCreateJson(),
    );
    return _parse(res.data);
  }

  // ── GET ALL ───────────────────────────────────────────────────────────────
  Future<({List<SolarLeadsModel> leads, int total, int page, int pages})>
    getAllLeads({
  String? status,
  String? search,
  int page = 1,
  int limit = 10,
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  final res = await client.dio.get(
    ApiEndpoints.solarLead,
    queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
      if (toDate != null) 'toDate': toDate.toIso8601String(),
    },
  );
  final body = res.data as Map<String, dynamic>;
  final leads = (body['leads'] as List? ?? [])
      .map((e) => SolarLeadsModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return (
    leads: leads,
    total: (body['total'] as num?)?.toInt() ?? leads.length,
    page:  (body['page']  as num?)?.toInt() ?? page,
    pages: (body['pages'] as num?)?.toInt() ?? 1,
  );
}

  // ── GET SINGLE ────────────────────────────────────────────────────────────
  Future<SolarLeadsModel> getSingleLead(String id) async {
    final res = await client.dio.get('${ApiEndpoints.solarLead}/$id');
    return _parse(res.data);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLead(String id) async =>
      client.dio.delete('${ApiEndpoints.solarLead}/$id');

  // ── UPDATE BASIC INFO ─────────────────────────────────────────────────────
  // PATCH /:id — edits core customer fields without advancing the pipeline stage
  Future<SolarLeadsModel> updateBasicInfo(
    String id, {
    String? customerName,
    String? mobile,
    String? address,
    String? village,
    double? landSize,
    double? requiredKW,
    String? electricityConnection,
    String? source,
    String? referenceName,
    String? note,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id',
      data: {
        if (customerName != null) 'customerName': customerName,
        if (mobile != null) 'mobile': mobile,
        if (address != null) 'address': address,
        if (village != null) 'village': village,
        if (landSize != null) 'landSize': landSize,
        if (requiredKW != null) 'requiredKW': requiredKW,
        if (electricityConnection != null)
          'electricityConnection': electricityConnection,
        if (source != null) 'source': source,
        // Only send referenceName when source is 'reference'
        if (source == 'reference' && referenceName != null)
          'referenceName': referenceName
        else
          'referenceName': null,
        if (note != null) 'note': note,
      },
    );
    return _parse(res.data);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PUT — first-time submit (advances stage + pushes history entry)
  // ══════════════════════════════════════════════════════════════════════════

  // ── STEP 2: VISIT SCHEDULE  (PUT — first time, advances stage) ──────────────
  Future<SolarLeadsModel> updateVisitSchedule(
    String id, {
    DateTime? visitDate,
    String? salesAssignedId,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/visit-schedule',
      data: {
        if (visitDate != null) 'visitDate': visitDate.toIso8601String(),
        'salesAssignedId': salesAssignedId, // always send, even null
        'notes': notes, // always send, even null
      },
    );
    return _parse(res.data);
  }

  // ── STEP 4: QUOTATION ─────────────────────────────────────────────────────
  Future<SolarLeadsModel> updateQuotation(
    String id, {
    String? systemSize,
    String? panelType,
    String? inverterType,
    String? structureType,
    String? wiringDetails,
    double? rooftopSystemCost,
    double? elevatedStructureCost,
    double? netMeterCost,
    double? premiumOtherCost,
    double? totalAmount,
    double? subsidyAmount,
    double? advancePercent,
    double? balancePercent,
    String? warrantyNote,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/quotation',
      data: {
        if (systemSize != null) 'systemSize': systemSize,
        if (panelType != null) 'panelType': panelType,
        if (inverterType != null) 'inverterType': inverterType,
        if (structureType != null) 'structureType': structureType,
        if (wiringDetails != null) 'wiringDetails': wiringDetails,
        if (rooftopSystemCost != null) 'rooftopSystemCost': rooftopSystemCost,
        if (elevatedStructureCost != null)
          'elevatedStructureCost': elevatedStructureCost,
        if (netMeterCost != null) 'netMeterCost': netMeterCost,
        if (premiumOtherCost != null) 'premiumOtherCost': premiumOtherCost,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (subsidyAmount != null) 'subsidyAmount': subsidyAmount,
        if (advancePercent != null) 'advancePercent': advancePercent,
        if (balancePercent != null) 'balancePercent': balancePercent,
        if (warrantyNote != null) 'warrantyNote': warrantyNote,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 5: FOLLOWUP ─────────────────────────────────────────────────────
  Future<SolarLeadsModel> updateFollowup(
    String id, {
    DateTime? followupDate,
    String? notes,
    String? outcome,
    String? customerType,
    String? interestLevel,
    String? followupType,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/followup',
      data: {
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (outcome != null) 'outcome': outcome,
        if (customerType != null) 'customerType': customerType,
        if (interestLevel != null) 'interestLevel': interestLevel,
        if (followupType != null) 'followupType': followupType,
      },
    );
    return _parse(res.data);
  }

  // ── ADD FOLLOWUP ENTRY ────────────────────────────────────────────────────
  Future<SolarLeadsModel> addFollowupEntry(
    String id, {
    required String remark,
    required String followupType,
    required DateTime nextFollowupDate,
    int? callDuration,
    String? attachment,
  }) async {
    final nextDateIso = nextFollowupDate.toIso8601String();
    final res = await client.dio.post(
      '${ApiEndpoints.solarLead}/$id/followup-add',
      data: {
        'remark': remark,
        'followupType': followupType,
        'nextFollowupDate': nextDateIso,
        if (callDuration != null) 'callDuration': callDuration,
        if (attachment != null) 'attachment': attachment,
      },
    );

    await client.dio.post(
      '/followups/Solar/$id',
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
      '${ApiEndpoints.solarLead}/$id/followup-history',
    );
    final body = res.data as Map<String, dynamic>;
    return (body['history'] as List? ?? [])
        .map((e) => FollowupHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── MARK FOLLOWUP DONE ────────────────────────────────────────────────────
  Future<SolarLeadsModel> markFollowupDone(String id) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/followup-done',
    );
    return _parse(res.data);
  }

  // ── STEP 6: DEAL ──────────────────────────────────────────────────────────
  Future<SolarLeadsModel> updateDeal(
    String id, {
    double? finalAmount,
    double? advancePayment,
    String? paymentMode,
    DateTime? expectedInstallDate,
    String? notes,
    String? installationTeamMemberId,
    String? installationTeamName,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/deal',
      data: {
        if (finalAmount != null) 'finalAmount': finalAmount,
        if (advancePayment != null) 'advancePayment': advancePayment,
        if (paymentMode != null) 'paymentMode': paymentMode,
        if (expectedInstallDate != null)
          'expectedInstallDate': expectedInstallDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 7: INSTALLATION ASSIGNED ─────────────────────────────────────────
  Future<SolarLeadsModel> updateInstallationAssign(
    String id, {
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamNames,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/installation-assign',
      data: {
        if (installationTeamMemberIds != null)
          'installationTeamMemberIds': installationTeamMemberIds,
        if (installationTeamNames != null)
          'installationTeamNames': installationTeamNames,
        if (scheduledDate != null)
          'scheduledDate': scheduledDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 8: INSTALLATION STARTED ──────────────────────────────────────────
  Future<SolarLeadsModel> updateInstallationStarted(
    String id, {
    String? teamAssigned,
    DateTime? startDate,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
  }) async {
    final form = FormData();
    if (teamAssigned != null) {
      form.fields.add(MapEntry('teamAssigned', teamAssigned));
    }
    if (startDate != null) {
      form.fields.add(MapEntry('startDate', startDate.toIso8601String()));
    }
    if (notes != null) form.fields.add(MapEntry('notes', notes));
    for (final p in beforePhotos) {
      form.files.add(
        MapEntry(
          'beforePhotos',
          MultipartFile.fromBytes(p.bytes, filename: p.filename),
        ),
      );
    }
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/installation-started',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 9: INSTALLATION COMPLETED ────────────────────────────────────────
  Future<SolarLeadsModel> updateInstallation(
    String id, {
    String? teamAssigned,
    bool systemTested = false,
    bool customerSigned = false,
    bool structureDone = false,
    bool wiringDone = false,
    bool plumeDone = false,
    bool inverterAcDone = false,
    bool fullyComplete = false,
    DateTime? completedDate,
    String? structureVendorName,
    String? structureVendorCo,
    String? wiringVendorName,
    String? wiringVendorCo,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    final form = FormData();
    if (teamAssigned != null) {
      form.fields.add(MapEntry('teamAssigned', teamAssigned));
    }
    form.fields.add(MapEntry('systemTested', systemTested.toString()));
    form.fields.add(MapEntry('customerSigned', customerSigned.toString()));
    form.fields.add(MapEntry('structureDone', structureDone.toString()));
    form.fields.add(MapEntry('wiringDone', wiringDone.toString()));
    form.fields.add(MapEntry('plumeDone', plumeDone.toString()));
    form.fields.add(MapEntry('inverterAcDone', inverterAcDone.toString()));
    form.fields.add(MapEntry('fullyComplete', fullyComplete.toString()));
    if (completedDate != null) {
      form.fields.add(MapEntry('completedDate', completedDate.toIso8601String()));
    }
    if (structureVendorName != null) {
      form.fields.add(MapEntry('structureVendorName', structureVendorName));
    }
    if (structureVendorCo != null) {
      form.fields.add(MapEntry('structureVendorCo', structureVendorCo));
    }
    if (wiringVendorName != null) {
      form.fields.add(MapEntry('wiringVendorName', wiringVendorName));
    }
    if (wiringVendorCo != null) {
      form.fields.add(MapEntry('wiringVendorCo', wiringVendorCo));
    }
    if (notes != null) form.fields.add(MapEntry('notes', notes));
    for (final p in beforePhotos) {
      form.files.add(
        MapEntry(
          'beforePhotos',
          MultipartFile.fromBytes(p.bytes, filename: p.filename),
        ),
      );
    }
    for (final p in afterPhotos) {
      form.files.add(
        MapEntry(
          'afterPhotos',
          MultipartFile.fromBytes(p.bytes, filename: p.filename),
        ),
      );
    }
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/installation',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 10: AGREEMENT UPLOAD ───────────────────────────────────────────
  Future<SolarLeadsModel> updateAgreementUpload(
    String id, {
    bool agreementUploaded = false,
    bool installationDetailsProvided = false,
    String? status,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/agreement-upload',
      data: {
        'agreementUploaded': agreementUploaded,
        'installationDetailsProvided': installationDetailsProvided,
        if (status != null) 'status': status,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 10: METER ────────────────────────────────────────────────────────
  Future<SolarLeadsModel> updateMeter(
    String id, {
    DateTime? applicationDate,
    DateTime? inspectionDate,
    DateTime? installedDate,
    bool? gebFileHandover,
    String? meterInstallationStatus,
    String? systemRunStatus,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/meter',
      data: {
        if (applicationDate != null)
          'applicationDate': applicationDate.toIso8601String(),
        if (inspectionDate != null)
          'inspectionDate': inspectionDate.toIso8601String(),
        if (installedDate != null)
          'installedDate': installedDate.toIso8601String(),
        if (gebFileHandover != null) 'gebFileHandover': gebFileHandover,
        if (meterInstallationStatus != null)
          'meterInstallationStatus': meterInstallationStatus,
        if (systemRunStatus != null) 'systemRunStatus': systemRunStatus,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 11: PORTAL ───────────────────────────────────────────────────────
  Future<SolarLeadsModel> updatePortal(
    String id, {
    String? applicationId,
    String? status,
    String? notes,
    Map<String, PickedPhoto> documents = const {},
  }) async {
    final form = FormData();
    if (applicationId != null) {
      form.fields.add(MapEntry('applicationId', applicationId));
    }
    if (status != null) form.fields.add(MapEntry('status', status));
    if (notes != null) form.fields.add(MapEntry('notes', notes));
    for (final e in documents.entries) {
      form.files.add(
        MapEntry(
          e.key,
          MultipartFile.fromBytes(e.value.bytes, filename: e.value.filename),
        ),
      );
    }
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/portal',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  // ── STEP 12: SUBSIDY ──────────────────────────────────────────────────────
  Future<SolarLeadsModel> updateSubsidy(
    String id, {
    bool? subsidyClaim,
    bool? receivedAmount,
    String? notes,
  }) async {
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/subsidy',
      data: {
        if (subsidyClaim != null) 'subsidyClaim': subsidyClaim,
        if (receivedAmount != null) 'receivedAmount': receivedAmount,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  // ── STEP 13: PAYMENT ──────────────────────────────────────────────────────
  Future<SolarLeadsModel> addPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? notes,
  }) async {
    final res = await client.dio.post(
      '${ApiEndpoints.solarLead}/$id/payment',
      data: {
        'amount': amount,
        'mode': mode,
        'type': type,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

    // ── STEP 2: VISIT SCHEDULE  (PATCH — edit, no stage advance) ─────────────────
  Future<SolarLeadsModel> editVisitSchedule(
    String id, {
    DateTime? visitDate,
    String? salesAssignedId,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/visit-schedule',
      data: {
        if (visitDate != null) 'visitDate': visitDate.toIso8601String(),
        'salesAssignedId': salesAssignedId, // always send, even null
        'notes': notes,                     // always send, even null
      },
    );
    return _parse(res.data);
  }

  // ── STEP 2b: TECHNICAL VISIT ──────────────────────────────────────────────
  Future<SolarLeadsModel> updateTechnicalVisit(
    String id, {
    String? systemKW,
    String? meterPhase,
    String? inverterBoardType,
    String? panelBoardType,
    String? panelCapacity,
    String? cableType,
    String? acDBType,
    String? structureHeight,
    String? beamLineDetails,
    String? totalArray,
    String? scaffoldingDetails,
    String? panelLayout,
    String? lugType,
    String? dbConfigSingle,
    String? dbConfigThree,
    String? estimatedCost,
    String? additionalNotes,
    List<PickedPhoto> photos = const [],
  }) async {
    final form = await _buildForm(
      {
        'systemKW': systemKW,
        'meterPhase': meterPhase,
        'inverterBoardType': inverterBoardType,
        'panelBoardType': panelBoardType,
        'panelCapacity': panelCapacity,
        'cableType': cableType,
        'acDBType': acDBType,
        'structureHeight': structureHeight,
        'beamLineDetails': beamLineDetails,
        'totalArray': totalArray,
        'scaffoldingDetails': scaffoldingDetails,
        'panelLayout': panelLayout,
        'lugType': lugType,
        'dbConfigSingle': dbConfigSingle,
        'dbConfigThree': dbConfigThree,
        'estimatedCost': estimatedCost,
        'additionalNotes': additionalNotes,
      },
      photos,
      'technicalPhotos',
    );
    final res = await client.dio.put(
      '${ApiEndpoints.solarLead}/$id/technicalVisit',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editTechnicalVisit(
    String id, {
    String? systemKW,
    String? meterPhase,
    String? inverterBoardType,
    String? panelBoardType,
    String? panelCapacity,
    String? cableType,
    String? acDBType,
    String? structureHeight,
    String? beamLineDetails,
    String? totalArray,
    String? scaffoldingDetails,
    String? panelLayout,
    String? lugType,
    String? dbConfigSingle,
    String? dbConfigThree,
    String? estimatedCost,
    String? additionalNotes,
    List<PickedPhoto> photos = const [],
  }) async {
    final form = await _buildForm(
      {
        'systemKW': systemKW,
        'meterPhase': meterPhase,
        'inverterBoardType': inverterBoardType,
        'panelBoardType': panelBoardType,
        'panelCapacity': panelCapacity,
        'cableType': cableType,
        'acDBType': acDBType,
        'structureHeight': structureHeight,
        'beamLineDetails': beamLineDetails,
        'totalArray': totalArray,
        'scaffoldingDetails': scaffoldingDetails,
        'panelLayout': panelLayout,
        'lugType': lugType,
        'dbConfigSingle': dbConfigSingle,
        'dbConfigThree': dbConfigThree,
        'estimatedCost': estimatedCost,
        'additionalNotes': additionalNotes,
      },
      photos,
      'technicalPhotos',
    );
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/technicalVisit',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editQuotation(
    String id, {
    String? systemSize,
    String? panelType,
    String? inverterType,
    String? structureType,
    String? wiringDetails,
    double? rooftopSystemCost,
    double? elevatedStructureCost,
    double? netMeterCost,
    double? premiumOtherCost,
    double? totalAmount,
    double? subsidyAmount,
    double? advancePercent,
    double? balancePercent,
    String? warrantyNote,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/quotation',
      data: {
        if (systemSize != null) 'systemSize': systemSize,
        if (panelType != null) 'panelType': panelType,
        if (inverterType != null) 'inverterType': inverterType,
        if (structureType != null) 'structureType': structureType,
        if (wiringDetails != null) 'wiringDetails': wiringDetails,
        if (rooftopSystemCost != null) 'rooftopSystemCost': rooftopSystemCost,
        if (elevatedStructureCost != null)
          'elevatedStructureCost': elevatedStructureCost,
        if (netMeterCost != null) 'netMeterCost': netMeterCost,
        if (premiumOtherCost != null) 'premiumOtherCost': premiumOtherCost,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (subsidyAmount != null) 'subsidyAmount': subsidyAmount,
        if (advancePercent != null) 'advancePercent': advancePercent,
        if (balancePercent != null) 'balancePercent': balancePercent,
        if (warrantyNote != null) 'warrantyNote': warrantyNote,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editFollowup(
    String id, {
    DateTime? followupDate,
    String? notes,
    String? outcome,
    String? customerType,
    String? interestLevel,
    String? followupType,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/followup',
      data: {
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (outcome != null) 'outcome': outcome,
        if (customerType != null) 'customerType': customerType,
        if (interestLevel != null) 'interestLevel': interestLevel,
        if (followupType != null) 'followupType': followupType,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editDeal(
    String id, {
    double? finalAmount,
    double? advancePayment,
    String? paymentMode,
    DateTime? expectedInstallDate,
    String? installationTeamMemberId,
    String? installationTeamName,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/deal',
      data: {
        if (finalAmount != null) 'finalAmount': finalAmount,
        if (advancePayment != null) 'advancePayment': advancePayment,
        if (paymentMode != null) 'paymentMode': paymentMode,
        if (expectedInstallDate != null)
          'expectedInstallDate': expectedInstallDate.toIso8601String(),
        if (installationTeamMemberId != null)
          'installationTeamMemberId': installationTeamMemberId,
        if (installationTeamName != null)
          'installationTeamName': installationTeamName,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editInstallationAssign(
    String id, {
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamNames,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/installation-assign',
      data: {
        if (installationTeamMemberIds != null)
          'installationTeamMemberIds': installationTeamMemberIds,
        if (installationTeamNames != null)
          'installationTeamNames': installationTeamNames,
        if (scheduledDate != null)
          'scheduledDate': scheduledDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editInstallation(
    String id, {
    String? teamAssigned,
    bool? systemTested,
    bool? customerSigned,
    bool? structureDone,
    bool? wiringDone,
    bool? plumeDone,
    bool? inverterAcDone,
    bool? fullyComplete,
    DateTime? completedDate,
    String? structureVendorName,
    String? structureVendorCo,
    String? wiringVendorName,
    String? wiringVendorCo,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    final form = FormData();
    if (teamAssigned != null) {
      form.fields.add(MapEntry('teamAssigned', teamAssigned));
    }
    if (systemTested != null) {
      form.fields.add(MapEntry('systemTested', systemTested.toString()));
    }
    if (customerSigned != null) {
      form.fields.add(MapEntry('customerSigned', customerSigned.toString()));
    }
    if (structureDone != null) {
      form.fields.add(MapEntry('structureDone', structureDone.toString()));
    }
    if (wiringDone != null) {
      form.fields.add(MapEntry('wiringDone', wiringDone.toString()));
    }
    if (plumeDone != null) {
      form.fields.add(MapEntry('plumeDone', plumeDone.toString()));
    }
    if (inverterAcDone != null) {
      form.fields.add(MapEntry('inverterAcDone', inverterAcDone.toString()));
    }
    if (fullyComplete != null) {
      form.fields.add(MapEntry('fullyComplete', fullyComplete.toString()));
    }
    if (completedDate != null) {
      form.fields.add(MapEntry('completedDate', completedDate.toIso8601String()));
    }
    if (structureVendorName != null) {
      form.fields.add(MapEntry('structureVendorName', structureVendorName));
    }
    if (structureVendorCo != null) {
      form.fields.add(MapEntry('structureVendorCo', structureVendorCo));
    }
    if (wiringVendorName != null) {
      form.fields.add(MapEntry('wiringVendorName', wiringVendorName));
    }
    if (wiringVendorCo != null) {
      form.fields.add(MapEntry('wiringVendorCo', wiringVendorCo));
    }
    if (notes != null) form.fields.add(MapEntry('notes', notes));
    for (final p in beforePhotos) {
      form.files.add(
        MapEntry(
          'beforePhotos',
          MultipartFile.fromBytes(p.bytes, filename: p.filename),
        ),
      );
    }
    for (final p in afterPhotos) {
      form.files.add(
        MapEntry(
          'afterPhotos',
          MultipartFile.fromBytes(p.bytes, filename: p.filename),
        ),
      );
    }
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/installation',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editAgreementUpload(
    String id, {
    bool? agreementUploaded,
    bool? installationDetailsProvided,
    String? status,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/agreement-upload',
      data: {
        if (agreementUploaded != null) 'agreementUploaded': agreementUploaded,
        if (installationDetailsProvided != null)
          'installationDetailsProvided': installationDetailsProvided,
        if (status != null) 'status': status,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editMeter(
    String id, {
    DateTime? applicationDate,
    DateTime? inspectionDate,
    DateTime? installedDate,
    bool? gebFileHandover,
    String? meterInstallationStatus,
    String? systemRunStatus,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/meter',
      data: {
        if (applicationDate != null)
          'applicationDate': applicationDate.toIso8601String(),
        if (inspectionDate != null)
          'inspectionDate': inspectionDate.toIso8601String(),
        if (installedDate != null)
          'installedDate': installedDate.toIso8601String(),
        if (gebFileHandover != null) 'gebFileHandover': gebFileHandover,
        if (meterInstallationStatus != null)
          'meterInstallationStatus': meterInstallationStatus,
        if (systemRunStatus != null) 'systemRunStatus': systemRunStatus,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editPortal(
    String id, {
    String? applicationId,
    String? status,
    String? notes,
    Map<String, PickedPhoto> documents = const {},
  }) async {
    final form = FormData();
    if (applicationId != null) {
      form.fields.add(MapEntry('applicationId', applicationId));
    }
    if (status != null) form.fields.add(MapEntry('status', status));
    if (notes != null) form.fields.add(MapEntry('notes', notes));
    for (final e in documents.entries) {
      form.files.add(
        MapEntry(
          e.key,
          MultipartFile.fromBytes(e.value.bytes, filename: e.value.filename),
        ),
      );
    }
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/portal',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editSubsidy(
    String id, {
    bool? subsidyClaim,
    bool? receivedAmount,
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/subsidy',
      data: {
        if (subsidyClaim != null) 'subsidyClaim': subsidyClaim,
        if (receivedAmount != null) 'receivedAmount': receivedAmount,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }

  Future<SolarLeadsModel> editPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? notes,
  }) async {
    final res = await client.dio.patch(
      '${ApiEndpoints.solarLead}/$id/payment',
      data: {
        'amount': amount,
        'mode': mode,
        'type': type,
        if (notes != null) 'notes': notes,
      },
    );
    return _parse(res.data);
  }
}
