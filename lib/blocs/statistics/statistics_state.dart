import 'package:equatable/equatable.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final double totalRevenue;
  final int totalReservations;
  final String selectedPeriod;
  final Map<String, int> reservationsByPeriod;
  final Map<String, double> revenueByPeriod;

  const StatisticsLoaded({
    required this.totalRevenue,
    required this.totalReservations,
    required this.selectedPeriod,
    required this.reservationsByPeriod,
    required this.revenueByPeriod,
  });

  @override
  List<Object> get props => [
        totalRevenue,
        totalReservations,
        selectedPeriod,
        reservationsByPeriod,
        revenueByPeriod,
      ];
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
} 