import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCode {
  final String id;
  final String code;
  final int discountPercent;
  final Timestamp expiresAt;
  final bool isActive;
  final String parkingLotId;
  final int usageLimit;
  final List<String> usedBy;
  final int usedCount;

  DiscountCode({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.expiresAt,
    required this.isActive,
    required this.parkingLotId,
    required this.usageLimit,
    required this.usedBy,
    required this.usedCount,
  });

  factory DiscountCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiscountCode(
      id: doc.id,
      code: data['code'] ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? false,
      parkingLotId: data['parkingLotId'] ?? '',
      usageLimit: data['usageLimit'] ?? 0,
      usedBy: List<String>.from(data['usedBy'] ?? []),
      usedCount: data['usedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountPercent': discountPercent,
      'expiresAt': expiresAt,
      'isActive': isActive,
      'parkingLotId': parkingLotId,
      'usageLimit': usageLimit,
      'usedBy': usedBy,
      'usedCount': usedCount,
    };
  }
} 