// lib/data/Models/installation_model.dart

enum InstallationStatus {
  installationAssigned,
  installationStarted,   // ← NEW: team on site, before photos taken
  installationCompleted,
  meterApplied,
  meterInspection,
  meterInstalled,
  projectCompleted,
}

enum MeterStage { applied, inspection, installed }

class InstallationModel {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final double systemSize;
  final String projectType;
  final InstallationStatus status;
  final MeterStage? meterStage;
  final DateTime assignedDate;
  final DateTime? scheduledDate;
  final DateTime? completedDate;

  // Photo upload flags
  final bool hasBeforePhoto;
  final bool hasPanelPhoto;
  final bool hasWiringPhoto;
  final bool hasInverterPhoto;

  // Customer confirmation
  final bool hasCustomerSignature;
  final bool hasCompletionCertificate;

  // Subsidy documents
  final bool hasInstallationCertificate;
  final bool hasCustomerId;
  final bool hasElectricityBill;
  final bool hasApplicationForm;

  // Payment
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? paymentReceiptUrl;

  // Deal info
  final String? paymentMode;
  final String? assignedByName;
  final DateTime? closedAt;
  final String? notes;
  final String? assignedBy;

  // ── Installation Assign fields (step 6 of solar pipeline) ────────────────
  // Multi-member arrays (canonical)
  final List<String> installationTeamMemberIds;
  final List<String> installationTeamMemberNames;
  // Legacy single getters for backward compat
  String? get installationTeamName =>
      installationTeamMemberNames.isNotEmpty ? installationTeamMemberNames.join(', ') : null;
  String? get installationTeamMemberId =>
      installationTeamMemberIds.isNotEmpty ? installationTeamMemberIds.first : null;
  final DateTime? installationAssignedAt;

  // Project completion
  final bool projectCompleted;
  final DateTime? projectCompletedAt;

  InstallationModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.systemSize,
    required this.projectType,
    required this.status,
    this.meterStage,
    required this.assignedDate,
    this.scheduledDate,
    this.completedDate,
    this.hasBeforePhoto = false,
    this.hasPanelPhoto = false,
    this.hasWiringPhoto = false,
    this.hasInverterPhoto = false,
    this.hasCustomerSignature = false,
    this.hasCompletionCertificate = false,
    this.hasInstallationCertificate = false,
    this.hasCustomerId = false,
    this.hasElectricityBill = false,
    this.hasApplicationForm = false,
    required this.totalAmount,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.paymentReceiptUrl,
    this.paymentMode,
    this.assignedByName,
    this.closedAt,
    this.notes,
    this.assignedBy,
    this.installationTeamMemberIds = const [],
    this.installationTeamMemberNames = const [],
    this.installationAssignedAt,
    this.projectCompleted = false,
    this.projectCompletedAt,
  });

  // ── fromJson ───────────────────────────────────────────────────────────────
  factory InstallationModel.fromJson(Map<String, dynamic> json) {
    String? str(String snake, String camel) =>
        json[snake]?.toString() ?? json[camel]?.toString();

    double dbl(String snake, String camel) =>
        ((json[snake] ?? json[camel] ?? 0) as num).toDouble();

    bool toBool(dynamic value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is num) return value != 0;

      final text = value.toString().trim().toLowerCase();
      if (text.isEmpty) return fallback;
      if (text == 'true' || text == 'yes' || text == 'y' || text == '1') {
        return true;
      }
      if (text == 'false' || text == 'no' || text == 'n' || text == '0') {
        return false;
      }

      final n = num.tryParse(text);
      if (n != null) return n != 0;
      return fallback;
    }

    bool bln(String snake, String camel) =>
        toBool(json[snake] ?? json[camel], fallback: false);

    DateTime? dte(String snake, String camel) {
      final raw = json[snake] ?? json[camel];
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString())?.toLocal();
    }

    // ── Nested sub-docs ────────────────────────────────────────────────────
    final deal         = json['deal']         as Map<String, dynamic>?;
    final quotation    = json['quotation']    as Map<String, dynamic>?;
    final payment      = json['payment']      as Map<String, dynamic>?;
    final installation = json['installation'] as Map<String, dynamic>?;
    final meter        = json['meter']        as Map<String, dynamic>?;

    // ── installationAssign subdoc ──────────────────────────────────────────
    final ia = json['installationAssign'] as Map<String, dynamic>?;

    // Parse multi-member arrays (new) with legacy single fallback
    String? _parseId(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) return raw['\$oid']?.toString();
      return raw.toString();
    }

    final rawIds = ia?['installationTeamMemberIds'];
    final List<String> installationTeamMemberIds;
    if (rawIds is List && rawIds.isNotEmpty) {
      installationTeamMemberIds = rawIds
          .map(_parseId)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final legacyId = _parseId(ia?['installationTeamMemberId']);
      installationTeamMemberIds = legacyId != null ? [legacyId] : [];
    }

    final rawNames = ia?['installationTeamNames'];
    final List<String> installationTeamMemberNames;
    if (rawNames is List && rawNames.isNotEmpty) {
      installationTeamMemberNames = rawNames
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final legacyName =
          ia?['installationTeamName']?.toString() ??
          deal?['installationTeamName']?.toString();
      installationTeamMemberNames = legacyName != null ? [legacyName] : [];
    }

    final installationAssignedAt = ia?['assignedAt'] != null
        ? DateTime.tryParse(ia!['assignedAt'].toString())?.toLocal()
        : null;

    // ── assignedByName ─────────────────────────────────────────────────────
    final createdBy = json['createdBy'];
    final assignedByName = createdBy is Map
        ? createdBy['name']?.toString()
        : str('assigned_by_name', 'assignedByName') ??
              str('closed_by_name', 'closedByName');

    // ── systemSize ─────────────────────────────────────────────────────────
    final rawSystemSize =
        quotation?['systemSize'] ??
        json['systemSize']       ??
        json['system_size']      ??
        0;
    final systemSize = double.tryParse(rawSystemSize.toString()) ?? 0.0;

    // ── payment amounts ────────────────────────────────────────────────────
    final totalAmount =
        (payment?['totalAmount'] as num?)?.toDouble() ??
        (deal?['finalAmount']    as num?)?.toDouble() ??
        dbl('total_amount', 'totalAmount');

    final paidAmount =
        (payment?['amountReceived'] as num?)?.toDouble() ??
        (deal?['advancePayment']    as num?)?.toDouble() ??
        dbl('paid_amount', 'paidAmount');

    final remainingAmount =
        (payment?['remainingBalance'] as num?)?.toDouble() ??
        (totalAmount - paidAmount).clamp(0.0, double.infinity);

    // ── scheduledDate ──────────────────────────────────────────────────────
    final scheduledDate =
        (ia?['scheduledDate'] != null
            ? DateTime.tryParse(ia!['scheduledDate'].toString())?.toLocal()
            : null) ??
        dte('scheduled_date', 'scheduledDate') ??
        (deal?['expectedInstallDate'] != null
            ? DateTime.tryParse(
                deal!['expectedInstallDate'].toString())?.toLocal()
            : null);

    // ── other dates ────────────────────────────────────────────────────────
    final assignedDate =
        dte('assigned_date', 'assignedDate') ??
        dte('created_at',    'createdAt')    ??
        DateTime.now();

    final completedDate =
        dte('completed_date', 'completedDate') ??
        (installation?['completedAt'] != null
            ? DateTime.tryParse(
                installation!['completedAt'].toString())?.toLocal()
            : null);

    final closedAt =
        dte('closed_at', 'closedAt') ??
        (deal?['closedAt'] != null
            ? DateTime.tryParse(deal!['closedAt'].toString())?.toLocal()
            : null);

    // ── photo flags ────────────────────────────────────────────────────────
    final beforePhotos = installation?['beforePhotos']       as List? ?? [];
    final afterPhotos  = installation?['installationPhotos'] as List? ?? [];

    // ── meter stage — derived from which date fields are set ───────────────
    MeterStage? meterStage;
    if      (meter?['installedDate']   != null) meterStage = MeterStage.installed;
    else if (meter?['inspectionDate']  != null) meterStage = MeterStage.inspection;
    else if (meter?['applicationDate'] != null) meterStage = MeterStage.applied;

    // ── status — parse backend string, then refine with meter sub-doc ──────
    final rawStatus = str('status', 'status');
    InstallationStatus parsedStatus = _parseStatus(rawStatus);

    // When backend says "Meter Process", refine to correct sub-stage
    // based on which date is populated.
    if (parsedStatus == InstallationStatus.meterApplied && meterStage != null) {
      switch (meterStage) {
        case MeterStage.installed:
          parsedStatus = InstallationStatus.meterInstalled;
          break;
        case MeterStage.inspection:
          parsedStatus = InstallationStatus.meterInspection;
          break;
        case MeterStage.applied:
          parsedStatus = InstallationStatus.meterApplied;
          break;
      }
    }

    return InstallationModel(
      id:           json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerName: str('customer_name', 'customerName') ?? '',
      phone:        str('phone', 'phone')                ?? '',
      address:      str('address', 'address')            ?? '',
      systemSize:   systemSize,
      projectType:  str('project_type', 'projectType')   ?? 'solar',
      status:       parsedStatus,
      meterStage:   meterStage,

      assignedDate:  assignedDate,
      scheduledDate: scheduledDate,
      completedDate: completedDate,

      hasBeforePhoto:   beforePhotos.isNotEmpty,
      hasPanelPhoto:    afterPhotos.isNotEmpty,
      hasWiringPhoto:   bln('has_wiring_photo',    'hasWiringPhoto'),
      hasInverterPhoto: bln('has_inverter_photo',  'hasInverterPhoto'),

      hasCustomerSignature:     toBool(installation?['customerSigned']),
      hasCompletionCertificate: bln('has_completion_certificate',    'hasCompletionCertificate'),
      hasInstallationCertificate: bln('has_installation_certificate', 'hasInstallationCertificate'),
      hasCustomerId:      bln('has_customer_id',      'hasCustomerId'),
      hasElectricityBill: bln('has_electricity_bill', 'hasElectricityBill'),
      hasApplicationForm: bln('has_application_form', 'hasApplicationForm'),

      totalAmount:       totalAmount,
      paidAmount:        paidAmount,
      remainingAmount:   remainingAmount,
      paymentReceiptUrl: str('payment_receipt_url', 'paymentReceiptUrl'),
      paymentMode:
          str('payment_mode', 'paymentMode') ??
          deal?['paymentMode']?.toString(),

      assignedByName: assignedByName,
      closedAt:       closedAt,
        notes:
          ia?['notes']?.toString() ??
          str('notes', 'notes') ??
          deal?['notes']?.toString(),
      assignedBy:
          deal?['installationTeamMemberId']?.toString() ??
          str('assigned_by', 'assignedBy'),

      installationTeamMemberIds:   installationTeamMemberIds,
      installationTeamMemberNames:  installationTeamMemberNames,
      installationAssignedAt:   installationAssignedAt,

      projectCompleted:   toBool(json['projectCompleted']),
      projectCompletedAt: dte('project_completed_at', 'projectCompletedAt'),
    );
  }

  // ── copyWith ───────────────────────────────────────────────────────────────
  InstallationModel copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? address,
    double? systemSize,
    String? projectType,
    InstallationStatus? status,
    MeterStage? meterStage,
    DateTime? assignedDate,
    DateTime? scheduledDate,
    DateTime? completedDate,
    bool? hasBeforePhoto,
    bool? hasPanelPhoto,
    bool? hasWiringPhoto,
    bool? hasInverterPhoto,
    bool? hasCustomerSignature,
    bool? hasCompletionCertificate,
    bool? hasInstallationCertificate,
    bool? hasCustomerId,
    bool? hasElectricityBill,
    bool? hasApplicationForm,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? paymentReceiptUrl,
    String? paymentMode,
    String? assignedByName,
    DateTime? closedAt,
    String? notes,
    String? assignedBy,
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamMemberNames,
    DateTime? installationAssignedAt,
    bool? projectCompleted,
    DateTime? projectCompletedAt,
  }) => InstallationModel(
    id:           id           ?? this.id,
    customerName: customerName ?? this.customerName,
    phone:        phone        ?? this.phone,
    address:      address      ?? this.address,
    systemSize:   systemSize   ?? this.systemSize,
    projectType:  projectType  ?? this.projectType,
    status:       status       ?? this.status,
    meterStage:   meterStage   ?? this.meterStage,
    assignedDate:  assignedDate  ?? this.assignedDate,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    completedDate: completedDate ?? this.completedDate,
    hasBeforePhoto:   hasBeforePhoto   ?? this.hasBeforePhoto,
    hasPanelPhoto:    hasPanelPhoto    ?? this.hasPanelPhoto,
    hasWiringPhoto:   hasWiringPhoto   ?? this.hasWiringPhoto,
    hasInverterPhoto: hasInverterPhoto ?? this.hasInverterPhoto,
    hasCustomerSignature:     hasCustomerSignature     ?? this.hasCustomerSignature,
    hasCompletionCertificate: hasCompletionCertificate ?? this.hasCompletionCertificate,
    hasInstallationCertificate: hasInstallationCertificate ?? this.hasInstallationCertificate,
    hasCustomerId:      hasCustomerId      ?? this.hasCustomerId,
    hasElectricityBill: hasElectricityBill ?? this.hasElectricityBill,
    hasApplicationForm: hasApplicationForm ?? this.hasApplicationForm,
    totalAmount:       totalAmount       ?? this.totalAmount,
    paidAmount:        paidAmount        ?? this.paidAmount,
    remainingAmount:   remainingAmount   ?? this.remainingAmount,
    paymentReceiptUrl: paymentReceiptUrl ?? this.paymentReceiptUrl,
    paymentMode:    paymentMode    ?? this.paymentMode,
    assignedByName: assignedByName ?? this.assignedByName,
    closedAt:       closedAt       ?? this.closedAt,
    notes:          notes          ?? this.notes,
    assignedBy:     assignedBy     ?? this.assignedBy,
    installationTeamMemberIds:   installationTeamMemberIds   ?? this.installationTeamMemberIds,
    installationTeamMemberNames: installationTeamMemberNames ?? this.installationTeamMemberNames,
    installationAssignedAt:   installationAssignedAt   ?? this.installationAssignedAt,
    projectCompleted:   projectCompleted   ?? this.projectCompleted,
    projectCompletedAt: projectCompletedAt ?? this.projectCompletedAt,
  );

  // ── Status parser ──────────────────────────────────────────────────────────
  // Maps backend status strings → InstallationStatus enum values.
  // "Meter Process" maps to meterApplied as the base; fromJson refines it
  // further using the meter sub-doc date fields.
  static InstallationStatus _parseStatus(String? s) {
    switch (s) {
      case 'Deal Closed':
      case 'Installation Assigned':
      case 'installation_assigned':
      case 'installationAssigned':
        return InstallationStatus.installationAssigned;

      case 'Installation Started':
      case 'installation_started':
      case 'installationStarted':
        return InstallationStatus.installationStarted;

      case 'Installed':
      case 'Installation Completed':
      case 'installation_completed':
      case 'installationCompleted':
        return InstallationStatus.installationCompleted;

      // All meter sub-stages come as "Meter Process" from backend.
      // fromJson refines to meterApplied/meterInspection/meterInstalled
      // by checking meter.applicationDate / inspectionDate / installedDate.
      case 'Meter Process':
      case 'Meter Applied':
      case 'meter_applied':
      case 'meterApplied':
        return InstallationStatus.meterApplied;

      case 'Meter Inspection':
      case 'meter_inspection':
      case 'meterInspection':
        return InstallationStatus.meterInspection;

      case 'Meter Installed':
      case 'meter_installed':
      case 'meterInstalled':
      case 'System Tested':
      case 'system_tested':
      case 'systemTested':
        return InstallationStatus.meterInstalled;

      case 'Project Completed':
      case 'Payment Completed':
      case 'project_completed':
      case 'projectCompleted':
        return InstallationStatus.projectCompleted;

      default:
        return InstallationStatus.installationAssigned;
    }
  }

  // ── Computed helpers ───────────────────────────────────────────────────────
  bool get isToday {
    final now = DateTime.now();
    final d = scheduledDate ?? assignedDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get isPending => status == InstallationStatus.installationAssigned;

  bool get allPhotosUploaded =>
      hasBeforePhoto && hasPanelPhoto && hasWiringPhoto && hasInverterPhoto;

  bool get subsidyDocsComplete =>
      hasInstallationCertificate &&
      hasCustomerId &&
      hasElectricityBill &&
      hasApplicationForm;

  String? get paymentModeLabel {
    switch (paymentMode) {
      case 'cash':         return 'Cash';
      case 'upi':          return 'UPI';
      case 'bankTransfer': return 'Bank Transfer';
      case 'cheque':       return 'Cheque';
      case 'loan':         return 'Loan';
      default:
        if (paymentMode == null) return null;
        return paymentMode![0].toUpperCase() + paymentMode!.substring(1);
    }
  }

  String get statusLabel {
    switch (status) {
      case InstallationStatus.installationAssigned:  return 'Assigned';
      case InstallationStatus.installationStarted:   return 'Started';
      case InstallationStatus.installationCompleted: return 'Installation Done';
      case InstallationStatus.meterApplied:          return 'Meter Applied';
      case InstallationStatus.meterInspection:       return 'Meter Inspection';
      case InstallationStatus.meterInstalled:        return 'Meter Installed';
      case InstallationStatus.projectCompleted:      return 'Project Complete 🏆';
    }
  }
}