import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ParkingLotState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ParkingLotInitial extends ParkingLotState {}

class ParkingLotLoading extends ParkingLotState {}

class ParkingLotLoaded extends ParkingLotState {
  final QuerySnapshot parkingLots;

  ParkingLotLoaded(this.parkingLots);

  @override
  List<Object?> get props => [parkingLots];
}

class ParkingSlotsLoaded extends ParkingLotState {
  final QuerySnapshot slots;

  ParkingSlotsLoaded(this.slots);

  @override
  List<Object?> get props => [slots];
}

class AvailableSlotsLoaded extends ParkingLotState {
  final List<Map<String, dynamic>> slots;

  AvailableSlotsLoaded(this.slots);

  @override
  List<Object?> get props => [slots];
}

class ExistingSlotsLoaded extends ParkingLotState {
  final List<Map<String, dynamic>> slots;

  ExistingSlotsLoaded(this.slots);
}

class ParkingLotSuccess extends ParkingLotState {}

class ParkingLotError extends ParkingLotState {
  final String message;
  ParkingLotError(this.message);

  @override
  List<Object?> get props => [message];
} 