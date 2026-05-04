// lib/data/Models/service_request_model.dart

class ServiceRequestModel {
  final String id;
  final String serviceId;
  final String customerName;
  final String phone;
  final String address;
  final String? issueType;
  final String? issueDescription;
  final String chargeType;       // "Free" | "Paid"
  final double amount;           // chargeAmount
  final double paidAmount;
  final String? paymentStatus;   // "Not Applicable" | "Pending" | "Partial" | "Paid"
  final String? paymentMode;
  final String priority;
  String status;
  final String? assignedToId;
  final String? assignedToName;
  final String? assignedToPhone;
  final String? createdById;
  final String? createdByName;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String? serviceNotes;
  final DateTime? serviceDate;
  final DateTime createdAt;

  ServiceRequestModel({
    required this.id,
    required this.serviceId,
    required this.customerName,
    required this.phone,
    required this.address,
    this.issueType,
    this.issueDescription,
    required this.chargeType,
    required this.amount,
    this.paidAmount = 0,
    this.paymentStatus,
    this.paymentMode,
    this.priority = 'Medium',
    required this.status,
    this.assignedToId,
    this.assignedToName,
    this.assignedToPhone,
    this.createdById,
    this.createdByName,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.serviceNotes,
    this.serviceDate,
    required this.createdAt,
  });

  bool get isPaid     => chargeType == 'Paid';
  bool get isComplete => status == 'Completed' || status == 'Resolved' || status == 'Closed';
  double get remaining => amount - paidAmount;

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    String? assignedId, assignedName, assignedPhone;
    if (json['assignedTo'] != null) {
      if (json['assignedTo'] is Map) {
        assignedId    = json['assignedTo']['_id'] ?? json['assignedTo']['id'];
        assignedName  = json['assignedTo']['name'];
        assignedPhone = json['assignedTo']['phone'];
      } else if (json['assignedTo'] is String) {
        assignedId = json['assignedTo'];
      }
    }

    String? createdById, createdByName;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        createdById  = json['createdBy']['_id'] ?? json['createdBy']['id'];
        createdByName = json['createdBy']['name'];
      } else {
        createdById = json['createdBy'];
      }
    }

    DateTime? serviceDate;
    if (json['assignment']?['serviceDate'] != null) {
      try {
        serviceDate = DateTime.parse(
          json['assignment']['serviceDate'],
        ).toLocal();
      } catch (_) {}
    }

    return ServiceRequestModel(
      id:              json['_id'] ?? json['id'] ?? '',
      serviceId:       json['serviceId'] ?? '',
      customerName:    json['customerName'] ?? '',
      phone:           json['phone'] ?? '',
      address:         json['address'] ?? '',
      issueType:       json['issueType'],
      issueDescription:json['issueDescription'],
      chargeType:      json['chargeType'] ?? 'Free',
      amount:          (json['chargeAmount'] ?? 0).toDouble(),
      paidAmount:      (json['paidAmount'] ?? 0).toDouble(),
      paymentStatus:   json['paymentStatus'],
      paymentMode:     json['paymentMode'],
      priority:        json['priority'] ?? 'Medium',
      status:          json['status'] ?? 'Open',
      assignedToId:    assignedId,
      assignedToName:  assignedName,
      assignedToPhone: assignedPhone,
      createdById:     createdById,
      createdByName:   createdByName,
      beforePhotos: List<String>.from(json['beforePhotos'] ?? []),
      afterPhotos:  List<String>.from(json['afterPhotos']  ?? []),
      serviceNotes:    json['serviceNotes'],
      serviceDate:     serviceDate,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'])?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'customerName':    customerName,
    'phone':           phone,
    'address':         address,
    'issueType':       issueType,
    'issueDescription':issueDescription,
    'chargeType':      chargeType,
    'chargeAmount':    amount,
    'priority':        priority,
    if (assignedToId != null) 'assignedTo': assignedToId,
  };
}