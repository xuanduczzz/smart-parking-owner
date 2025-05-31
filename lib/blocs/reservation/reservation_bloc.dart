import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'reservation_event.dart';
import 'reservation_state.dart';
import '../../services/notification_service.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _reservationsSubscription;

  // Thêm các biến lưu filter hiện tại
  String? _currentLotId;
  String? _currentStatus;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  ReservationBloc(this._firestore) : super(ReservationInitial()) {
    on<LoadReservationsEvent>(_onLoadReservations);
    on<FilterReservationsEvent>(_onFilterReservations);
    on<UpdateReservationsEvent>(_onUpdateReservations);
    on<LoadReviewEvent>(_onLoadReview);
    on<UpdateReservationStatusEvent>(_onUpdateReservationStatus);
    on<LoadPaymentImageEvent>(_onLoadPaymentImage);
  }

  @override
  Future<void> close() {
    _reservationsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadReservations(LoadReservationsEvent event, Emitter<ReservationState> emit) async {
    await _reservationsSubscription?.cancel();
    emit(ReservationLoading());

    _reservationsSubscription = _firestore
        .collection('reservations')
        .where('lotId', isEqualTo: event.lotId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((querySnapshot) {
          add(UpdateReservationsEvent(querySnapshot.docs));
        }, onError: (error) {
          add(UpdateReservationsEvent([]));
        });
  }

  void _onUpdateReservations(UpdateReservationsEvent event, Emitter<ReservationState> emit) {
    emit(ReservationLoaded(event.docs));
  }

  Future<void> _onFilterReservations(FilterReservationsEvent event, Emitter<ReservationState> emit) async {
    await _reservationsSubscription?.cancel();
    emit(ReservationLoading());

    // Lưu filter hiện tại
    _currentLotId = event.lotId;
    _currentStatus = event.status;
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;

    Query query = _firestore.collection('reservations').where('lotId', isEqualTo: event.lotId);
    if (event.status != null) query = query.where('status', isEqualTo: event.status);
    if (event.startDate != null && event.endDate != null) {
      query = query
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(event.startDate!))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(event.endDate!));
    }

    _reservationsSubscription = query.orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      add(UpdateReservationsEvent(snapshot.docs));
    });
  }

  Future<void> _onLoadReview(
    LoadReviewEvent event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReviewLoading());
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('reservationId', isEqualTo: event.reservationId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        emit(ReviewEmpty());
        return;
      }

      final review = querySnapshot.docs.first.data();
      emit(ReviewLoaded(review));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onUpdateReservationStatus(UpdateReservationStatusEvent event, Emitter<ReservationState> emit) async {
    try {
      // Lấy userId từ reservation document
      final doc = await _firestore.collection('reservations').doc(event.reservationId).get();
      final data = doc.data();
      final userId = data != null && data['userId'] != null ? data['userId'] as String : null;

      await _firestore
          .collection('reservations')
          .doc(event.reservationId)
          .update({'status': event.status});

      // Gửi notification nếu lấy được userId
      if (userId != null) {
        await NotificationService().createStatusChangeNotification(
          userId: userId,
          title: 'Trạng thái đơn đặt thay đổi',
          body: 'Đơn đặt của bạn đã chuyển sang trạng thái: ${event.status}',
        );
      }
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onLoadPaymentImage(
    LoadPaymentImageEvent event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payment')
          .where('reservationId', isEqualTo: event.reservationId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        emit(PaymentImageLoaded(paymentImageUrl: null));
        return;
      }

      final paymentData = querySnapshot.docs.first.data();
      final paymentImageUrl = paymentData['paymentImageUrl'] as String?;
      emit(PaymentImageLoaded(paymentImageUrl: paymentImageUrl));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
} 