import 'package:cloud_firestore/cloud_firestore.dart';

class QRRepository {
  final FirebaseFirestore _firestore;

  QRRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> updateReservationStatus(String reservationId) async {
    try {
      final reservationRef = _firestore.collection('reservations').doc(reservationId);
      final reservationDoc = await reservationRef.get();

      if (!reservationDoc.exists) {
        throw Exception('Không tìm thấy đơn đặt chỗ');
      }

      final data = reservationDoc.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String;

      String newStatus;
      String message;

      switch (currentStatus) {
        case 'confirmed':
          newStatus = 'checkin';
          message = 'Đã cập nhật trạng thái thành check-in';
          break;
        case 'checkin':
          newStatus = 'checkout';
          message = 'Đã cập nhật trạng thái thành check-out';
          break;
        default:
          throw Exception('Không thể cập nhật trạng thái từ $currentStatus');
      }

      await reservationRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return message;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
} 