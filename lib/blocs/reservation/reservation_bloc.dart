import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_event.dart';
import 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final FirebaseFirestore _firestore;

  ReservationBloc(this._firestore) : super(ReservationInitial()) {
    on<LoadReservationsEvent>(_onLoadReservations);
    on<FilterReservationsEvent>(_onFilterReservations);
  }

  Future<void> _onLoadReservations(LoadReservationsEvent event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('lotId', isEqualTo: event.lotId)
          .orderBy('createdAt', descending: true)
          .get();
      
      emit(ReservationLoaded(reservationsSnapshot.docs));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onFilterReservations(FilterReservationsEvent event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      Query query = _firestore.collection('reservations')
          .where('lotId', isEqualTo: event.lotId);

      // Thêm điều kiện lọc theo trạng thái nếu có
      if (event.status != null && event.status!.isNotEmpty) {
        query = query.where('status', isEqualTo: event.status);
      }

      // Thêm điều kiện lọc theo ngày nếu có
      if (event.startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: event.startDate);
      }
      if (event.endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: event.endDate);
      }

      // Sắp xếp theo ngày tạo
      query = query.orderBy('createdAt', descending: true);

      final reservationsSnapshot = await query.get();
      emit(ReservationLoaded(reservationsSnapshot.docs));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
} 