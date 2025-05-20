import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../widgets/custom_drawer.dart';
import '../parking/parking_info_screen.dart';
import '../reservation/reservation_screen.dart';
import '../discount/discount_screen.dart';
import '../statistics/statistics_screen.dart';
import '../qr_scanner_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Colors.blue,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade100,
                child: Icon(icon, color: Colors.blue, size: 28),
                radius: 28,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('home'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      drawer: const CustomDrawer(),
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
                  Icon(Icons.local_parking, size: 64, color: theme.iconTheme.color?.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    tr('no_parking_lots'),
                    style: theme.textTheme.bodyLarge,
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
                    tr('welcome'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),
                _buildMenuCard(
                  context: context,
                  icon: Icons.local_parking,
                  title: tr('parking_info'),
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
                  title: tr('reservation'),
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
                ),
                _buildMenuCard(
                  context: context,
                  icon: Icons.discount,
                  title: tr('discount'),
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
                  title: tr('statistics'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                    );
                  },
                ),
                _buildMenuCard(
                  context: context,
                  icon: Icons.qr_code_scanner,
                  title: tr('qr_scan'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
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