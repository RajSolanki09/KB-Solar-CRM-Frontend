class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "status": status,
    };
  }
}