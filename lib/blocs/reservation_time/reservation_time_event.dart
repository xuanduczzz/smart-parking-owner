abstract class ReservationTimeEvent {}

class StartCheckingEvent extends ReservationTimeEvent {}

class StopCheckingEvent extends ReservationTimeEvent {}

class CheckReservationsEvent extends ReservationTimeEvent {} 