import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/reservation/reservation_bloc.dart';
import '../../../blocs/reservation/reservation_state.dart';

class ReviewSection extends StatelessWidget {
  final String reservationId;

  const ReviewSection({
    Key? key,
    required this.reservationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationBloc, ReservationState>(
      buildWhen: (previous, current) {
        return current is ReviewLoading ||
               current is ReviewLoaded ||
               current is ReviewEmpty ||
               current is ReviewError;
      },
      builder: (context, state) {
        if (state is ReviewLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (state is ReviewEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Chưa có đánh giá',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        if (state is ReviewError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Có lỗi xảy ra khi tải đánh giá',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
            ),
          );
        }

        if (state is ReviewLoaded) {
          final review = state.review;
          final createdAt = (review['createdAt'] as Timestamp).toDate();
          final imageUrl = review['imageUrl'] as String?;
          final reviewText = review['review'] as String;
          final star = review['star'] as int;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(5, (index) => Icon(
                    index < star ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reviewText,
                style: GoogleFonts.montserrat(fontSize: 16),
              ),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
} 