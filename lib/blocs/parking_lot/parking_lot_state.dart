import 'package:equatable/equatable.dart';

abstract class ParkingLotState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ParkingLotInitial extends ParkingLotState {}

class ParkingLotLoading extends ParkingLotState {}

class ParkingLotSuccess extends ParkingLotState {}

class ParkingLotError extends ParkingLotState {
  final String message;
  ParkingLotError(this.message);

  @override
  List<Object?> get props => [message];
} 