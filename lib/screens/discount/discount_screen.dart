import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/discount_code.dart';
import '../../blocs/discount/discount_bloc.dart';
import '../../blocs/discount/discount_event.dart';
import '../../blocs/discount/discount_state.dart';
import 'package:easy_localization/easy_localization.dart';

class DiscountScreen extends StatelessWidget {
  const DiscountScreen({Key? key}) : super(key: key);

  Widget _buildDiscountCard(BuildContext context, DiscountCode discount) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  discount.code,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BlocProvider.value(
                            value: context.read<DiscountBloc>(),
                            child: AlertDialog(
                              title: Text(tr('send_notification')),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(tr('confirm_send_notification')),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr('discount_info', args: [discount.code, discount.discountPercent.toString()]),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<DiscountBloc>().add(
                                          SendDiscountNotification(
                                            code: discount.code,
                                            discountPercent: discount.discountPercent,
                                          ),
                                        );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                        content: Text(tr('notification_sent')),
                                      ),
                                    );
                                  },
                                  child: const Text('Gửi'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      tooltip: 'Gửi thông báo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BlocProvider.value(
                            value: context.read<DiscountBloc>(),
                            child: AlertDialog(
                              title: Text(tr('delete_discount_title')),
                              content: Text(tr('confirm_delete_discount', args: [discount.code])),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    context.read<DiscountBloc>().add(
                                          DeleteDiscount(discount.id),
                                        );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                        content: Text(tr('discount_deleted')),
                                      ),
                                    );
                                  },
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      tooltip: 'Xóa mã giảm giá',
                    ),
                    Switch(
                      value: discount.isActive,
                      onChanged: (value) {
                        context.read<DiscountBloc>().add(
                              UpdateDiscountStatus(
                                discountId: discount.id,
                                isActive: value,
                                parkingLotId: discount.parkingLotId,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tr('discount_percent', args: [discount.discountPercent.toString()]),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              tr('expires_at', args: [discount.expiresAt.toDate().toString().split('.')[0]]),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              tr('usage_count', args: [discount.usedCount.toString(), discount.usageLimit.toString()]),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVoucherDialog(BuildContext context, String parkingLotId) {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final usageLimitController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<DiscountBloc>(),
        child: AlertDialog(
          title: Text(tr('create_new_discount')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: tr('discount_code'),
                    hintText: tr('enter_discount_code'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(
                    labelText: tr('discount_percent'),
                    hintText: tr('enter_discount_percent'),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usageLimitController,
                  decoration: InputDecoration(
                    labelText: tr('usage_limit'),
                    hintText: tr('enter_usage_limit'),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(tr('expiry_date')),
                  subtitle: Text(selectedDate.toString().split('.')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.isNotEmpty &&
                    discountController.text.isNotEmpty &&
                    usageLimitController.text.isNotEmpty) {
                  context.read<DiscountBloc>().add(
                        CreateDiscount(
                          code: codeController.text,
                          discountPercent: int.parse(discountController.text),
                          expiresAt: selectedDate,
                          usageLimit: int.parse(usageLimitController.text),
                          parkingLotId: parkingLotId,
                        ),
                      );
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(tr('create')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('discount_title')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_lots')
            .where('oid', isEqualTo: userId)
            .snapshots(),
        builder: (context, parkingLotSnapshot) {
          if (parkingLotSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (parkingLotSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    tr('connection_error'),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading data
                      context.read<DiscountBloc>().add(
                        LoadDiscounts(parkingLotSnapshot.data?.docs.first.id ?? ''),
                      );
                    },
                    child: Text(tr('retry')),
                  ),
                ],
              ),
            );
          }

          if (!parkingLotSnapshot.hasData || parkingLotSnapshot.data!.docs.isEmpty) {
            return Center(child: Text(tr('no_parking_found')));
          }

          final parkingLotId = parkingLotSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vouchers')
                .where('parkingLotId', isEqualTo: parkingLotId)
                .snapshots(),
            builder: (context, voucherSnapshot) {
              if (voucherSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (voucherSnapshot.hasError) {
                return Center(
                  child: Text(
                    voucherSnapshot.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!voucherSnapshot.hasData || voucherSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.discount, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        tr('no_discounts'),
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final discounts = voucherSnapshot.data!.docs
                  .map((doc) => DiscountCode.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: discounts.length,
                itemBuilder: (context, index) {
                  return _buildDiscountCard(context, discounts[index]);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_lots')
            .where('oid', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox();
          }

          final parkingLotId = snapshot.data!.docs.first.id;

          return FloatingActionButton(
            onPressed: () => _showCreateVoucherDialog(context, parkingLotId),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
} 