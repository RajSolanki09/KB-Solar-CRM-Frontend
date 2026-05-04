// lib/Cubits/SolarLeads/solar_leads_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Repository/solar_leads_repository.dart';
import 'solar_leads_state.dart';

class SolarLeadCubit extends Cubit<SolarLeadState> {
  final SolarLeadRepository _repo;
  SolarLeadCubit(this._repo) : super(SolarLeadInitial());

  String _msg(Object e) => e.toString().replaceAll("Exception: ", "");

  // ── CREATE ────────────────────────────────────────────────────────────────
  // referenceName is embedded in the lead model and sent via toCreateJson()
  Future<void> createLead(SolarLeadsModel lead) async {
    emit(SolarLeadLoading());
    try {
      emit(SolarLeadSaved(await _repo.createLead(lead)));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── GET ALL ───────────────────────────────────────────────────────────────
  Future<void> fetchAllLeads({String? status, String? search}) async {
    emit(SolarLeadLoading());
    try {
      final leads = await _repo.getAllLeads(status: status, search: search);
      emit(
        SolarLeadsLoaded(leads: leads, total: leads.length, page: 1, pages: 1),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── REFRESH SINGLE ────────────────────────────────────────────────────────
  Future<void> refreshLead(String id) async {
    try {
      emit(SolarLeadDetailLoaded(await _repo.getSingleLead(id)));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PUT — first-time submit (advances stage)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> scheduleVisit(
    String id, {
    DateTime? visitDate,
    String? salesAssignedId,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateVisitSchedule(
            id,
            visitDate: visitDate,
            salesAssignedId: salesAssignedId,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 4: QUOTATION ─────────────────────────────────────────────────────
  Future<void> saveQuotation(
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
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateQuotation(
            id,
            systemSize: systemSize,
            panelType: panelType,
            inverterType: inverterType,
            structureType: structureType,
            wiringDetails: wiringDetails,
            rooftopSystemCost: rooftopSystemCost,
            elevatedStructureCost: elevatedStructureCost,
            netMeterCost: netMeterCost,
            premiumOtherCost: premiumOtherCost,
            totalAmount: totalAmount,
            subsidyAmount: subsidyAmount,
            advancePercent: advancePercent,
            balancePercent: balancePercent,
            warrantyNote: warrantyNote,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 5: FOLLOWUP ─────────────────────────────────────────────────────
  Future<void> saveFollowup(
    String id, {
    DateTime? followupDate,
    String? notes,
    String? outcome,
    String? customerType,
    String? interestLevel,
    String? followupType,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateFollowup(
            id,
            followupDate: followupDate,
            notes: notes,
            outcome: outcome,
            customerType: customerType,
            interestLevel: interestLevel,
            followupType: followupType,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── ADD FOLLOWUP ENTRY ────────────────────────────────────────────────────
  Future<void> addFollowupEntry(
    String id, {
    required String remark,
    required String followupType,
    required DateTime nextFollowupDate,
    int? callDuration,
    String? attachment,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.addFollowupEntry(
            id,
            remark: remark,
            followupType: followupType,
            nextFollowupDate: nextFollowupDate,
            callDuration: callDuration,
            attachment: attachment,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── GET FOLLOWUP HISTORY ──────────────────────────────────────────────────
  Future<void> loadFollowupHistory(String id) async {
    emit(SolarLeadLoading());
    try {
      final history = await _repo.getFollowupHistory(id);
      emit(SolarFollowupHistoryLoaded(history));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── MARK FOLLOWUP DONE ──────────────────────────────────────────────────
  Future<void> markFollowupDone(String id) async {
    emit(SolarLeadLoading());
    try {
      emit(SolarLeadSaved(await _repo.markFollowupDone(id)));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 6: DEAL ──────────────────────────────────────────────────────────
  Future<void> saveDeal(
    String id, {
    double? finalAmount,
    double? advancePayment,
    String? paymentMode,
    DateTime? expectedInstallDate,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateDeal(
            id,
            finalAmount: finalAmount,
            advancePayment: advancePayment,
            paymentMode: paymentMode,
            expectedInstallDate: expectedInstallDate,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 7: INSTALLATION ASSIGNED ─────────────────────────────────────────
  Future<void> saveInstallationAssign(
    String id, {
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamNames,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateInstallationAssign(
            id,
            installationTeamMemberIds: installationTeamMemberIds,
            installationTeamNames: installationTeamNames,
            scheduledDate: scheduledDate,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 8: INSTALLATION STARTED ──────────────────────────────────────────
  Future<void> saveInstallationStarted(
    String id, {
    String? teamAssigned,
    DateTime? startDate,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateInstallationStarted(
            id,
            teamAssigned: teamAssigned,
            startDate: startDate,
            notes: notes,
            beforePhotos: beforePhotos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 9: INSTALLATION COMPLETED ────────────────────────────────────────
  Future<void> saveInstallation(
    String id, {
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
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateInstallation(
            id,
            systemTested: systemTested,
            customerSigned: customerSigned,
            structureDone: structureDone,
            wiringDone: wiringDone,
            plumeDone: plumeDone,
            inverterAcDone: inverterAcDone,
            fullyComplete: fullyComplete,
            completedDate: completedDate,
            structureVendorName: structureVendorName,
            structureVendorCo: structureVendorCo,
            wiringVendorName: wiringVendorName,
            wiringVendorCo: wiringVendorCo,
            notes: notes,
            afterPhotos: afterPhotos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 10: AGREEMENT UPLOAD ───────────────────────────────────────────
  Future<void> saveAgreementUpload(
    String id, {
    bool agreementUploaded = false,
    bool installationDetailsProvided = false,
    String? status,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateAgreementUpload(
            id,
            agreementUploaded: agreementUploaded,
            installationDetailsProvided: installationDetailsProvided,
            status: status,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 10: METER ────────────────────────────────────────────────────────
  Future<void> saveMeter(
    String id, {
    DateTime? applicationDate,
    DateTime? inspectionDate,
    DateTime? installedDate,
    bool? gebFileHandover,
    String? meterInstallationStatus,
    String? systemRunStatus,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateMeter(
            id,
            applicationDate: applicationDate,
            inspectionDate: inspectionDate,
            installedDate: installedDate,
            gebFileHandover: gebFileHandover,
            meterInstallationStatus: meterInstallationStatus,
            systemRunStatus: systemRunStatus,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 11: PORTAL ───────────────────────────────────────────────────────
  Future<void> savePortal(
    String id, {
    String? applicationId,
    String? status,
    String? notes,
    Map<String, PickedPhoto> documents = const {},
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updatePortal(
            id,
            applicationId: applicationId,
            status: status,
            notes: notes,
            documents: documents,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 12: SUBSIDY ──────────────────────────────────────────────────────
  Future<void> saveSubsidy(
    String id, {
    bool? subsidyClaim,
    bool? receivedAmount,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateSubsidy(
            id,
            subsidyClaim: subsidyClaim,
            receivedAmount: receivedAmount,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 13: PAYMENT ──────────────────────────────────────────────────────
  Future<void> addPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.addPayment(
            id,
            amount: amount,
            mode: mode,
            type: type,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLead(String id) async {
    emit(SolarLeadLoading());
    try {
      await _repo.deleteLead(id);
      emit(SolarLeadSuccess());
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── UPDATE BASIC INFO ─────────────────────────────────────────────────────
  // Edits core customer fields (name, phone, address, source, etc.)
  // without advancing the pipeline step.
  Future<void> updateBasicInfo(
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
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateBasicInfo(
            id,
            customerName: customerName,
            mobile: mobile,
            address: address,
            village: village,
            landSize: landSize,
            requiredKW: requiredKW,
            electricityConnection: electricityConnection,
            source: source,
            referenceName: referenceName,
            note: note,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PATCH — edit existing data (NO stage advance)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> editVisitSchedule(
    String id, {
    DateTime? visitDate,
    String? salesAssignedId,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editVisitSchedule(
            id,
            visitDate: visitDate,
            salesAssignedId: salesAssignedId,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 2b: TECHNICAL VISIT ──────────────────────────────────────────────
  Future<void> markTechnicalVisit(
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
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateTechnicalVisit(
            id,
            systemKW: systemKW,
            meterPhase: meterPhase,
            inverterBoardType: inverterBoardType,
            panelBoardType: panelBoardType,
            panelCapacity: panelCapacity,
            cableType: cableType,
            acDBType: acDBType,
            structureHeight: structureHeight,
            beamLineDetails: beamLineDetails,
            totalArray: totalArray,
            scaffoldingDetails: scaffoldingDetails,
            panelLayout: panelLayout,
            lugType: lugType,
            dbConfigSingle: dbConfigSingle,
            dbConfigThree: dbConfigThree,
            estimatedCost: estimatedCost,
            additionalNotes: additionalNotes,
            photos: photos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editTechnicalVisit(
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
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editTechnicalVisit(
            id,
            systemKW: systemKW,
            meterPhase: meterPhase,
            inverterBoardType: inverterBoardType,
            panelBoardType: panelBoardType,
            panelCapacity: panelCapacity,
            cableType: cableType,
            acDBType: acDBType,
            structureHeight: structureHeight,
            beamLineDetails: beamLineDetails,
            totalArray: totalArray,
            scaffoldingDetails: scaffoldingDetails,
            panelLayout: panelLayout,
            lugType: lugType,
            dbConfigSingle: dbConfigSingle,
            dbConfigThree: dbConfigThree,
            estimatedCost: estimatedCost,
            additionalNotes: additionalNotes,
            photos: photos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editQuotation(
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
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editQuotation(
            id,
            systemSize: systemSize,
            panelType: panelType,
            inverterType: inverterType,
            structureType: structureType,
            wiringDetails: wiringDetails,
            rooftopSystemCost: rooftopSystemCost,
            elevatedStructureCost: elevatedStructureCost,
            netMeterCost: netMeterCost,
            premiumOtherCost: premiumOtherCost,
            totalAmount: totalAmount,
            subsidyAmount: subsidyAmount,
            advancePercent: advancePercent,
            balancePercent: balancePercent,
            warrantyNote: warrantyNote,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editFollowup(
    String id, {
    DateTime? followupDate,
    String? notes,
    String? outcome,
    String? customerType,
    String? interestLevel,
    String? followupType,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editFollowup(
            id,
            followupDate: followupDate,
            notes: notes,
            outcome: outcome,
            customerType: customerType,
            interestLevel: interestLevel,
            followupType: followupType,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editDeal(
    String id, {
    double? finalAmount,
    double? advancePayment,
    String? paymentMode,
    DateTime? expectedInstallDate,
    String? installationTeamMemberId,
    String? installationTeamName,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editDeal(
            id,
            finalAmount: finalAmount,
            advancePayment: advancePayment,
            paymentMode: paymentMode,
            expectedInstallDate: expectedInstallDate,
            installationTeamMemberId: installationTeamMemberId,
            installationTeamName: installationTeamName,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editInstallationAssign(
    String id, {
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamNames,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editInstallationAssign(
            id,
            installationTeamMemberIds: installationTeamMemberIds,
            installationTeamNames: installationTeamNames,
            scheduledDate: scheduledDate,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editInstallation(
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
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editInstallation(
            id,
            teamAssigned: teamAssigned,
            systemTested: systemTested,
            customerSigned: customerSigned,
            structureDone: structureDone,
            wiringDone: wiringDone,
            plumeDone: plumeDone,
            inverterAcDone: inverterAcDone,
            fullyComplete: fullyComplete,
            completedDate: completedDate,
            structureVendorName: structureVendorName,
            structureVendorCo: structureVendorCo,
            wiringVendorName: wiringVendorName,
            wiringVendorCo: wiringVendorCo,
            notes: notes,
            beforePhotos: beforePhotos,
            afterPhotos: afterPhotos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editAgreementUpload(
    String id, {
    bool? agreementUploaded,
    bool? installationDetailsProvided,
    String? status,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editAgreementUpload(
            id,
            agreementUploaded: agreementUploaded,
            installationDetailsProvided: installationDetailsProvided,
            status: status,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editMeter(
    String id, {
    DateTime? applicationDate,
    DateTime? inspectionDate,
    DateTime? installedDate,
    bool? gebFileHandover,
    String? meterInstallationStatus,
    String? systemRunStatus,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editMeter(
            id,
            applicationDate: applicationDate,
            inspectionDate: inspectionDate,
            installedDate: installedDate,
            gebFileHandover: gebFileHandover,
            meterInstallationStatus: meterInstallationStatus,
            systemRunStatus: systemRunStatus,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editPortal(
    String id, {
    String? applicationId,
    String? status,
    String? notes,
    Map<String, PickedPhoto> documents = const {},
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editPortal(
            id,
            applicationId: applicationId,
            status: status,
            notes: notes,
            documents: documents,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editSubsidy(
    String id, {
    bool? subsidyClaim,
    bool? receivedAmount,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editSubsidy(
            id,
            subsidyClaim: subsidyClaim,
            receivedAmount: receivedAmount,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editPayment(
            id,
            amount: amount,
            mode: mode,
            type: type,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }
}
