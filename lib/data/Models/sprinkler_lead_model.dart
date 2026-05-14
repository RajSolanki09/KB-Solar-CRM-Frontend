// lib/data/Models/sprinkler_lead_model.dart

enum SprinklerStep {
  newLead,
  siteVisit,
  visitData,
  quotation,
  followup,
  dealDone,
  installationAssigned,
  installationStarted,
  installationCompleted,
  systemTested,
  fullPayment,
  projectCompleted,
}

SprinklerStep sprinklerStepFromString(String? v) {
  switch (v) {
    case 'newLead':
      return SprinklerStep.newLead;
    case 'siteVisit':
      return SprinklerStep.siteVisit;
    case 'visitData':
      return SprinklerStep.visitData;
    case 'quotation':
      return SprinklerStep.quotation;
    case 'technicalVisit':
      return SprinklerStep.visitData; // legacy compat
    case 'followup':
      return SprinklerStep.followup;
    case 'dealDone':
      return SprinklerStep.dealDone;
    case 'installationAssigned':
      return SprinklerStep.installationAssigned;
    case 'installationStarted':
      return SprinklerStep.installationStarted;
    case 'installationCompleted':
      return SprinklerStep.installationCompleted;
    case 'systemTested':
      return SprinklerStep.systemTested;
    case 'fullPayment':
      return SprinklerStep.fullPayment;
    case 'projectCompleted':
      return SprinklerStep.projectCompleted;
    // Display strings
    case 'New Lead':
      return SprinklerStep.newLead;
    case 'Site Visited':
      return SprinklerStep.siteVisit;
    case 'Visit Data':
      return SprinklerStep.visitData;
    case 'System Designed':
      return SprinklerStep.visitData; // legacy
    case 'Quotation Sent':
      return SprinklerStep.quotation;
    case 'Follow-up':
      return SprinklerStep.followup;
    case 'Followup':
      return SprinklerStep.followup;
    case 'Deal Closed':
      return SprinklerStep.dealDone;
    case 'Installation Assigned':
      return SprinklerStep.installationAssigned;
    case 'Installation Started':
      return SprinklerStep.installationStarted;
    case 'Installation Completed':
      return SprinklerStep.installationCompleted;
    case 'Installed':
      return SprinklerStep.installationCompleted;
    case 'System Tested':
      return SprinklerStep.systemTested;
    case 'Payment Remaining':
      return SprinklerStep.fullPayment;
    case 'Payment Completed':
      return SprinklerStep.fullPayment;
    case 'Project Completed':
      return SprinklerStep.projectCompleted;
    case 'installation':
      return SprinklerStep.installationCompleted;
    default:
      return SprinklerStep.newLead;
  }
}

String sprinklerStepToString(SprinklerStep s) {
  switch (s) {
    case SprinklerStep.newLead:
      return 'newLead';
    case SprinklerStep.siteVisit:
      return 'siteVisit';
    case SprinklerStep.visitData:
      return 'visitData';
    case SprinklerStep.quotation:
      return 'quotation';
    case SprinklerStep.followup:
      return 'followup';
    case SprinklerStep.dealDone:
      return 'dealDone';
    case SprinklerStep.installationAssigned:
      return 'installationAssigned';
    case SprinklerStep.installationStarted:
      return 'installationStarted';
    case SprinklerStep.installationCompleted:
      return 'installationCompleted';
    case SprinklerStep.systemTested:
      return 'systemTested';
    case SprinklerStep.fullPayment:
      return 'fullPayment';
    case SprinklerStep.projectCompleted:
      return 'projectCompleted';
  }
}

String sprinklerStepToDisplay(SprinklerStep s) {
  switch (s) {
    case SprinklerStep.newLead:
      return 'New Lead';
    case SprinklerStep.siteVisit:
      return 'Site Visited';
    case SprinklerStep.visitData:
      return 'Visit Data';
    case SprinklerStep.quotation:
      return 'Quotation Sent';
    case SprinklerStep.followup:
      return 'Follow-up';
    case SprinklerStep.dealDone:
      return 'Deal Closed';
    case SprinklerStep.installationAssigned:
      return 'Installation Assigned';
    case SprinklerStep.installationStarted:
      return 'Installation Started';
    case SprinklerStep.installationCompleted:
      return 'Installation Completed';
    case SprinklerStep.systemTested:
      return 'System Tested';
    case SprinklerStep.fullPayment:
      return 'Payment Remaining';
    case SprinklerStep.projectCompleted:
      return 'Project Completed';
  }
}

SprinklerStep _resolveSprinklerStepFromData({
  required SprinklerStep base,
  required SprinklerInstallationAssignData assign,
  required SprinklerInstallationData installation,
}) {
  if (base.index >= SprinklerStep.projectCompleted.index) return base;

  if (installation.testedAt != null || installation.systemTested) {
    return SprinklerStep.systemTested;
  }
  if (installation.completedAt != null) {
    return SprinklerStep.installationCompleted;
  }
  if (installation.startedAt != null) {
    return SprinklerStep.installationStarted;
  }
  final hasAssign =
      assign.installerIds.isNotEmpty ||
      assign.installerNames.isNotEmpty ||
      assign.assignedAt != null ||
      assign.scheduledDate != null;
  if (hasAssign) return SprinklerStep.installationAssigned;

  return base;
}

// ── Followup History ─────────────────────────────────────────────────────────
class FollowupHistoryEntry {
  final String id, remark, interestLevel, followupType;
  final DateTime nextFollowupDate, createdAt;
  final int? callDuration;
  final String? attachment;
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

// ── Site Visit ───────────────────────────────────────────────────────────────
class SprinklerSiteVisitData {
  final DateTime? visitDate;
  final String? visitTime,
      salesPerson,
      fieldConditionNotes,
      waterAvailabilityNotes,
      notes;
  final List<String> sitePhotos;
  const SprinklerSiteVisitData({
    this.visitDate,
    this.visitTime,
    this.salesPerson,
    this.fieldConditionNotes,
    this.waterAvailabilityNotes,
    this.notes,
    this.sitePhotos = const [],
  });
  factory SprinklerSiteVisitData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerSiteVisitData();
    return SprinklerSiteVisitData(
      visitDate: _parseDate(j['visitDate']),
      visitTime: j['visitTime']?.toString(),
      salesPerson: j['salesPerson']?.toString(),
      fieldConditionNotes: j['fieldConditionNotes']?.toString(),
      waterAvailabilityNotes: j['waterAvailabilityNotes']?.toString(),
      notes: j['notes']?.toString(),
      sitePhotos: List<String>.from(j['sitePhotos'] ?? []),
    );
  }
}

// ── Visit Data ────────────────────────────────────────────────────────────────
class SprinklerVisitData {
  final int? noOfPanels;
  final String? pumpCapacity;
  final String? typeOfPump;
  final double? deliveryPipeLength;
  final int? noOfSprinklers;
  final double? cableLength;
  final String? typeOfSite;
  final String? notes;
  final List<String> visitPhotos;

  const SprinklerVisitData({
    this.noOfPanels,
    this.pumpCapacity,
    this.typeOfPump,
    this.deliveryPipeLength,
    this.noOfSprinklers,
    this.cableLength,
    this.typeOfSite,
    this.notes,
    this.visitPhotos = const [],
  });

  factory SprinklerVisitData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerVisitData();
    return SprinklerVisitData(
      noOfPanels: (j['noOfPanels'] as num?)?.toInt(),
      pumpCapacity: j['pumpCapacity']?.toString(),
      typeOfPump: j['typeOfPump']?.toString(),
      deliveryPipeLength: (j['deliveryPipeLength'] as num?)?.toDouble(),
      noOfSprinklers: (j['noOfSprinklers'] as num?)?.toInt(),
      cableLength: (j['cableLength'] as num?)?.toDouble(),
      typeOfSite: j['typeOfSite']?.toString(),
      notes: j['notes']?.toString(),
      visitPhotos: List<String>.from(
        j['visitPhotoPaths'] ?? j['visitPhotos'] ?? [],
      ),
    );
  }
}

// ── Quotation ─────────────────────────────────────────────────────────────────
class SprinklerQuotationData {
  final List<SprinklerQuotationLineItem> lineItems;
  final int? noOfPanels;
  final double? noOfKW;
  final int? noOfSprinklerSet;
  final String? typeOfSprinkler;
  final String? pumpDetails,
      sprinkleType,
      upvcPipeSizes,
      cableDetails,
      upvcFittings,
      controlPanel;
  final double? pipeLength;
  final int? sprinklerQty;
  final String? fittings, notes;
  final double labourCost, transportCost, totalAmount, discount, finalAmount;
  final double? advancePercent, balancePercent;
  final String? warrantyNote;
  final String? quotationPdfPath;
  final DateTime? quotationPdfUploadedAt;

  const SprinklerQuotationData({
    this.lineItems = const [],
    this.noOfPanels,
    this.noOfKW,
    this.noOfSprinklerSet,
    this.typeOfSprinkler,
    this.pumpDetails,
    this.sprinkleType,
    this.upvcPipeSizes,
    this.cableDetails,
    this.upvcFittings,
    this.controlPanel,
    this.pipeLength,
    this.sprinklerQty,
    this.fittings,
    this.notes,
    this.labourCost = 0,
    this.transportCost = 0,
    this.totalAmount = 0,
    this.discount = 0,
    this.finalAmount = 0,
    this.advancePercent,
    this.balancePercent,
    this.warrantyNote,
    this.quotationPdfPath,
    this.quotationPdfUploadedAt,
  });

  factory SprinklerQuotationData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerQuotationData();
    return SprinklerQuotationData(
      lineItems: (j['lineItems'] as List? ?? [])
          .map(
            (e) => SprinklerQuotationLineItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      noOfPanels: (j['noOfPanels'] as num?)?.toInt(),
      noOfKW: (j['noOfKW'] as num?)?.toDouble(),
      noOfSprinklerSet: (j['noOfSprinklerSet'] as num?)?.toInt(),
      typeOfSprinkler: j['typeOfSprinkler']?.toString(),
      pumpDetails: j['pumpDetails']?.toString(),
      sprinkleType: j['sprinkleType']?.toString(),
      upvcPipeSizes: j['upvcPipeSizes']?.toString(),
      cableDetails: j['cableDetails']?.toString(),
      upvcFittings: j['upvcFittings']?.toString(),
      controlPanel: j['controlPanel']?.toString(),
      pipeLength: (j['pipeLength'] as num?)?.toDouble(),
      sprinklerQty: (j['sprinklerQty'] as num?)?.toInt(),
      fittings: j['fittings']?.toString(),
      labourCost: (j['labourCost'] as num?)?.toDouble() ?? 0,
      transportCost: (j['transportCost'] as num?)?.toDouble() ?? 0,
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
      discount: (j['discount'] as num?)?.toDouble() ?? 0,
      finalAmount: (j['finalAmount'] as num?)?.toDouble() ?? 0,
      advancePercent: (j['advancePercent'] as num?)?.toDouble(),
      balancePercent: (j['balancePercent'] as num?)?.toDouble(),
      warrantyNote: j['warrantyNote']?.toString(),
      notes: j['notes']?.toString(),
      quotationPdfPath: j['quotationPdfPath']?.toString(),
      quotationPdfUploadedAt: _parseDate(j['quotationPdfUploadedAt']),
    );
  }
}

class SprinklerQuotationLineItem {
  final String description;
  final String quantity;
  final double unitPrice;
  final double total;

  const SprinklerQuotationLineItem({
    required this.description,
    this.quantity = '',
    this.unitPrice = 0,
    this.total = 0,
  });

  factory SprinklerQuotationLineItem.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return const SprinklerQuotationLineItem(description: '');
    }
    return SprinklerQuotationLineItem(
      description: j['description']?.toString() ?? '',
      quantity: j['quantity']?.toString() ?? '',
      unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
      total: (j['total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'total': total,
  };
}

// ── Followup ──────────────────────────────────────────────────────────────────
class SprinklerFollowupData {
  final DateTime? followupDate;
  final String? response, customerType, remarks, notes;
  const SprinklerFollowupData({
    this.followupDate,
    this.response,
    this.customerType,
    this.remarks,
    this.notes,
  });
  factory SprinklerFollowupData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerFollowupData();
    return SprinklerFollowupData(
      followupDate: _parseDate(j['followupDate']),
      response: j['response']?.toString(),
      customerType: j['customerType']?.toString(),
      remarks: j['remarks']?.toString(),
      notes: j['notes']?.toString(),
    );
  }
}

// ── Deal ──────────────────────────────────────────────────────────────────────
class SprinklerDealData {
  final double? finalDealAmount, advancePayment;
  final double discountGiven;
  final String? paymentMode, notes;
  final DateTime? expectedInstallDate, closedAt;
  const SprinklerDealData({
    this.finalDealAmount,
    this.discountGiven = 0,
    this.advancePayment,
    this.paymentMode,
    this.notes,
    this.expectedInstallDate,
    this.closedAt,
  });
  factory SprinklerDealData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerDealData();
    return SprinklerDealData(
      finalDealAmount: (j['finalDealAmount'] as num?)?.toDouble(),
      discountGiven: (j['discountGiven'] as num?)?.toDouble() ?? 0,
      advancePayment: (j['advancePayment'] as num?)?.toDouble(),
      paymentMode: j['paymentMode']?.toString(),
      notes: j['notes']?.toString(),
      expectedInstallDate: _parseDate(j['expectedInstallDate']),
      closedAt: _parseDate(j['closedAt']),
    );
  }
}

// ── Installation Assign ───────────────────────────────────────────────────────
class SprinklerInstallationAssignData {
  final List<String> installerIds;
  final List<String> installerNames;
  final String? installerPhone;
  final DateTime? assignedAt, scheduledDate;
  final String? notes;
  const SprinklerInstallationAssignData({
    this.installerIds = const [],
    this.installerNames = const [],
    this.installerPhone,
    this.assignedAt,
    this.scheduledDate,
    this.notes,
  });

  // Backward-compat single aliases (first assigned installer)
  String? get installerId => installerIds.isNotEmpty ? installerIds.first : null;
  String? get installerName => installerNames.isNotEmpty ? installerNames.first : null;

  factory SprinklerInstallationAssignData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerInstallationAssignData();

    String? parseId(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) {
        return (raw['_id'] ?? raw['id'] ?? raw['\$oid'])?.toString();
      }
      return raw.toString();
    }

    final rawIds = j['installationTeamMemberIds'];
    final rawNames = j['installationTeamNames'];

    final List<String> ids = [];
    final List<String> names = [];
    String? phone;

    if (rawIds is List && rawIds.isNotEmpty) {
      for (final raw in rawIds) {
        final id = parseId(raw);
        if (id != null && id.isNotEmpty) ids.add(id);
        if (raw is Map<String, dynamic>) {
          final n = raw['name']?.toString();
          if (n != null && n.isNotEmpty) names.add(n);
          phone ??= raw['phone']?.toString();
        }
      }
    }

    if (rawNames is List && rawNames.isNotEmpty) {
      for (final n in rawNames) {
        final text = n?.toString();
        if (text != null && text.isNotEmpty) names.add(text);
      }
    }

    // Legacy fallback
    if (ids.isEmpty) {
      final legacyId = parseId(j['installationTeamMemberId']);
      if (legacyId != null && legacyId.isNotEmpty) ids.add(legacyId);
    }
    if (names.isEmpty && j['installationTeamMemberId'] is Map<String, dynamic>) {
      final legacyUser = j['installationTeamMemberId'] as Map<String, dynamic>;
      final legacyName = legacyUser['name']?.toString();
      if (legacyName != null && legacyName.isNotEmpty) names.add(legacyName);
      phone ??= legacyUser['phone']?.toString();
    }
    if (names.isEmpty) {
      final legacyName = j['installerName']?.toString();
      if (legacyName != null && legacyName.isNotEmpty) names.add(legacyName);
    }

    return SprinklerInstallationAssignData(
      installerIds: ids,
      installerNames: names,
      installerPhone: phone,
      assignedAt: _parseDate(j['assignedAt']),
      scheduledDate: _parseDate(j['scheduledDate']),
      notes: j['notes']?.toString(),
    );
  }
}

// ── Installation Data ─────────────────────────────────────────────────────────
class SprinklerInstallationData {
  final String? technicianName, materialUsed, extraMaterial, workNotes, notes;
  final bool pendingWork;
  final String? pendingWorkNote;
  final bool? paymentReceived;
  final DateTime? followUpDate;
  final String? completedBy;
  final String? customerReview;
  final DateTime? installationDate, startedAt, completedAt, testedAt;
  final bool systemTested;
  final List<String> beforePhotos;
  final List<String> installPhotos;
  const SprinklerInstallationData({
    this.technicianName,
    this.materialUsed,
    this.extraMaterial,
    this.workNotes,
    this.notes,
    this.pendingWork = false,
    this.pendingWorkNote,
    this.paymentReceived,
    this.followUpDate,
    this.completedBy,
    this.customerReview,
    this.installationDate,
    this.startedAt,
    this.completedAt,
    this.testedAt,
    this.systemTested = false,
    this.beforePhotos = const [],
    this.installPhotos = const [],
  });
  factory SprinklerInstallationData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerInstallationData();
    return SprinklerInstallationData(
      technicianName: j['technicianName']?.toString(),
      materialUsed: j['materialUsed']?.toString(),
      extraMaterial: j['extraMaterial']?.toString(),
      workNotes: j['workNotes']?.toString(),
      notes: j['notes']?.toString(),
      pendingWork: j['pendingWork'] as bool? ?? false,
      pendingWorkNote: j['pendingWorkNote']?.toString(),
      paymentReceived: j['paymentReceived'] as bool?,
      followUpDate: _parseDate(j['followUpDate']),
      completedBy: j['completedBy']?.toString(),
      customerReview: j['customerReview']?.toString(),
      installationDate: _parseDate(j['installationDate']),
      startedAt: _parseDate(j['startedAt']),
      completedAt: _parseDate(j['completedAt']),
      testedAt: _parseDate(j['testedAt']),
      systemTested: j['systemTested'] as bool? ?? false,
      beforePhotos: List<String>.from(j['beforePhotos'] ?? []),
      installPhotos: List<String>.from(j['installPhotos'] ?? []),
    );
  }
}

// ── Payment ───────────────────────────────────────────────────────────────────
class SprinklerPaymentSummary {
  final double totalAmount, amountReceived, remainingBalance;
  final List<Map<String, dynamic>> history;
  const SprinklerPaymentSummary({
    this.totalAmount = 0,
    this.amountReceived = 0,
    this.remainingBalance = 0,
    this.history = const [],
  });
  factory SprinklerPaymentSummary.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerPaymentSummary();
    return SprinklerPaymentSummary(
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

// ── Review ────────────────────────────────────────────────────────────────────
class SprinklerReviewData {
  final String? reviewCode, feedback, notes;
  final int? rating;
  const SprinklerReviewData({
    this.reviewCode,
    this.rating,
    this.feedback,
    this.notes,
  });
  factory SprinklerReviewData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SprinklerReviewData();
    return SprinklerReviewData(
      reviewCode: j['reviewCode']?.toString(),
      rating: (j['rating'] as num?)?.toInt(),
      feedback: j['feedback']?.toString(),
      notes: j['notes']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN MODEL
// ─────────────────────────────────────────────────────────────────────────────
class SprinklerLeadModel {
  static List<String> get workflowSteps => [
    'New Lead',
    'Site Visited',
    'Visit Data',
    'Quotation Sent',
    'Follow-up',
    'Deal Closed',
    'Installation Assigned',
    'Installation Completed',
    'System Tested',
    'Payment Remaining',
    'Project Completed',
  ];

  final String id, customerName, phone, address, village;
  final String? createdByName, assignedToName, assignedToId;
  final String? installerName, installerId;
  final double? farmSize;
  final String? waterSource, cropType, source, referenceName, note;
  final SprinklerStep currentStep;
  final bool isCompleted;

  final SprinklerSiteVisitData siteVisitData;
  final SprinklerVisitData visitData;
  final SprinklerQuotationData quotationData;
  final SprinklerFollowupData followupData;
  final SprinklerDealData dealData;
  final SprinklerInstallationAssignData installationAssignData;
  final SprinklerInstallationData installationData;
  final SprinklerPaymentSummary paymentSummary;
  final SprinklerReviewData reviewData;

  final List<FollowupHistoryEntry> followupHistory;
  final String? interestLevel, followupType, lastRemark;
  final DateTime? nextFollowupDate, lastFollowupDate;
  final int followupCount, missedFollowupCount;
  final DateTime createdAt, updatedAt;

  const SprinklerLeadModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    this.village = '',
    this.farmSize,
    this.waterSource,
    this.cropType,
    this.source,
    this.referenceName,
    this.note,
    this.currentStep = SprinklerStep.newLead,
    this.isCompleted = false,
    this.siteVisitData = const SprinklerSiteVisitData(),
    this.visitData = const SprinklerVisitData(),
    this.quotationData = const SprinklerQuotationData(),
    this.followupData = const SprinklerFollowupData(),
    this.dealData = const SprinklerDealData(),
    this.installationAssignData = const SprinklerInstallationAssignData(),
    this.installationData = const SprinklerInstallationData(),
    this.paymentSummary = const SprinklerPaymentSummary(),
    this.reviewData = const SprinklerReviewData(),
    this.followupHistory = const [],
    this.interestLevel,
    this.followupType,
    this.nextFollowupDate,
    this.lastFollowupDate,
    this.lastRemark,
    this.followupCount = 0,
    this.missedFollowupCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.assignedToName,
    this.assignedToId,
    this.installerName,
    this.installerId,
  });

  String get status {
    if (currentStep == SprinklerStep.fullPayment) {
      return pendingAmount > 0 ? 'Payment Remaining' : 'Project Completed';
    }
    if (currentStep == SprinklerStep.projectCompleted) {
      return 'Project Completed';
    }
    return sprinklerStepToDisplay(currentStep);
  }

  double get totalAmount => quotationData.finalAmount > 0
      ? quotationData.finalAmount
      : (dealData.finalDealAmount ?? 0);
  double get paidAmount => paymentSummary.amountReceived;
  double get pendingAmount => paymentSummary.remainingBalance;
  bool get isFullyPaid =>
      pendingAmount <= 0 &&
      currentStep.index >= SprinklerStep.fullPayment.index;
  List<Map<String, dynamic>> get paymentHistory => paymentSummary.history;

  DateTime? get visitDate => siteVisitData.visitDate;
  String? get salesPerson => siteVisitData.salesPerson;
  List<String> get sitePhotoPaths => siteVisitData.sitePhotos;
  double? get quotationFinalAmount => quotationData.finalAmount;
  DateTime? get followupDate => followupData.followupDate;
  String? get followupResponse => followupData.response;
  double? get finalDealAmount => dealData.finalDealAmount;
  double? get advancePayment => dealData.advancePayment;
  String? get paymentMode => dealData.paymentMode;
  DateTime? get expectedInstallDate => dealData.expectedInstallDate;
  String? get technicianName => installationData.technicianName;
  List<String> get beforePhotoPaths => installationData.beforePhotos;
  List<String> get installPhotoPaths => installationData.installPhotos;
  String? get reviewCode => reviewData.reviewCode;
  int? get reviewRating => reviewData.rating;
  String? get reviewFeedback => reviewData.feedback;

  bool get hasInstaller =>
      installationAssignData.installerIds.isNotEmpty ||
      (installerId?.isNotEmpty == true);

  List<String> get effectiveInstallerIds {
    if (installationAssignData.installerIds.isNotEmpty) {
      return installationAssignData.installerIds.toSet().toList();
    }
    if (installerId?.isNotEmpty == true) return [installerId!];
    return const [];
  }

  List<String> get effectiveInstallerNames {
    if (installationAssignData.installerNames.isNotEmpty) {
      return installationAssignData.installerNames.toSet().toList();
    }
    if (installerName?.isNotEmpty == true) return [installerName!];
    return const [];
  }

  String? get effectiveInstallerName =>
      effectiveInstallerNames.isNotEmpty ? effectiveInstallerNames.first : null;

  String? get effectiveInstallerNamesString =>
      effectiveInstallerNames.isNotEmpty ? effectiveInstallerNames.join(', ') : null;

  String? get effectiveInstallerId =>
      effectiveInstallerIds.isNotEmpty ? effectiveInstallerIds.first : null;

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

  Map<String, dynamic> toCreateJson() => {
    'customerName': customerName,
    'phone': phone,
    'address': address,
    if (village.isNotEmpty) 'village': village,
    if (farmSize != null) 'farmSize': farmSize,
    if (waterSource != null) 'waterSource': waterSource,
    if (cropType?.isNotEmpty == true) 'cropType': cropType,
    if (source != null) 'source': source,
    if (source == 'reference' && referenceName?.isNotEmpty == true)
      'referenceName': referenceName,
    if (note?.isNotEmpty == true) 'note': note,
  };

  factory SprinklerLeadModel.fromJson(Map<String, dynamic> json) {
    final j = json.containsKey('lead')
        ? json['lead'] as Map<String, dynamic>
        : json;

    final assignRaw = j['installationAssign'] as Map<String, dynamic>?;
    final assignData = SprinklerInstallationAssignData.fromJson(assignRaw);
    final installData = SprinklerInstallationData.fromJson(
      j['installation'] as Map<String, dynamic>?,
    );
    final quotationData = SprinklerQuotationData.fromJson(
      j['quotation'] as Map<String, dynamic>?,
    );
    final dealData = SprinklerDealData.fromJson(
      j['deal'] as Map<String, dynamic>?,
    );
    final paymentSummary = SprinklerPaymentSummary.fromJson(
      j['payment'] as Map<String, dynamic>?,
    );

    final visitDataRaw =
        (j['visitData'] as Map<String, dynamic>?) ??
        (j['technicalVisit'] as Map<String, dynamic>?);
    final visitData = SprinklerVisitData.fromJson(visitDataRaw);

    final rawCreatedBy = j['createdBy'];
    final createdByName = rawCreatedBy is Map
        ? rawCreatedBy['name']?.toString() ??
              rawCreatedBy['fullName']?.toString() ??
              rawCreatedBy['username']?.toString()
        : rawCreatedBy?.toString();

    var rawStep = sprinklerStepFromString(
      j['currentStep']?.toString() ?? j['status']?.toString(),
    );

    // If backend still sends installationStarted index, clamp it back to
    // installationAssigned so no stale data causes a phantom step.
    var resolvedStep = _resolveSprinklerStepFromData(
      base: rawStep,
      assign: assignData,
      installation: installData,
    );

    final backendCompleted =
        j['isCompleted'] as bool? ?? j['projectCompleted'] as bool? ?? false;
    final expectedPayable =
        (dealData.finalDealAmount ?? quotationData.finalAmount).toDouble();
    final paymentRequired = expectedPayable > 0;
    final hasPaymentEvidence =
        paymentSummary.history.isNotEmpty || paymentSummary.amountReceived > 0;
    final paymentRemaining = paymentSummary.remainingBalance;
    final paymentCleared = hasPaymentEvidence && paymentRemaining <= 0;

    final paymentStageReached =
        rawStep.index >= SprinklerStep.fullPayment.index ||
        ((resolvedStep.index >= SprinklerStep.systemTested.index) &&
            hasPaymentEvidence);

    if (paymentStageReached && rawStep != SprinklerStep.projectCompleted) {
      resolvedStep = SprinklerStep.fullPayment;
    }

    final resolvedIsCompleted =
        backendCompleted || (paymentRequired && paymentCleared);

    if (resolvedIsCompleted) resolvedStep = SprinklerStep.projectCompleted;

    if (rawStep == SprinklerStep.projectCompleted && !resolvedIsCompleted) {
      resolvedStep = hasPaymentEvidence
          ? SprinklerStep.fullPayment
          : _resolveSprinklerStepFromData(
              base: SprinklerStep.systemTested,
              assign: assignData,
              installation: installData,
            );
    }

    return SprinklerLeadModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      customerName: j['customerName']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      village: j['village']?.toString() ?? '',
      farmSize: (j['farmSize'] as num?)?.toDouble(),
      waterSource: j['waterSource']?.toString(),
      cropType: j['cropType']?.toString(),
      source: j['source']?.toString(),
      referenceName: j['referenceName']?.toString(),
      note: j['note']?.toString(),
      currentStep: resolvedStep,
      isCompleted: resolvedIsCompleted,
      siteVisitData: SprinklerSiteVisitData.fromJson(
        j['siteVisit'] as Map<String, dynamic>?,
      ),
      visitData: visitData,
      quotationData: quotationData,
      followupData: SprinklerFollowupData.fromJson(
        j['followup'] as Map<String, dynamic>?,
      ),
      dealData: dealData,
      installationAssignData: assignData,
      installationData: installData,
      paymentSummary: paymentSummary,
      reviewData: SprinklerReviewData.fromJson(
        j['review'] as Map<String, dynamic>?,
      ),
      followupHistory: (j['followupHistory'] as List? ?? [])
          .map((e) => FollowupHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      interestLevel: j['interestLevel']?.toString(),
      followupType: j['followupType']?.toString(),
      nextFollowupDate: _parseDate(j['nextFollowupDate']),
      lastFollowupDate: _parseDate(j['lastFollowupDate']),
      lastRemark: j['lastRemark']?.toString(),
      followupCount: (j['followupCount'] as num?)?.toInt() ?? 0,
      missedFollowupCount: (j['missedFollowupCount'] as num?)?.toInt() ?? 0,
      createdByName: (createdByName?.trim().isNotEmpty ?? false)
          ? createdByName!.trim()
          : (j['createdByName']?.toString() ??
                j['creatorName']?.toString() ??
                j['created_by_name']?.toString()),
      assignedToName: (j['assignedTo'] is Map)
          ? j['assignedTo']['name']?.toString()
          : null,
      assignedToId: (j['assignedTo'] is Map)
          ? (j['assignedTo']['_id'] ?? j['assignedTo']['id'])?.toString()
          : j['assignedTo']?.toString(),
      installerName: assignData.installerName ?? j['installerName']?.toString(),
      installerId: assignData.installerId ?? j['installerId']?.toString(),
      createdAt: _parseDate(j['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(j['updatedAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}
