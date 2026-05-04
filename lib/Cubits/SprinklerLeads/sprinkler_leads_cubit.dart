// lib/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Repository/sprinkler_leads_repository.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'sprinkler_leads_state.dart';

class SprinklerLeadCubit extends Cubit<SprinklerLeadState> {
  final SprinklerLeadRepository _repo;

  SprinklerLeadCubit()
    : _repo = SprinklerLeadRepository(DioClient()),
      super(SprinklerLeadInitial());

  // ── FETCH ALL LEADS ───────────────────────────────────────────────────────
  Future<void> fetchAllLeads({String? status, String? search}) async {
    emit(SprinklerLeadLoading());
    try {
      final leads = await _repo.getAllLeads(status: status, search: search);
      emit(SprinklerLeadsLoaded(leads));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── REFRESH SINGLE LEAD ───────────────────────────────────────────────────
  Future<void> refreshLead(String leadId) async {
    try {
      final updated = await _repo.getSingleLead(leadId);
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── CREATE LEAD ───────────────────────────────────────────────────────────
  Future<void> createLead(SprinklerLeadModel lead) async {
    emit(SprinklerLeadLoading());
    try {
      final created = await _repo.createLead(lead);
      emit(SprinklerLeadSaved(created));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── DELETE LEAD (admin only) ──────────────────────────────────────────────
  Future<void> deleteLead(String leadId) async {
    emit(SprinklerLeadLoading());
    try {
      await _repo.deleteLead(leadId);
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 1: UPDATE BASIC INFO ─────────────────────────────────────────────
  Future<void> updateBasicInfo(
    String leadId, {
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
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateBasicInfo(
        leadId,
        customerName: customerName,
        phone: phone,
        address: address,
        village: village,
        farmSize: farmSize,
        waterSource: waterSource,
        cropType: cropType,
        source: source,
        referenceName: referenceName,
        note: note,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 2: SITE VISIT ────────────────────────────────────────────────────
  Future<void> saveSiteVisit(
    String leadId, {
    DateTime? visitDate,
    String? visitTime,
    String? salesPerson,
    String? fieldConditionNotes,
    String? waterAvailabilityNotes,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateSiteVisit(
        leadId,
        visitDate: visitDate,
        visitTime: visitTime,
        salesPerson: salesPerson,
        fieldConditionNotes: fieldConditionNotes,
        waterAvailabilityNotes: waterAvailabilityNotes,
        notes: notes,
        photos: photos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 3: VISIT DATA ────────────────────────────────────────────────────
  Future<void> saveVisitData(
    String leadId, {
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
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateVisitData(
        leadId,
        noOfPanels: noOfPanels,
        pumpCapacity: pumpCapacity,
        typeOfPump: typeOfPump,
        deliveryPipeLength: deliveryPipeLength,
        noOfSprinklers: noOfSprinklers,
        cableLength: cableLength,
        typeOfSite: typeOfSite,
        notes: notes,
        photos: photos,
      );

      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 4: QUOTATION ─────────────────────────────────────────────────────
  Future<void> saveQuotation(
    String leadId, {
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
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateQuotation(
        leadId,
        lineItems: lineItems,
        noOfPanels: noOfPanels,
        noOfKW: noOfKW,
        noOfSprinklerSet: noOfSprinklerSet,
        typeOfSprinkler: typeOfSprinkler,
        pumpDetails: pumpDetails,
        sprinkleType: sprinkleType,
        upvcPipeSizes: upvcPipeSizes,
        cableDetails: cableDetails,
        upvcFittings: upvcFittings,
        controlPanel: controlPanel,
        pipeLength: pipeLength,
        sprinklerQty: sprinklerQty,
        fittings: fittings,
        labourCost: labourCost,
        transportCost: transportCost,
        totalAmount: totalAmount,
        discount: discount,
        advancePercent: advancePercent,
        balancePercent: balancePercent,
        warrantyNote: warrantyNote,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 5: FOLLOWUP (step screen) ───────────────────────────────────────
  Future<void> saveFollowup(
    String leadId, {
    DateTime? followupDate,
    String? response,
    String? customerType,
    String? remarks,
    String? notes,
    String? interestLevel,
    String? followupType,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateFollowup(
        leadId,
        followupDate: followupDate,
        response: response,
        customerType: customerType,
        remarks: remarks,
        notes: notes,
        interestLevel: interestLevel,
        followupType: followupType,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── EDIT FOLLOWUP (PATCH — no step advance) ──────────────────────────────
  Future<void> editFollowup(
    String leadId, {
    DateTime? followupDate,
    String? response,
    String? customerType,
    String? remarks,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.editFollowup(
        leadId,
        followupDate: followupDate,
        response: response,
        customerType: customerType,
        remarks: remarks,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── ADD FOLLOWUP ENTRY (history) ─────────────────────────────────────────
  Future<void> addFollowupEntry(
    String leadId, {
    required String remark,
    required String followupType,
    required DateTime nextFollowupDate,
    int? callDuration,
    String? attachment,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.addFollowupEntry(
        leadId,
        remark: remark,
        followupType: followupType,
        nextFollowupDate: nextFollowupDate,
        callDuration: callDuration,
        attachment: attachment,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── GET FOLLOWUP HISTORY ──────────────────────────────────────────────────
  Future<List<FollowupHistoryEntry>> getFollowupHistory(String leadId) async {
    try {
      return await _repo.getFollowupHistory(leadId);
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
      return [];
    }
  }

  // ── MARK FOLLOWUP DONE ────────────────────────────────────────────────────
  Future<void> markFollowupDone(String leadId) async {
    emit(SprinklerLeadLoading());
    try {
      emit(SprinklerLeadSaved(await _repo.markFollowupDone(leadId)));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 6: DEAL ─────────────────────────────────────────────────────────
  Future<void> saveDeal(
    String leadId, {
    double? finalDealAmount,
    double? discountGiven,
    double? advancePayment,
    String? paymentMode,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateDeal(
        leadId,
        finalDealAmount: finalDealAmount,
        discountGiven: discountGiven,
        advancePayment: advancePayment,
        paymentMode: paymentMode,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 7 (ADMIN): ASSIGN INSTALLATION TEAM ─────────────────────────────
  Future<void> assignInstaller(
    String leadId, {
    required List<String> installerIds,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.assignInstaller(
        leadId,
        installerIds: installerIds,
        scheduledDate: scheduledDate,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
      fetchAllLeads();
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 8: INSTALLATION STARTED ───────────────────────────────────────
  Future<void> saveInstallationStarted(
    String leadId, {
    DateTime? startedAt,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.startInstallation(
        leadId,
        startedAt: startedAt,
        notes: notes,
        beforePhotos: beforePhotos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 9 (INSTALLATION TEAM): COMPLETE INSTALLATION ────────────────────
  Future<void> completeInstallation(
    String leadId, {
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
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.completeInstallation(
        leadId,
        technicianName: technicianName,
        installationDate: installationDate,
        materialUsed: materialUsed,
        extraMaterial: extraMaterial,
        workNotes: workNotes,
        notes: notes,
        pendingWork: pendingWork,
        pendingWorkNote: pendingWorkNote,
        systemTested: systemTested,
        paymentReceived: paymentReceived,
        followUpDate: followUpDate,
        completedBy: completedBy,
        customerReview: customerReview,
        photos: photos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── LEGACY: saveInstallation (kept for backward compat) ──────────────────
  Future<void> saveInstallation(
    String leadId, {
    String? technicianName,
    DateTime? installationDate,
    String? materialUsed,
    String? extraMaterial,
    String? workNotes,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.completeInstallation(
        leadId,
        technicianName: technicianName,
        installationDate: installationDate,
        materialUsed: materialUsed,
        extraMaterial: extraMaterial,
        workNotes: workNotes,
        notes: notes,
        photos: photos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 10 (ADMIN): PAYMENT ──────────────────────────────────────────────
  Future<void> addPayment(
    String leadId, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? transactionId,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.addPayment(
        leadId,
        amount: amount,
        mode: mode,
        type: type,
        transactionId: transactionId,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 11 (ADMIN): REVIEW ───────────────────────────────────────────────
  Future<void> saveReview(
    String leadId, {
    required int rating,
    String? feedback,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateReview(
        leadId,
        rating: rating,
        feedback: feedback,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── INSTALLATION TEAM: GET MY ASSIGNED LEADS ─────────────────────────────
  Future<List<SprinklerLeadModel>> fetchMyInstallationLeads({
    String? status,
    String? search,
  }) async {
    try {
      return await _repo.getMyInstallationLeads(status: status, search: search);
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
      return [];
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _message(Object e) {
    final s = e.toString();
    if (s.contains('message:')) {
      final start = s.indexOf('message:') + 8;
      final end = s.contains('\n') ? s.indexOf('\n', start) : s.length;
      return s.substring(start, end).trim();
    }
    return s;
  }
}
