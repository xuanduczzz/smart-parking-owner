import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/parking_lot/parking_lot_bloc.dart';
import 'add_parking_lot_screen.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ParkingInfoScreen extends StatelessWidget {
  const ParkingInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return BlocProvider(
      create: (_) => ParkingLotBloc(CloudinaryPublic('dqnbclzi5', 'avatar_img', cache: false)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('parking_info')),
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
              // Chưa có bãi đỗ, hiển thị nút thêm
              return Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddParkingLotScreen()),
                    );
                  },
                  label: Text(tr('add_parking_lot'), style: TextStyle(fontSize: 18)),
                ),
              );
            }
            // Đã có bãi đỗ, hiển thị thông tin và ẩn nút thêm
            final doc = snapshot.data!.docs.first;
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['name'] ?? '',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                                tooltip: tr('edit_parking_lot'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider.value(
                                        value: context.read<ParkingLotBloc>(),
                                        child: AddParkingLotScreen(
                                          isEditing: true,
                                          docId: doc.id,
                                          initialData: data,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['address'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.attach_money, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                tr('price_per_hour') + ': ',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                              ),
                              Text(
                                '${data['pricePerHour'] ?? ''} VNĐ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.event_seat, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                tr('total_slot') + ': ',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                              ),
                              Text(
                                '${data['totalSlots'] ?? ''}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (data['status'] == false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pending_actions, color: Colors.orange.shade800, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('waiting_for_confirmation'),
                                    style: GoogleFonts.montserrat(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 