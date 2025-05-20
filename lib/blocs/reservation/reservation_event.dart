import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ReservationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadReservationsEvent extends ReservationEvent {
  final String userId;
  final String lotId;

  LoadReservationsEvent({
    required this.userId,
    required this.lotId,
  });

  @override
  List<Object?> get props => [userId, lotId];
}

class FilterReservationsEvent extends ReservationEvent {
  final String userId;
  final String lotId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  FilterReservationsEvent({
    required this.userId,
    required this.lotId,
    this.startDate,
    this.endDate,
    this.status,
  });

  @override
  List<Object?> get props => [userId, lotId, startDate, endDate, status];
}

class UpdateReservationsEvent extends ReservationEvent {
  final List<QueryDocumentSnapshot> docs;
  UpdateReservationsEvent(this.docs);

  @override
  List<Object?> get props => [docs];
}

class LoadReviewEvent extends ReservationEvent {
  final String reservationId;

  LoadReviewEvent({required this.reservationId});

  @override
  List<Object?> get props => [reservationId];
} 