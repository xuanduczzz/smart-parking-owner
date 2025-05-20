import 'package:equatable/equatable.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();

  @override
  List<Object> get props => [];
}

class LoadStatistics extends StatisticsEvent {
  final String parkingLotId;
  final String period;

  const LoadStatistics({
    required this.parkingLotId,
    required this.period,
  });

  @override
  List<Object> get props => [parkingLotId, period];
}

class ChangePeriod extends StatisticsEvent {
  final String period;

  const ChangePeriod(this.period);

  @override
  List<Object> get props => [period];
} 