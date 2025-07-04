import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/statistics/statistics_bloc.dart';
import '../../blocs/statistics/statistics_event.dart';
import '../../blocs/statistics/statistics_state.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_lots')
            .where('oid', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không tìm thấy bãi đỗ xe'));
          }

          final parkingLotId = snapshot.data!.docs.first.id;
          print('Parking Lot ID: $parkingLotId');

          return BlocProvider(
            create: (context) => StatisticsBloc()
              ..add(LoadStatistics(
                parkingLotId: parkingLotId,
                period: 'Ngày',
              )),
            child: BlocBuilder<StatisticsBloc, StatisticsState>(
              builder: (context, state) {
                if (state is StatisticsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is StatisticsError) {
                  return Center(child: Text(state.message));
                }

                if (state is StatisticsLoaded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(
                          'Tổng doanh thu',
                          '${state.totalRevenue.toStringAsFixed(0)} VNĐ',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          'Tổng số đặt chỗ',
                          state.totalReservations.toString(),
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thống kê theo ${state.selectedPeriod}',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton<String>(
                              value: state.selectedPeriod,
                              items: ['Giờ', 'Ngày', 'Tháng', 'Năm'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  context.read<StatisticsBloc>().add(
                                        ChangePeriod(newValue),
                                      );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (state.reservationsByPeriod.isNotEmpty) ...[
                          SizedBox(
                            height: 300,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: (state.reservationsByPeriod.length * 50).toDouble().clamp(MediaQuery.of(context).size.width, double.infinity),
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: state.reservationsByPeriod.values
                                        .reduce((a, b) => a > b ? a : b)
                                        .toDouble(),
                                    barGroups: state.reservationsByPeriod.entries
                                        .map((entry) {
                                      return BarChartGroupData(
                                        x: state.reservationsByPeriod.keys
                                            .toList()
                                            .indexOf(entry.key),
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value.toDouble(),
                                            color: Colors.blue,
                                            width: 20,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value >= 0 && value < state.reservationsByPeriod.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  state.reservationsByPeriod.keys.elementAt(value.toInt()),
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (state.revenueByPeriod.isNotEmpty) ...[
                          Text(
                            'Doanh thu theo ${state.selectedPeriod}',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: (state.revenueByPeriod.length * 50).toDouble().clamp(MediaQuery.of(context).size.width, double.infinity),
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: state.revenueByPeriod.values
                                        .reduce((a, b) => a > b ? a : b),
                                    barGroups: state.revenueByPeriod.entries
                                        .map((entry) {
                                      return BarChartGroupData(
                                        x: state.revenueByPeriod.keys
                                            .toList()
                                            .indexOf(entry.key),
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value,
                                            color: Colors.green,
                                            width: 20,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value >= 0 && value < state.revenueByPeriod.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  state.revenueByPeriod.keys.elementAt(value.toInt()),
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 60,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Đơn vị: VNĐ',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                        if (state.reservationsByPeriod.isEmpty && state.revenueByPeriod.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Không có dữ liệu thống kê'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return const Center(child: Text('Không có dữ liệu'));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 