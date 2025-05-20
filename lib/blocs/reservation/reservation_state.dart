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

class ReviewLoading extends ReservationState {}

class ReviewLoaded extends ReservationState {
  final Map<String, dynamic> review;

  ReviewLoaded(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewError extends ReservationState {
  final String message;

  ReviewError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReviewEmpty extends ReservationState {} 