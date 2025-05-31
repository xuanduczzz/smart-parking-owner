import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Function(BuildContext, QueryDocumentSnapshot) onTap;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusText;

  const ReservationCard({
    Key? key,
    required this.doc,
    required this.onTap,
    required this.getStatusColor,
    required this.getStatusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reservation = doc.data() as Map<String, dynamic>;
    final startTime = (reservation['startTime'] as Timestamp).toDate();
    final endTime = (reservation['endTime'] as Timestamp).toDate();
    final totalPrice = reservation['totalPrice'] as double;
    final slotId = reservation['slotId'] as String? ?? '';
    final name = reservation['name'] as String? ?? '';
    final phoneNumber = reservation['phoneNumber'] as String? ?? '';
    final vehicleId = reservation['vehicleId'] as String? ?? '';
    final status = reservation['status'] as String? ?? 'pending';
    final createdAt = (reservation['createdAt'] as Timestamp?)?.toDate();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(context, doc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getStatusText(status),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: getStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Tạo lúc: ' + DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    phoneNumber,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('vehicle_plate') + ': $vehicleId',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_seat, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('slot') + ': $slotId',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('start_time') + ':',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              Text(
                'Kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(endTime)}',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('total_price') + ': ',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(0)} VNĐ',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 