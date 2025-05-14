import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ReservationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReservationInitial extends ReservationState {}

class ReservationLoading extends ReservationState {}

class ReservationLoaded extends ReservationState {
  final List<QueryDocumentSnapshot> reservations;

  ReservationLoaded(this.reservations);

  @override
  List<Object?> get props => [reservations];
}

class ReservationError extends ReservationState {
  final String message;

  ReservationError(this.message);

  @override
  List<Object?> get props => [message];
} 