import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/discount_code.dart';
import '../../blocs/voucher/voucher_bloc.dart';
import '../../blocs/voucher/voucher_event.dart';
import '../../blocs/voucher/voucher_state.dart';

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
                          builder: (context) => AlertDialog(
                            title: const Text('Gửi thông báo'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Bạn có muốn gửi thông báo về mã giảm giá này cho tất cả người dùng không?'),
                                const SizedBox(height: 16),
                                Text(
                                  'Mã giảm giá: ${discount.code}\nGiảm giá: ${discount.discountPercent}%',
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
                                  context.read<VoucherBloc>().add(
                                        SendNotification(
                                          userId: 'all',
                                          title: 'Mã giảm giá mới',
                                          body: 'Bạn có mã giảm giá mới: ${discount.code} với ${discount.discountPercent}% giảm giá',
                                        ),
                                      );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã gửi thông báo cho tất cả người dùng'),
                                    ),
                                  );
                                },
                                child: const Text('Gửi'),
                              ),
                            ],
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
                          builder: (context) => AlertDialog(
                            title: const Text('Xóa mã giảm giá'),
                            content: Text('Bạn có chắc chắn muốn xóa mã giảm giá ${discount.code} không?'),
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
                                  context.read<VoucherBloc>().add(
                                        DeleteVoucher(
                                          voucherId: discount.id,
                                        ),
                                      );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã xóa mã giảm giá'),
                                    ),
                                  );
                                },
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Xóa mã giảm giá',
                    ),
                    Switch(
                      value: discount.isActive,
                      onChanged: (value) {
                        context.read<VoucherBloc>().add(
                              UpdateVoucherStatus(
                                voucherId: discount.id,
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
              'Giảm giá: ${discount.discountPercent}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Hạn sử dụng: ${discount.expiresAt.toDate().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã sử dụng: ${discount.usedCount}/${discount.usageLimit}',
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
      builder: (context) => AlertDialog(
        title: const Text('Tạo mã giảm giá mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã giảm giá',
                  hintText: 'Nhập mã giảm giá',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountController,
                decoration: const InputDecoration(
                  labelText: 'Phần trăm giảm giá',
                  hintText: 'Nhập phần trăm giảm giá',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usageLimitController,
                decoration: const InputDecoration(
                  labelText: 'Giới hạn sử dụng',
                  hintText: 'Nhập số lần sử dụng tối đa',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Ngày hết hạn'),
                subtitle: Text(selectedDate.toString().split('.')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty &&
                  discountController.text.isNotEmpty &&
                  usageLimitController.text.isNotEmpty) {
                context.read<VoucherBloc>().add(
                      CreateVoucher(
                        code: codeController.text,
                        discountPercent: int.parse(discountController.text),
                        expiresAt: selectedDate,
                        usageLimit: int.parse(usageLimitController.text),
                        parkingLotId: parkingLotId,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider(
      create: (context) => VoucherBloc()..add(LoadVouchers(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mã giảm giá'),
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

            return BlocBuilder<VoucherBloc, VoucherState>(
              builder: (context, state) {
                if (state is VoucherLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VoucherError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is VoucherLoaded) {
                  if (state.vouchers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.discount, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có mã giảm giá nào',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: state.vouchers.length,
                    itemBuilder: (context, index) {
                      return _buildDiscountCard(context, state.vouchers[index]);
                    },
                  );
                }

                return const SizedBox();
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
      ),
    );
  }
} 