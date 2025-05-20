import 'package:equatable/equatable.dart';

abstract class QREvent extends Equatable {
  const QREvent();

  @override
  List<Object?> get props => [];
}

class QRScanned extends QREvent {
  final String reservationId;

  const QRScanned(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
} 