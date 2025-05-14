import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final FirebaseFirestore _firestore;

  StatisticsBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    try {
      emit(StatisticsLoading());

      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('lotId', isEqualTo: event.parkingLotId)
          .where('status', isEqualTo: 'completed')
          .get();

      final reservations = reservationsSnapshot.docs;
      double totalRevenue = 0;
      int totalReservations = reservations.length;
      Map<String, int> reservationsByPeriod = {};
      Map<String, double> revenueByPeriod = {};

      for (var reservation in reservations) {
        final data = reservation.data();
        final amount = (data['totalPrice'] ?? 0).toDouble();
        totalRevenue += amount;

        final date = (data['createdAt'] as Timestamp).toDate();
        String periodKey;

        switch (event.period) {
          case 'Ngày':
            periodKey = '${date.day}/${date.month}/${date.year}';
            break;
          case 'Tháng':
            periodKey = '${date.month}/${date.year}';
            break;
          case 'Năm':
            periodKey = date.year.toString();
            break;
          default:
            periodKey = '${date.day}/${date.month}/${date.year}';
        }

        reservationsByPeriod[periodKey] = (reservationsByPeriod[periodKey] ?? 0) + 1;
        revenueByPeriod[periodKey] = (revenueByPeriod[periodKey] ?? 0) + amount;
      }

      emit(StatisticsLoaded(
        totalRevenue: totalRevenue,
        totalReservations: totalReservations,
        reservationsByPeriod: reservationsByPeriod,
        revenueByPeriod: revenueByPeriod,
        selectedPeriod: event.period,
      ));
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }

  void _onChangePeriod(
    ChangePeriod event,
    Emitter<StatisticsState> emit,
  ) {
    if (state is StatisticsLoaded) {
      final currentState = state as StatisticsLoaded;
      add(LoadStatistics(
        parkingLotId: currentState.reservationsByPeriod.keys.first,
        period: event.period,
      ));
    }
  }
} 