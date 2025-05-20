import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/qr_repository.dart';
import 'qr_event.dart';
import 'qr_state.dart';

class QRBloc extends Bloc<QREvent, QRState> {
  final QRRepository _qrRepository;

  QRBloc(this._qrRepository) : super(QRInitial()) {
    on<QRScanned>(_onQRScanned);
  }

  Future<void> _onQRScanned(QRScanned event, Emitter<QRState> emit) async {
    emit(QRLoading());
    try {
      final message = await _qrRepository.updateReservationStatus(event.reservationId);
      emit(QRSuccess(message));
    } catch (e) {
      emit(QRError(e.toString()));
    }
  }
} 