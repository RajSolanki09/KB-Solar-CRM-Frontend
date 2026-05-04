// lib/data/Models/solar_leads_model.dart

// -- Step enum -----------------------------------------------------------------
enum SolarStep {
  newLead, // 0
  visitScheduled, // 1
  technicalVisit, // 2
  quotation, // 3
  followup, // 4
  dealDone, // 5
  installationAssigned, // 6
  installationStarted, // 7
  installation, // 8
  agreementUpload, // 9
  meter, // 10
  portal, // 11
  subsidy, // 12
  payment, // 13
  projectCompleted, // 14
}

SolarStep solarStepFromString(String? v) {
  switch (v) {
    // camelCase keys (if backend ever switches)
    case 'newLead':
      return SolarStep.newLead;
    case 'visitScheduled':
      return SolarStep.visitScheduled;
    case 'technicalVisit':
      return SolarStep.technicalVisit;
    case 'quotation':
      return SolarStep.quotation;
    case 'followup':
      return SolarStep.followup;
    case 'dealDone':
      return SolarStep.dealDone;
    case 'installationAssigned':
      return SolarStep.installationAssigned;
    case 'installationStarted':
      return SolarStep.installationStarted;
    case 'installation':
      return SolarStep.installation;
    case 'agreementUpload':
      return SolarStep.agreementUpload;
    case 'meter':
      return SolarStep.meter;
    case 'portal':
      return SolarStep.portal;
    case 'subsidy':
      return SolarStep.subsidy;
    case 'payment':
      return SolarStep.payment;
    case 'projectCompleted':
      return SolarStep.projectCompleted;
    // Display strings sent by backend in "status" field
    case 'New Lead':
      return SolarStep.newLead;
    case 'Visit Scheduled':
      return SolarStep.visitScheduled;
    case 'Technical Visit':
      return SolarStep.technicalVisit;
    case 'Quotation Sent':
      return SolarStep.quotation;
    case 'Follow-up':
      return SolarStep.followup;
    case 'Followup':
      return SolarStep.followup;
    case 'Deal Closed':
      return SolarStep.dealDone;
    case 'Installation Assigned':
      return SolarStep.installationAssigned;
    case 'Installation Started':
      return SolarStep.installationStarted;
    case 'Installation Completed':
      return SolarStep.installation;
    case 'Installed':
      return SolarStep.installation;
    case 'Agreement Upload':
      return SolarStep.agreementUpload;
    case 'Agreement Uploaded':
      return SolarStep.agreementUpload;
    case 'Meter Process':
      return SolarStep.meter;
    case 'Meter Applied':
      return SolarStep.meter;
    case 'Meter Inspection':
      return SolarStep.meter;
    case 'Meter Installed':
      return SolarStep.meter;
    case 'Portal Submitted':
      return SolarStep.portal;
    case 'Subsidy Completed':
      return SolarStep.subsidy;
    case 'Payment Completed':
      return SolarStep.projectCompleted;
    case 'Project Completed':
      return SolarStep.projectCompleted;
    default:
      return SolarStep.newLead;
  }
}

SolarStep _resolveStepFromData({
  required SolarStep base,
  required InstallationAssignData assign,
  required InstallationData installation,
  required MeterData meter,
  required TechnicalVisitData technicalVisit,
  required AgreementUploadData agreementUpload,
}) {
  // Never downgrade final pipeline stages.
  if (base.index >= SolarStep.agreementUpload.index) return base;

  if (meter.applicationDate != null ||
      meter.inspectionDate != null ||
      meter.installedDate != null) {
    return SolarStep.meter;
  }

  final hasAgreementEvidence =
      agreementUpload.agreementUploaded ||
      agreementUpload.installationDetailsProvided ||
      (agreementUpload.status?.isNotEmpty ?? false);
  if (hasAgreementEvidence) {
    return SolarStep.agreementUpload;
  }

  if (installation.completedDate != null ||
      installation.systemTested ||
      installation.customerSigned ||
      installation.afterPhotos.isNotEmpty) {
    return SolarStep.installation;
  }

  if (installation.startDate != null || installation.beforePhotos.isNotEmpty) {
    return SolarStep.installationStarted;
  }

  final hasAssign =
      (assign.teamMemberId?.isNotEmpty ?? false) ||
      (assign.teamMemberName?.isNotEmpty ?? false) ||
      assign.assignedAt != null ||
      assign.scheduledDate != null;
  if (hasAssign) return SolarStep.installationAssigned;

  // Auto-advance to technical visit when visit-schedule lead already has technical data.
  if (base.index >= SolarStep.visitScheduled.index &&
      base.index < SolarStep.technicalVisit.index) {
    final hasTechnicalVisit =
        (technicalVisit.systemKW?.isNotEmpty ?? false) ||
        (technicalVisit.inverterBoardType?.isNotEmpty ?? false) ||
        (technicalVisit.panelCapacity?.isNotEmpty ?? false) ||
        technicalVisit.photos.isNotEmpty;
    if (hasTechnicalVisit) return SolarStep.technicalVisit;
  }

  return base;
}

String solarStepToDisplay(SolarStep s) {
  switch (s) {
    case SolarStep.newLead:
      return 'New Lead';
    case SolarStep.visitScheduled:
      return 'Visit Scheduled';
    case SolarStep.technicalVisit:
      return 'Technical Visit';
    case SolarStep.quotation:
      return 'Quotation Sent';
    case SolarStep.followup:
      return 'Follow-up';
    case SolarStep.dealDone:
      return 'Deal Closed';
    case SolarStep.installationAssigned:
      return 'Installation Assigned';
    case SolarStep.installationStarted:
      return 'Installation Started';
    case SolarStep.installation:
      return 'Installation Completed';
    case SolarStep.agreementUpload:
      return 'Agreement Upload';
    case SolarStep.meter:
      return 'Meter Process';
    case SolarStep.portal:
      return 'Portal Submitted';
    case SolarStep.subsidy:
      return 'Subsidy Completed';
    case SolarStep.payment:
      return 'Payment Remaining';
    case SolarStep.projectCompleted:
      return 'Project Completed';
  }
}

// -- Followup history entry ----------------------------------------------------
class FollowupHistoryEntry {
  final String id;
  final String remark;
  final String interestLevel;
  final String followupType;
  final DateTime nextFollowupDate;
  final int? callDuration;
  final String? attachment;
  final DateTime createdAt;

  const FollowupHistoryEntry({
    required this.id,
    required this.remark,
    required this.interestLevel,
    required this.followupType,
    required this.nextFollowupDate,
    this.callDuration,
    this.attachment,
    required this.createdAt,
  });

  factory FollowupHistoryEntry.fromJson(Map<String, dynamic> j) =>
      FollowupHistoryEntry(
        id: j['_id']?.toString() ?? '',
        remark: j['remark']?.toString() ?? '',
        interestLevel: j['interestLevel']?.toString() ?? 'warm',
        followupType: j['followupType']?.toString() ?? 'call',
        nextFollowupDate: _parseDate(j['nextFollowupDate']) ?? DateTime.now(),
        callDuration: (j['callDuration'] as num?)?.toInt(),
        attachment: j['attachment']?.toString(),
        createdAt: _parseDate(j['createdAt']) ?? DateTime.now(),
      );
}

// -- Nested data classes -------------------------------------------------------

class VisitScheduleData {
  final DateTime? visitDate;
  final String? salesAssigned, geoLocation, notes;

  const VisitScheduleData({
    this.visitDate,
    this.salesAssigned,
    this.geoLocation,
    this.notes,
  });

  factory VisitScheduleData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const VisitScheduleData();
    return VisitScheduleData(
      visitDate: _parseDate(j['visitDate']),
      salesAssigned: j['salesAssigned']?.toString(),
      geoLocation: j['geoLocation']?.toString(),
      notes: j['notes']?.toString(),
    );
  }
}

// -- TechnicalVisitData - step 2b (after site visit) --------------------------
class TechnicalVisitData {
  final String? systemKW;
  final String? meterPhase;
  final String? inverterBoardType;
  final String? panelBoardType;
  final String? panelCapacity;
  final String? cableType;
  final String? acDBType;
  final String? structureHeight;
  final String? beamLineDetails;
  final String? totalArray;
  final String? scaffoldingDetails;
  final String? panelLayout;
  final String? lugType;
  final String? dbConfigSingle;
  final String? dbConfigThree;
  final String? estimatedCost;
  final String? additionalNotes;
  final List<String> photos;

  const TechnicalVisitData({
    this.systemKW,
    this.meterPhase,
    this.inverterBoardType,
    this.panelBoardType,
    this.panelCapacity,
    this.cableType,
    this.acDBType,
    this.structureHeight,
    this.beamLineDetails,
    this.totalArray,
    this.scaffoldingDetails,
    this.panelLayout,
    this.lugType,
    this.dbConfigSingle,
    this.dbConfigThree,
    this.estimatedCost,
    this.additionalNotes,
    this.photos = const [],
  });

  factory TechnicalVisitData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const TechnicalVisitData();
    return TechnicalVisitData(
      systemKW: j['systemKW']?.toString(),
      meterPhase: j['meterPhase']?.toString(),
      inverterBoardType: j['inverterBoardType']?.toString(),
      panelBoardType: j['panelBoardType']?.toString(),
      panelCapacity: j['panelCapacity']?.toString(),
      cableType: j['cableType']?.toString(),
      acDBType: j['acDBType']?.toString(),
      structureHeight: j['structureHeight']?.toString(),
      beamLineDetails: j['beamLineDetails']?.toString(),
      totalArray: j['totalArray']?.toString(),
      scaffoldingDetails: j['scaffoldingDetails']?.toString(),
      panelLayout: j['panelLayout']?.toString(),
      lugType: j['lugType']?.toString(),
      dbConfigSingle: j['dbConfigSingle']?.toString(),
      dbConfigThree: j['dbConfigThree']?.toString(),
      estimatedCost: j['estimatedCost']?.toString(),
      additionalNotes: j['additionalNotes']?.toString(),
      photos: List<String>.from(j['technicalPhotos'] ?? j['photos'] ?? []),
    );
  }
}

class QuotationData {
  final String? systemSize,
      panelType,
      inverterType,
      structureType,
      wiringDetails,
      warrantyNote,
    notes,
    quotationPdfPath;
  final double totalAmount, subsidyAmount, customerPayable;
  final double rooftopSystemCost,
    elevatedStructureCost,
    netMeterCost,
    premiumOtherCost;
  final double? advancePercent, balancePercent;
  final DateTime? quotationPdfUploadedAt;

  const QuotationData({
    this.systemSize,
    this.panelType,
    this.inverterType,
    this.structureType,
    this.wiringDetails,
    this.warrantyNote,
    this.notes,
    this.quotationPdfPath,
    this.totalAmount = 0,
    this.subsidyAmount = 0,
    this.customerPayable = 0,
    this.rooftopSystemCost = 0,
    this.elevatedStructureCost = 0,
    this.netMeterCost = 0,
    this.premiumOtherCost = 0,
    this.advancePercent,
    this.balancePercent,
    this.quotationPdfUploadedAt,
  });

  factory QuotationData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const QuotationData();
    return QuotationData(
      systemSize: j['systemSize']?.toString(),
      panelType: j['panelType']?.toString(),
      inverterType: j['inverterType']?.toString(),
      structureType: j['structureType']?.toString(),
      wiringDetails: j['wiringDetails']?.toString(),
      warrantyNote: j['warrantyNote']?.toString(),
      notes: j['notes']?.toString(),
      quotationPdfPath: j['quotationPdfPath']?.toString(),
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
      subsidyAmount: (j['subsidyAmount'] as num?)?.toDouble() ?? 0,
      customerPayable: (j['customerPayable'] as num?)?.toDouble() ?? 0,
      rooftopSystemCost: (j['rooftopSystemCost'] as num?)?.toDouble() ?? 0,
      elevatedStructureCost:
          (j['elevatedStructureCost'] as num?)?.toDouble() ?? 0,
      netMeterCost: (j['netMeterCost'] as num?)?.toDouble() ?? 0,
      premiumOtherCost: (j['premiumOtherCost'] as num?)?.toDouble() ?? 0,
      advancePercent: (j['advancePercent'] as num?)?.toDouble(),
      balancePercent: (j['balancePercent'] as num?)?.toDouble(),
      quotationPdfUploadedAt: _parseDate(j['quotationPdfUploadedAt']),
    );
  }
}

class FollowupData {
  final DateTime? followupDate;
  final String? outcome, response, customerType, notes;

  const FollowupData({
    this.followupDate,
    this.outcome,
    this.response,
    this.customerType,
    this.notes,
  });

  factory FollowupData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const FollowupData();
    return FollowupData(
      followupDate: _parseDate(j['followupDate']),
      outcome: j['outcome']?.toString(),
      response: j['response']?.toString(),
      customerType: j['customerType']?.toString(),
      notes: j['notes']?.toString(),
    );
  }
}

class DealData {
  final double? finalDealAmount, advancePayment;
  final double discountGiven;
  final String? paymentMode, notes;
  final DateTime? expectedInstallDate;
  final DateTime? closedAt;
  final String? installationTeamMemberId;
  final String? installationTeamName;

  const DealData({
    this.finalDealAmount,
    this.discountGiven = 0,
    this.advancePayment,
    this.paymentMode,
    this.expectedInstallDate,
    this.closedAt,
    this.notes,
    this.installationTeamMemberId,
    this.installationTeamName,
  });

  factory DealData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const DealData();
    return DealData(
      finalDealAmount:
          (j['finalAmount'] as num?)?.toDouble() ??
          (j['finalDealAmount'] as num?)?.toDouble(),
      discountGiven: (j['discountGiven'] as num?)?.toDouble() ?? 0,
      advancePayment: (j['advancePayment'] as num?)?.toDouble(),
      paymentMode: j['paymentMode']?.toString(),
      expectedInstallDate: _parseDate(j['expectedInstallDate']),
      closedAt: _parseDate(j['closedAt']),
      notes: j['notes']?.toString(),
      installationTeamMemberId: j['installationTeamMemberId']?.toString(),
      installationTeamName: j['installationTeamName']?.toString(),
    );
  }
}

// -- InstallationAssignData - step 6 ------------------------------------------
class InstallationAssignData {
  /// Multi-member canonical fields
  final List<String> teamMemberIds;
  final List<String> teamMemberNames;

  final String? notes;
  final DateTime? scheduledDate, assignedAt;

  const InstallationAssignData({
    this.teamMemberIds = const [],
    this.teamMemberNames = const [],
    this.notes,
    this.scheduledDate,
    this.assignedAt,
  });

  // Backward-compat single getters (first member)
  String? get teamMemberId => teamMemberIds.isNotEmpty ? teamMemberIds.first : null;
  String? get teamMemberName => teamMemberNames.isNotEmpty ? teamMemberNames.first : null;

  factory InstallationAssignData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const InstallationAssignData();

    String? parseId(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) return raw['\$oid']?.toString();
      return raw.toString();
    }

    // Parse array of IDs
    final rawIds = j['installationTeamMemberIds'];
    final List<String> teamMemberIds;
    if (rawIds is List && rawIds.isNotEmpty) {
      teamMemberIds = rawIds
          .map(parseId)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final legacyId = parseId(j['installationTeamMemberId'] ?? j['teamMemberId']);
      teamMemberIds = legacyId != null ? [legacyId] : [];
    }

    // Parse array of names
    final rawNames = j['installationTeamNames'];
    final List<String> teamMemberNames;
    if (rawNames is List && rawNames.isNotEmpty) {
      teamMemberNames = rawNames
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final legacyName =
          j['installationTeamName']?.toString() ??
          j['teamMemberName']?.toString();
      teamMemberNames = legacyName != null ? [legacyName] : [];
    }

    return InstallationAssignData(
      teamMemberIds: teamMemberIds,
      teamMemberNames: teamMemberNames,
      notes: j['notes']?.toString(),
      scheduledDate: _parseDate(j['scheduledDate']),
      assignedAt: _parseDate(j['assignedAt']),
    );
  }
}

// InstallationData - covers both Started (step 7) and Completed (step 8)
class InstallationData {
  final String? teamAssigned, notes;
  final bool systemTested, customerSigned;
  final List<String> beforePhotos, afterPhotos;

  /// Date installation work was started (step 7)
  final DateTime? startDate;

  /// Date installation was completed/signed off (step 8)
  final DateTime? completedDate;

  // Completion checklist (step 8 form)
  final bool structureDone, wiringDone, plumeDone, inverterAcDone, fullyComplete;

  // Vendor details
  final String? structureVendorName, structureVendorCo;
  final String? wiringVendorName, wiringVendorCo;

  const InstallationData({
    this.teamAssigned,
    this.notes,
    this.systemTested = false,
    this.customerSigned = false,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.startDate,
    this.completedDate,
    this.structureDone = false,
    this.wiringDone = false,
    this.plumeDone = false,
    this.inverterAcDone = false,
    this.fullyComplete = false,
    this.structureVendorName,
    this.structureVendorCo,
    this.wiringVendorName,
    this.wiringVendorCo,
  });

  factory InstallationData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const InstallationData();
    return InstallationData(
      teamAssigned: j['teamAssigned']?.toString(),
      notes: j['notes']?.toString(),
      systemTested: j['systemTested'] as bool? ?? false,
      customerSigned: j['customerSigned'] as bool? ?? false,
      beforePhotos: List<String>.from(j['beforePhotos'] ?? []),
      afterPhotos: List<String>.from(
        j['installationPhotos'] ?? j['afterPhotos'] ?? [],
      ),
      startDate: _parseDate(j['startDate']),
      completedDate: _parseDate(
        j['completedDate'] ?? j['completedAt'] ?? j['installationDate'],
      ),
      structureDone: j['structureDone'] as bool? ?? false,
      wiringDone: j['wiringDone'] as bool? ?? false,
      plumeDone: j['plumeDone'] as bool? ?? false,
      inverterAcDone: j['inverterAcDone'] as bool? ?? false,
      fullyComplete: j['fullyComplete'] as bool? ?? false,
      structureVendorName: j['structureVendorName']?.toString(),
      structureVendorCo: j['structureVendorCo']?.toString(),
      wiringVendorName: j['wiringVendorName']?.toString(),
      wiringVendorCo: j['wiringVendorCo']?.toString(),
    );
  }
}

class MeterData {
  final DateTime? applicationDate, inspectionDate, installedDate;
  final bool? gebFileHandover;
  final String? meterInstallationStatus;
  final String? systemRunStatus;
  final String? notes;

  const MeterData({
    this.applicationDate,
    this.inspectionDate,
    this.installedDate,
    this.gebFileHandover,
    this.meterInstallationStatus,
    this.systemRunStatus,
    this.notes,
  });

  factory MeterData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const MeterData();
    return MeterData(
      applicationDate: _parseDate(j['applicationDate']),
      inspectionDate: _parseDate(j['inspectionDate']),
      installedDate: _parseDate(j['installedDate']),
      gebFileHandover: j['gebFileHandover'] is bool
          ? j['gebFileHandover'] as bool
          : (j['gebFileHandover']?.toString().toLowerCase() == 'true'
                ? true
                : (j['gebFileHandover']?.toString().toLowerCase() == 'false'
                      ? false
                      : null)),
      meterInstallationStatus: j['meterInstallationStatus']?.toString(),
      systemRunStatus: j['systemRunStatus']?.toString(),
      notes: j['notes']?.toString(),
    );
  }
}

class PortalData {
  final String? applicationId, status, notes;
  final Map<String, String> documents;

  const PortalData({
    this.applicationId,
    this.status,
    this.notes,
    this.documents = const {},
  });

  factory PortalData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const PortalData();
    return PortalData(
      applicationId: j['applicationId']?.toString(),
      status: j['status']?.toString(),
      notes: j['notes']?.toString(),
      documents: Map<String, String>.from(
        (j['documents'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        ),
      ),
    );
  }
}

class SubsidyData {
  final bool? subsidyClaim;
  final bool? receivedAmount;
  final String? notes;

  const SubsidyData({
    this.subsidyClaim,
    this.receivedAmount,
    this.notes,
  });

  factory SubsidyData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SubsidyData();
    return SubsidyData(
      subsidyClaim: j['subsidyClaim'] as bool?,
      receivedAmount: j['receivedAmount'] as bool?,
      notes: j['notes']?.toString(),
    );
  }
}

class AgreementUploadData {
  final bool agreementUploaded;
  final bool installationDetailsProvided;
  final String? status;

  const AgreementUploadData({
    this.agreementUploaded = false,
    this.installationDetailsProvided = false,
    this.status,
  });

  factory AgreementUploadData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const AgreementUploadData();
    return AgreementUploadData(
      agreementUploaded: j['agreementUploaded'] as bool? ?? false,
      installationDetailsProvided:
          j['installationDetailsProvided'] as bool? ?? false,
      status: j['status']?.toString(),
    );
  }
}

class PaymentSummary {
  final double totalAmount, amountReceived, remainingBalance;
  final List<Map<String, dynamic>> history;

  const PaymentSummary({
    this.totalAmount = 0,
    this.amountReceived = 0,
    this.remainingBalance = 0,
    this.history = const [],
  });

  factory PaymentSummary.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const PaymentSummary();
    return PaymentSummary(
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
      amountReceived: (j['amountReceived'] as num?)?.toDouble() ?? 0,
      remainingBalance: (j['remainingBalance'] as num?)?.toDouble() ?? 0,
      history: List<Map<String, dynamic>>.from(
        (j['paymentHistory'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  MAIN MODEL
// -----------------------------------------------------------------------------
class SolarLeadsModel {
  // -- Workflow step labels - 14 entries (index 0-13) ------------------------
  static List<String> get workflowSteps => [
    'New Lead', // 0
    'Visit Scheduled', // 1
    'Technical Visit', // 2
    'Quotation Sent', // 3
    'Follow-up', // 4
    'Deal Closed', // 5
    'Installation Assigned', // 6
    'Installation Started', // 7
    'Installation Completed', // 8
    'Agreement Upload', // 9
    'Meter Process', // 10
    'Portal Submitted', // 11
    'Subsidy Completed', // 12
    'Payment Remaining', // 13
    'Project Completed', // 14
  ];

  // -- Core fields -----------------------------------------------------------
  final String id, customerName, mobile, address, village;
  final double? landSize, requiredKW;
  final String? electricityConnection, source, note;

  /// Populated only when source == 'reference'
  final String? referenceName;

  final String? createdBy;

  final SolarStep currentStep;
  final bool isCompleted;

  // -- Nested data -----------------------------------------------------------
  final VisitScheduleData visitScheduleData;
  final TechnicalVisitData technicalVisitData;
  final QuotationData quotationData;
  final FollowupData followupData;
  final DealData dealData;
  final InstallationAssignData installationAssignData; // step 6
  final InstallationData installationData; // steps 7 + 8
  final MeterData meterData;
  final PortalData portalData;
  final SubsidyData subsidyData;
  final AgreementUploadData agreementUploadData;
  final PaymentSummary paymentSummary;

  // -- Followup system -------------------------------------------------------
  final List<FollowupHistoryEntry> followupHistory;
  final String? interestLevel, followupType, lastRemark;
  final DateTime? nextFollowupDate, lastFollowupDate;
  final int followupCount, missedFollowupCount;

  final DateTime createdAt, updatedAt;

  const SolarLeadsModel({
    required this.id,
    required this.customerName,
    required this.mobile,
    required this.address,
    this.village = '',
    this.landSize,
    this.requiredKW,
    this.electricityConnection,
    this.source,
    this.note,
    this.referenceName, // - NEW
    this.createdBy,
    this.currentStep = SolarStep.newLead,
    this.isCompleted = false,
    this.visitScheduleData = const VisitScheduleData(),
    this.technicalVisitData = const TechnicalVisitData(),
    this.quotationData = const QuotationData(),
    this.followupData = const FollowupData(),
    this.dealData = const DealData(),
    this.installationAssignData = const InstallationAssignData(),
    this.installationData = const InstallationData(),
    this.meterData = const MeterData(),
    this.portalData = const PortalData(),
    this.subsidyData = const SubsidyData(),
    this.agreementUploadData = const AgreementUploadData(),
    this.paymentSummary = const PaymentSummary(),
    this.followupHistory = const [],
    this.interestLevel,
    this.followupType,
    this.lastRemark,
    this.nextFollowupDate,
    this.lastFollowupDate,
    this.followupCount = 0,
    this.missedFollowupCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // -- Convenience getters - visit schedule ---------------------------------
  String get status => solarStepToDisplay(currentStep);
  DateTime? get visitDate => visitScheduleData.visitDate;
  String? get salesAssigned => visitScheduleData.salesAssigned;
  String? get geoLocation => visitScheduleData.geoLocation;
  String? get visitNotes => visitScheduleData.notes;

  // -- Convenience getters - technical visit -------------------------------
  List<String> get technicalPhotoPaths => technicalVisitData.photos;

  // -- Convenience getters - quotation --------------------------------------
  String? get systemSize => quotationData.systemSize;
  String? get panelType => quotationData.panelType;
  String? get inverterType => quotationData.inverterType;
  String? get structureType => quotationData.structureType;
  String? get wiringDetails => quotationData.wiringDetails;
  double get rooftopSystemCost => quotationData.rooftopSystemCost;
  double get elevatedStructureCost => quotationData.elevatedStructureCost;
  double get netMeterCost => quotationData.netMeterCost;
  double get premiumOtherCost => quotationData.premiumOtherCost;
  double get totalAmount => quotationData.totalAmount;
  double? get subsidyAmount =>
      quotationData.subsidyAmount > 0 ? quotationData.subsidyAmount : null;
  double get customerPayable => quotationData.customerPayable;
  String? get quotationPdfPath => quotationData.quotationPdfPath;

  // -- Convenience getters - followup ----------------------------------------
  DateTime? get followupDate => followupData.followupDate;
  String? get followupOutcome => followupData.response ?? followupData.outcome;

  // -- Convenience getters - deal --------------------------------------------
  double? get finalAmount => dealData.finalDealAmount;
  double? get advancePayment => dealData.advancePayment;
  String? get paymentMode => dealData.paymentMode;
  DateTime? get expectedInstallDate => dealData.expectedInstallDate;
  DateTime? get dealClosedAt => dealData.closedAt;

  // -- Convenience getters - installation assign (step 6) -------------------

  /// All assigned member IDs (multi-member support)
  List<String> get installationTeamMemberIds => installationAssignData.teamMemberIds;

  /// All assigned member names (multi-member support)
  List<String> get installationTeamMemberNames => installationAssignData.teamMemberNames;

  /// First member - backward compat with legacy single-member screens
  String? get installationTeam =>
      installationAssignData.teamMemberName ??
      dealData.installationTeamName; // fallback for legacy data
  String? get installationTeamId =>
      installationAssignData.teamMemberId ?? dealData.installationTeamMemberId;

  /// Aliases - match legacy field names used across dashboard/pipeline screens
  String? get installationTeamName => installationTeam;
  String? get installationTeamMemberId => installationTeamId;

  // -- Convenience getters - installation (steps 7 + 8) ---------------------
  bool get systemTested => installationData.systemTested;
  bool get customerSigned => installationData.customerSigned;
  List<String> get beforePhotoPaths => installationData.beforePhotos;
  List<String> get afterPhotoPaths => installationData.afterPhotos;

  /// Date installation work started (step 7)
  DateTime? get installationStartDate => installationData.startDate;

  /// Date installation was completed (step 8)
  DateTime? get installationCompletedDate => installationData.completedDate;

  // -- Convenience getters - meter -------------------------------------------
  DateTime? get meterApplicationDate => meterData.applicationDate;
  DateTime? get meterInspectionDate => meterData.inspectionDate;
  DateTime? get meterInstalledDate => meterData.installedDate;
  bool? get meterGebFileHandover => meterData.gebFileHandover;
  String? get meterInstallationStatus => meterData.meterInstallationStatus;
  String? get meterSystemRunStatus => meterData.systemRunStatus;

  // -- Convenience getters - portal ------------------------------------------
  String? get applicationId => portalData.applicationId;
  String? get portalStatus => portalData.status;
  Map<String, String> get portalDocuments => portalData.documents;

  // -- Convenience getters - subsidy -----------------------------------------
  bool? get subsidyClaim => subsidyData.subsidyClaim;
  bool? get subsidyReceivedAmount => subsidyData.receivedAmount;

  // -- Convenience getters - payment -----------------------------------------
  double get paidAmount => paymentSummary.amountReceived;
  double get pendingAmount => paymentSummary.remainingBalance;
  List<Map<String, dynamic>> get paymentHistory => paymentSummary.history;
  bool get isFullyPaid =>
      pendingAmount <= 0 && currentStep.index >= SolarStep.payment.index;

  // -- Followup status -------------------------------------------------------
  String? get followupStatus {
    if (isCompleted) return 'completed';
    if (nextFollowupDate == null) return null;
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final nextMid = DateTime(
      nextFollowupDate!.year,
      nextFollowupDate!.month,
      nextFollowupDate!.day,
    );
    if (nextMid.isBefore(todayMid)) return 'overdue';
    if (nextMid.isAtSameMomentAs(todayMid)) return 'today';
    return 'pending';
  }

  // -- toCreateJson ----------------------------------------------------------
  Map<String, dynamic> toCreateJson() => {
    'customerName': customerName,
    'mobile': mobile,
    'address': address,
    if (village.isNotEmpty) 'village': village,
    if (landSize != null) 'landSize': landSize,
    if (requiredKW != null) 'requiredKW': requiredKW,
    if (electricityConnection != null)
      'electricityConnection': electricityConnection,
    if (source != null) 'source': source,
    // Only send referenceName when source is 'reference' and value is non-empty
    if (source == 'reference' && referenceName != null && referenceName!.isNotEmpty)
      'referenceName': referenceName,
    if (note?.isNotEmpty == true) 'note': note,
  };

  // -- fromJson --------------------------------------------------------------
  factory SolarLeadsModel.fromJson(Map<String, dynamic> json) {
    final j = json.containsKey('lead')
        ? json['lead'] as Map<String, dynamic>
        : json;

    String? createdBy;
    final rawCreatedBy = j['createdBy'];
    if (rawCreatedBy is Map) {
      createdBy =
          rawCreatedBy['name']?.toString() ??
          rawCreatedBy['fullName']?.toString() ??
          rawCreatedBy['username']?.toString();
    } else if (rawCreatedBy is String && rawCreatedBy.trim().isNotEmpty) {
      createdBy = rawCreatedBy.trim();
    }

    createdBy ??=
        j['createdByName']?.toString() ??
        j['creatorName']?.toString() ??
        j['created_by_name']?.toString();

    final installationAssignData = InstallationAssignData.fromJson(
      (j['installationAssign'] ?? j['installation_assign'])
          as Map<String, dynamic>?,
    );
    final quotationData = QuotationData.fromJson(
      j['quotation'] as Map<String, dynamic>?,
    );
    final dealData = DealData.fromJson(j['deal'] as Map<String, dynamic>?);
    final installationData = InstallationData.fromJson(
      j['installation'] as Map<String, dynamic>?,
    );
    final meterData = MeterData.fromJson(j['meter'] as Map<String, dynamic>?);
    final technicalVisitData = TechnicalVisitData.fromJson(j['technicalVisit'] as Map<String, dynamic>?);
    final agreementUploadData = AgreementUploadData.fromJson(
      (j['agreementUpload'] ?? j['agreement_upload']) as Map<String, dynamic>?,
    );
    final paymentSummary = PaymentSummary.fromJson(
      j['payment'] as Map<String, dynamic>?,
    );

    final rawStep = solarStepFromString(
      j['currentStep']?.toString() ?? j['status']?.toString(),
    );
    final resolvedStep = _resolveStepFromData(
      base: rawStep,
      assign: installationAssignData,
      installation: installationData,
      meter: meterData,
      technicalVisit: technicalVisitData,
      agreementUpload: agreementUploadData,
    );

    final backendCompleted =
      j['isCompleted'] as bool? ?? j['projectCompleted'] as bool? ?? false;
    final expectedPayable =
      (dealData.finalDealAmount ?? quotationData.customerPayable).toDouble();
    final paymentRequired = expectedPayable > 0;
    final hasPaymentEvidence =
      paymentSummary.history.isNotEmpty || paymentSummary.amountReceived > 0;
    final resolvedIsCompleted =
      backendCompleted && (!paymentRequired || hasPaymentEvidence);

    return SolarLeadsModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      customerName: j['customerName']?.toString() ?? '',
      mobile: j['mobile']?.toString() ?? j['phone']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      village: j['village']?.toString() ?? '',
      landSize: (j['landSize'] as num?)?.toDouble(),
      requiredKW: (j['requiredKW'] as num?)?.toDouble(),
      electricityConnection: j['electricityConnection']?.toString(),
      source: j['source']?.toString(),
      note: j['note']?.toString(),
      referenceName: j['referenceName']?.toString(), // - NEW
      createdBy: createdBy,
      currentStep: resolvedStep,
      isCompleted: resolvedIsCompleted,

      visitScheduleData: VisitScheduleData.fromJson(
        (j['visitScheduled'] ?? j['visitSchedule']) as Map<String, dynamic>?,
      ),
      technicalVisitData: technicalVisitData,
      quotationData: quotationData,
      followupData: FollowupData.fromJson(
        j['followup'] as Map<String, dynamic>?,
      ),
      dealData: dealData,
      installationAssignData: installationAssignData,
      installationData: installationData,
      meterData: meterData,
      portalData: PortalData.fromJson(j['portal'] as Map<String, dynamic>?),
      subsidyData: SubsidyData.fromJson(j['subsidy'] as Map<String, dynamic>?),
      agreementUploadData: agreementUploadData,
      paymentSummary: paymentSummary,

      followupHistory: (j['followupHistory'] as List? ?? [])
          .map((e) => FollowupHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      interestLevel: j['interestLevel']?.toString(),
      followupType: j['followupType']?.toString(),
      lastRemark: j['lastRemark']?.toString(),
      nextFollowupDate: _parseDate(j['nextFollowupDate']),
      lastFollowupDate: _parseDate(j['lastFollowupDate']),
      followupCount: (j['followupCount'] as num?)?.toInt() ?? 0,
      missedFollowupCount: (j['missedFollowupCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(j['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(j['updatedAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString()).toLocal();
  } catch (_) {
    return null;
  }
}


