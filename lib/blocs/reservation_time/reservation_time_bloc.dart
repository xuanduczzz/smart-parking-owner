import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'reservation_time_event.dart';
import 'reservation_time_state.dart';
import '../../services/notification_service.dart';

class ReservationTimeBloc extends Bloc<ReservationTimeEvent, ReservationTimeState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;
  Timer? _timer;
  String? _lotId;

  ReservationTimeBloc({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? NotificationService(),
        super(ReservationTimeInitial()) {
    on<StartCheckingEvent>(_onStartChecking);
    on<StopCheckingEvent>(_onStopChecking);
    on<CheckReservationsEvent>(_onCheckReservations);

    // Lắng nghe sự thay đổi trạng thái đăng nhập
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('👤 Người dùng đã đăng nhập, bắt đầu kiểm tra thời gian');
        add(StartCheckingEvent());
      } else {
        print('👤 Người dùng đã đăng xuất, dừng kiểm tra thời gian');
        add(StopCheckingEvent());
      }
    });
  }

  Future<void> _onStartChecking(
    StartCheckingEvent event,
    Emitter<ReservationTimeState> emit,
  ) async {
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
          emit(ReservationTimeChecking(_lotId!));
          
          // Bắt đầu kiểm tra mỗi phút
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(minutes: 1), (_) {
            add(CheckReservationsEvent());
          });
        } else {
          print('⚠️ Không tìm thấy parking lot cho user ${user.uid}');
          emit(ReservationTimeError('Không tìm thấy parking lot'));
        }
      }
    } catch (e) {
      print('❌ Lỗi khi tìm parking lot: $e');
      emit(ReservationTimeError(e.toString()));
    }
  }

  Future<void> _onStopChecking(
    StopCheckingEvent event,
    Emitter<ReservationTimeState> emit,
  ) async {
    _timer?.cancel();
    _timer = null;
    _lotId = null;
    emit(ReservationTimeStopped());
  }

  Future<void> _onCheckReservations(
    CheckReservationsEvent event,
    Emitter<ReservationTimeState> emit,
  ) async {
    if (_lotId == null) {
      print('⚠️ Không thể kiểm tra vì chưa có lotId');
      return;
    }

    try {
      final now = DateTime.now();
      print('📅 Thời gian hiện tại: ${now.toString()}');
      
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
      emit(ReservationTimeError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
} 