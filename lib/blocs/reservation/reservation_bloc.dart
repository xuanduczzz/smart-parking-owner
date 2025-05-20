import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'reservation_event.dart';
import 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _reservationsSubscription;

  ReservationBloc(this._firestore) : super(ReservationInitial()) {
    on<LoadReservationsEvent>(_onLoadReservations);
    on<FilterReservationsEvent>(_onFilterReservations);
    on<UpdateReservationsEvent>(_onUpdateReservations);
    on<LoadReviewEvent>(_onLoadReview);
  }

  @override
  Future<void> close() {
    _reservationsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadReservations(LoadReservationsEvent event, Emitter<ReservationState> emit) async {
    try {
      emit(ReservationLoading());
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('lotId', isEqualTo: event.lotId)
          .orderBy('startTime', descending: true)
          .get();
      emit(ReservationLoaded(querySnapshot.docs));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  void _onUpdateReservations(UpdateReservationsEvent event, Emitter<ReservationState> emit) {
    emit(ReservationLoaded(event.docs));
  }

  Future<void> _onFilterReservations(FilterReservationsEvent event, Emitter<ReservationState> emit) async {
    try {
      emit(ReservationLoading());
      Query query = _firestore
          .collection('reservations')
          .where('lotId', isEqualTo: event.lotId);

      if (event.startDate != null && event.endDate != null) {
        query = query
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(event.startDate!))
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(event.endDate!));
      }

      if (event.status != null) {
        query = query.where('status', isEqualTo: event.status);
      }

      final querySnapshot = await query.orderBy('startTime', descending: true).get();
      emit(ReservationLoaded(querySnapshot.docs));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
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
} 