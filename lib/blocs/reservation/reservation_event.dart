import 'package:equatable/equatable.dart';

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