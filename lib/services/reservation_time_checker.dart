import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ReservationTimeChecker {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final FirebaseAuth _auth;
  Timer? _timer;
  String? _lotId;

  ReservationTimeChecker({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService(),
        _auth = auth ?? FirebaseAuth.instance {
    // Lắng nghe sự thay đổi trạng thái đăng nhập
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('👤 Người dùng đã đăng nhập, bắt đầu kiểm tra thời gian');
        _initializeLotId();
      } else {
        print('👤 Người dùng đã đăng xuất, dừng kiểm tra thời gian');
        stopChecking();
      }
    });
  }

  Future<void> _initializeLotId() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final parkingLots = await _firestore
            .collection('parking_lots')
            .where('oid', isEqualTo: user.uid)
            .get();
        
        if (parkingLots.docs.isNotEmpty) {
          _lotId = parkingLots.docs.first.id;
          print('📌 Đã tìm thấy parking lot với ID: $_lotId');
          startChecking();
        } else {
          print('⚠️ Không tìm thấy parking lot cho user ${user.uid}');
          stopChecking();
        }
      }
    } catch (e) {
      print('❌ Lỗi khi tìm parking lot: $e');
      stopChecking();
    }
  }

  void startChecking() {
    if (_lotId == null) {
      print('⚠️ Không thể bắt đầu kiểm tra vì chưa có lotId');
      return;
    }

    print('🔄 Bắt đầu kiểm tra thời gian reservation cho lot: $_lotId');
    // Kiểm tra mỗi phút
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      print('⏰ Đang kiểm tra thời gian reservation cho lot: $_lotId');
      _checkActiveReservations();
    });
  }

  void stopChecking() {
    print('🛑 Dừng kiểm tra thời gian reservation');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkActiveReservations() async {
    if (_lotId == null) {
      print('⚠️ Không thể kiểm tra vì chưa có lotId');
      return;
    }

    try {
      final now = DateTime.now();
      print('📅 Thời gian hiện tại: ${now.toString()}');
      
      // Lấy tất cả các reservation đang checkin của lot cụ thể
      final activeReservations = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'checkin')
          .where('lotId', isEqualTo: _lotId)
          .get();

      print('🔍 Tìm thấy ${activeReservations.docs.length} reservation đang checkin cho lot: $_lotId');

      for (var doc in activeReservations.docs) {
        try {
          final data = doc.data();
          final endTimeData = data['endTime'];
          
          if (endTimeData == null) {
            print('⚠️ Reservation ${doc.id} không có thời gian kết thúc');
            continue;
          }

          DateTime endTime;
          if (endTimeData is Timestamp) {
            endTime = endTimeData.toDate();
          } else if (endTimeData is String) {
            endTime = DateTime.parse(endTimeData);
          } else {
            print('⚠️ Định dạng thời gian không hợp lệ cho reservation ${doc.id}');
            continue;
          }

          final userId = data['userId'] as String?;
          if (userId == null) {
            print('⚠️ Reservation ${doc.id} không có userId');
            continue;
          }

          final timeUntilEnd = endTime.difference(now);
          print('📌 Kiểm tra reservation ID: ${doc.id}');
          print('👤 User ID: $userId');
          print('⏱️ Thời gian kết thúc: ${endTime.toString()}');
          print('⏳ Thời gian còn lại: ${timeUntilEnd.inMinutes} phút');

          // Chỉ xử lý các reservation chưa kết thúc
          if (timeUntilEnd.isNegative) {
            print('⚠️ Reservation ${doc.id} đã kết thúc');
            continue;
          }

          await _notificationService.scheduleTimeRemainingNotifications(
            userId: userId,
            endTime: endTime,
          );
        } catch (e) {
          print('⚠️ Lỗi khi xử lý reservation ${doc.id}: $e');
          continue;
        }
      }
    } catch (e) {
      print('❌ Lỗi khi kiểm tra reservations: $e');
    }
  }
} 