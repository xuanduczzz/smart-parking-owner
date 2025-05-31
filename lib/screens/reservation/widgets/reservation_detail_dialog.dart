import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/reservation/reservation_bloc.dart';
import '../../../blocs/reservation/reservation_event.dart';
import '../../../blocs/reservation/reservation_state.dart';
import 'review_section.dart';

class ReservationDetailDialog extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Function(String, String) onUpdateStatus;

  const ReservationDetailDialog({
    Key? key,
    required this.doc,
    required this.onUpdateStatus,
  }) : super(key: key);

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentImage(BuildContext context, String reservationId) {
    // Load payment image when dialog opens
    context.read<ReservationBloc>().add(LoadPaymentImageEvent(reservationId: reservationId));

    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        if (state is ReservationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReservationError) {
          return const SizedBox.shrink();
        }

        String? paymentImageUrl;
        if (state is PaymentImageLoaded) {
          paymentImageUrl = state.paymentImageUrl;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Hình ảnh thanh toán',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (paymentImageUrl == null || paymentImageUrl.isEmpty)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 32, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có hình ảnh thanh toán',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  paymentImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

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
    final reservationId = doc.id;
    final theme = Theme.of(context);

    // Load review if status is completed
    if (status == 'completed') {
      context.read<ReservationBloc>().add(LoadReviewEvent(reservationId: reservationId));
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('reservation_detail'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(context, Icons.person, tr('name') + ':', name),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.phone, tr('phone') + ':', phoneNumber),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.directions_car, tr('vehicle_plate') + ':', vehicleId),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.event_seat, tr('slot') + ':', slotId),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.access_time, tr('start_time') + ':', 
                DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.access_time, tr('end_time') + ':', 
                DateFormat('dd/MM/yyyy HH:mm').format(endTime)),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.attach_money, tr('total_price') + ':', 
                '${totalPrice.toStringAsFixed(0)} VNĐ'),
              if (status == 'pending') _buildPaymentImage(context, reservationId),
              const SizedBox(height: 24),
              if (status == 'completed') ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Đánh giá',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ReviewSection(reservationId: reservationId),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (status == 'pending') ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateStatus(reservationId, 'confirmed');
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Hủy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateStatus(reservationId, 'cancelled');
                      },
                    ),
                  ] else if (status == 'confirmed') ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Check-in'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateStatus(reservationId, 'checkin');
                      },
                    ),
                  ] else if (status == 'checkin') ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Check-out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateStatus(reservationId, 'checkout');
                      },
                    ),
                  ] else if (status == 'checkout') ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Kết thúc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateStatus(reservationId, 'completed');
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 