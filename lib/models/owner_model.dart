class OwnerModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String address;
  final DateTime createdAt;
  final String avatar;
  final String qrcode;
  final bool status;

  OwnerModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
    this.avatar = '',
    this.qrcode = '',
    this.status = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'avatar': avatar,
      'oid': id,
      'qrcode': qrcode,
      'status': status,
    };
  }

  factory OwnerModel.fromMap(Map<String, dynamic> map) {
    return OwnerModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      avatar: map['avatar'] ?? '',
      qrcode: map['qrcode'] ?? '',
      status: map['status'] ?? false,
    );
  }
} 