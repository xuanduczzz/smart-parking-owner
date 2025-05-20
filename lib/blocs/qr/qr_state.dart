import 'package:equatable/equatable.dart';

abstract class QRState extends Equatable {
  const QRState();

  @override
  List<Object?> get props => [];
}

class QRInitial extends QRState {}

class QRLoading extends QRState {}

class QRSuccess extends QRState {
  final String message;

  const QRSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class QRError extends QRState {
  final String message;

  const QRError(this.message);

  @override
  List<Object?> get props => [message];
} 