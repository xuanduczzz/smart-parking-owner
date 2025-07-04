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
        if (data['status'] != 'completed') continue;
        final timestamp = (data['createdAt'] as Timestamp).toDate();
        final totalPrice = (data['totalPrice'] as num).toDouble();
        totalRevenue += totalPrice;

        String periodKey;
        if (event.period == 'Giờ') {
          // Chỉ lấy dữ liệu của ngày hiện tại
          if (timestamp.year == now.year && 
              timestamp.month == now.month && 
              timestamp.day == now.day) {
            periodKey = '${timestamp.hour}:00';
          } else {
            continue; // Bỏ qua dữ liệu của các ngày khác
          }
        } else if (event.period == 'Ngày') {
          periodKey = '${timestamp.day}/${timestamp.month}';
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

      // Sắp xếp các khóa theo thứ tự
      if (event.period == 'Giờ') {
        // Thêm các giờ không có dữ liệu với giá trị 0
        for (int hour = 0; hour < 24; hour++) {
          final hourKey = '$hour:00';
          if (!reservationsByPeriod.containsKey(hourKey)) {
            reservationsByPeriod[hourKey] = 0;
            revenueByPeriod[hourKey] = 0;
          }
        }
        
        reservationsByPeriod = Map.fromEntries(
          reservationsByPeriod.entries.toList()
            ..sort((a, b) => int.parse(a.key.split(':')[0]).compareTo(int.parse(b.key.split(':')[0])))
        );
        revenueByPeriod = Map.fromEntries(
          revenueByPeriod.entries.toList()
            ..sort((a, b) => int.parse(a.key.split(':')[0]).compareTo(int.parse(b.key.split(':')[0])))
        );
      } else if (event.period == 'Ngày') {
        reservationsByPeriod = Map.fromEntries(
          reservationsByPeriod.entries.toList()
            ..sort((a, b) {
              final aParts = a.key.split('/');
              final bParts = b.key.split('/');
              // So sánh tháng trước
              final monthCompare = int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
              if (monthCompare != 0) return monthCompare;
              // Nếu cùng tháng thì so sánh ngày
              return int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
            })
        );
        revenueByPeriod = Map.fromEntries(
          revenueByPeriod.entries.toList()
            ..sort((a, b) {
              final aParts = a.key.split('/');
              final bParts = b.key.split('/');
              // So sánh tháng trước
              final monthCompare = int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
              if (monthCompare != 0) return monthCompare;
              // Nếu cùng tháng thì so sánh ngày
              return int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
            })
        );
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