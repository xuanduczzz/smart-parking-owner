import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../parking/parking_info_screen.dart';
import '../reservation/reservation_screen.dart';
import '../discount/discount_screen.dart';
import '../statistics/statistics_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color ?? Colors.blue.shade100,
                child: Icon(icon, color: Colors.blue, size: 28),
                radius: 28,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.blue),
                onPressed: () {
                  context.read<AuthBloc>().add(SignOutEvent());
                },
                tooltip: 'Đăng xuất',
              ),
            ),
          ),
        ],
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có bãi đỗ xe nào',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Chào mừng bạn đến với Owner App!',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),
                _buildMenuCard(
                  context: context,
                  icon: Icons.local_parking,
                  title: 'Thông tin bãi đỗ xe',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ParkingInfoScreen()),
                    );
                  },
                ),
                _buildMenuCard(
                  context: context,
                  icon: Icons.receipt_long,
                  title: 'Đơn đặt',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservationScreen(
                          lotId: doc.id,
                          lotName: data['name'] ?? '',
                        ),
                      ),
                    );
                  },
                  color: Colors.green.shade100,
                ),
                _buildMenuCard(
                  context: context,
                  icon: Icons.discount,
                  title: 'Mã giảm giá',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiscountScreen()),
                    );
                  },
                ),
                _buildMenuCard(
                  context: context,
                  icon: Icons.bar_chart,
                  title: 'Thống kê',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }
} 