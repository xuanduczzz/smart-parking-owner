abstract class ReservationTimeState {}

class ReservationTimeInitial extends ReservationTimeState {}

class ReservationTimeChecking extends ReservationTimeState {
  final String lotId;
  ReservationTimeChecking(this.lotId);
}

class ReservationTimeStopped extends ReservationTimeState {}

class ReservationTimeError extends ReservationTimeState {
  final String message;
  ReservationTimeError(this.message);
} 