import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentParkingLotId;

  StatisticsBloc() : super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    try {
      _currentParkingLotId = event.parkingLotId;
      final now = DateTime.now();
      final reservationsRef = _firestore
          .collection('reservations')
          .where('lotId', isEqualTo: event.parkingLotId);

      // Lấy tất cả reservations
      final reservationsSnapshot = await reservationsRef.get();
      final reservations = reservationsSnapshot.docs;
      
      print('Number of reservations: ${reservations.length}');
      if (reservations.isNotEmpty) {
        print('First reservation data: ${reservations.first.data()}');
      }

      // Tính toán tổng doanh thu và số lượng đặt chỗ
      double totalRevenue = 0;
      int totalReservations = reservations.length;

      // Khởi tạo map để lưu thống kê theo kỳ
      Map<String, int> reservationsByPeriod = {};
      Map<String, double> revenueByPeriod = {};

      for (var doc in reservations) {
        final data = doc.data();
        final timestamp = (data['createdAt'] as Timestamp).toDate();
        final totalPrice = (data['totalPrice'] as num).toDouble();
        totalRevenue += totalPrice;

        String periodKey;
        if (event.period == 'Ngày') {
          periodKey = '${timestamp.hour}:00';
        } else if (event.period == 'Tháng') {
          periodKey = '${timestamp.month}/${timestamp.year}';
        } else {
          periodKey = timestamp.year.toString();
        }

        // Cập nhật số lượng đặt chỗ
        reservationsByPeriod[periodKey] = (reservationsByPeriod[periodKey] ?? 0) + 1;
        // Cập nhật doanh thu
        revenueByPeriod[periodKey] = (revenueByPeriod[periodKey] ?? 0) + totalPrice;
      }

      emit(StatisticsLoaded(
        totalRevenue: totalRevenue,
        totalReservations: totalReservations,
        selectedPeriod: event.period,
        reservationsByPeriod: reservationsByPeriod,
        revenueByPeriod: revenueByPeriod,
      ));
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }

  void _onChangePeriod(
    ChangePeriod event,
    Emitter<StatisticsState> emit,
  ) {
    if (state is StatisticsLoaded && _currentParkingLotId != null) {
      add(LoadStatistics(
        parkingLotId: _currentParkingLotId!,
        period: event.period,
      ));
    }
  }
} 