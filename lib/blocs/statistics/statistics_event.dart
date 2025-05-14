abstract class StatisticsEvent {}

class LoadStatistics extends StatisticsEvent {
  final String parkingLotId;
  final String period;

  LoadStatistics({
    required this.parkingLotId,
    required this.period,
  });
}

class ChangePeriod extends StatisticsEvent {
  final String period;

  ChangePeriod(this.period);
} 