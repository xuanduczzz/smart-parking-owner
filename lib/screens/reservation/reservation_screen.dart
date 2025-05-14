import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../blocs/reservation/reservation_bloc.dart';
import '../../blocs/reservation/reservation_event.dart';
import '../../blocs/reservation/reservation_state.dart';

class ReservationScreen extends StatefulWidget {
  final String lotId;
  final String lotName;

  const ReservationScreen({
    Key? key,
    required this.lotId,
    required this.lotName,
  }) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late ReservationBloc _bloc;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _bloc = ReservationBloc(FirebaseFirestore.instance)
      ..add(LoadReservationsEvent(
        userId: userId,
        lotId: widget.lotId,
      ));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onLoadReservations() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _bloc.add(
      LoadReservationsEvent(
        userId: userId,
        lotId: widget.lotId,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Lỗi',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.montserrat(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: GoogleFonts.montserrat(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReservationStatus(BuildContext context, String reservationId, String status) async {
    try {
      // Cập nhật trạng thái trong Firestore
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({'status': status});
      
      if (!mounted) return;

      // Tải lại danh sách đơn đặt
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      _bloc.add(LoadReservationsEvent(
        userId: userId,
        lotId: widget.lotId,
      ));
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, 'Có lỗi xảy ra khi cập nhật trạng thái');
    }
  }

  void _showReservationDetails(BuildContext context, QueryDocumentSnapshot doc) {
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

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    'Chi tiết đơn đặt',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Họ tên:', name),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.phone, 'Số điện thoại:', phoneNumber),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.directions_car, 'Biển số xe:', vehicleId),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.event_seat, 'Slot:', slotId),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Thời gian bắt đầu:', 
                DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Thời gian kết thúc:', 
                DateFormat('dd/MM/yyyy HH:mm').format(endTime)),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.attach_money, 'Tổng tiền:', 
                '${totalPrice.toStringAsFixed(0)} VNĐ'),
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
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _updateReservationStatus(dialogContext, reservationId, 'confirmed');
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
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _updateReservationStatus(dialogContext, reservationId, 'cancelled');
                      },
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: status == 'confirmed' ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'confirmed' ? 'Đã xác nhận' : 'Đã hủy',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: status == 'confirmed' ? Colors.green.shade900 : Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: Text(
            'Lọc đơn đặt',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chọn khoảng thời gian
              ListTile(
                title: Text(
                  'Từ ngày',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _startDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'Chọn ngày',
                  style: GoogleFonts.montserrat(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final now = DateTime.now();
                  final firstDate = DateTime(2020);
                  final lastDate = DateTime(now.year, now.month, now.day);
                  final initialDate = _startDate ?? now;
                  
                  final date = await showDatePicker(
                    context: Navigator.of(context).context,
                    initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (date != null) {
                    dialogSetState(() {
                      _startDate = date;
                      // Reset end date if it's before new start date
                      if (_endDate != null && _endDate!.isBefore(date)) {
                        _endDate = null;
                      }
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  'Đến ngày',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _endDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'Chọn ngày',
                  style: GoogleFonts.montserrat(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  if (_startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vui lòng chọn ngày bắt đầu trước',
                          style: GoogleFonts.montserrat(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final now = DateTime.now();
                  final firstDate = _startDate!;
                  final lastDate = DateTime(now.year, now.month, now.day);
                  final initialDate = _endDate ?? now;
                  
                  final date = await showDatePicker(
                    context: Navigator.of(context).context,
                    initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (date != null) {
                    if (date.isBefore(_startDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ngày kết thúc phải sau ngày bắt đầu',
                            style: GoogleFonts.montserrat(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    dialogSetState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
              // Chọn trạng thái
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  labelStyle: GoogleFonts.montserrat(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tất cả'),
                  ),
                  const DropdownMenuItem(
                    value: 'pending',
                    child: Text('Chờ xác nhận'),
                  ),
                  const DropdownMenuItem(
                    value: 'confirmed',
                    child: Text('Đã xác nhận'),
                  ),
                  const DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Đã hủy'),
                  ),
                ],
                onChanged: (value) {
                  dialogSetState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedStatus = null;
                });
                _onLoadReservations();
              },
              child: Text(
                'Đặt lại',
                style: GoogleFonts.montserrat(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_startDate != null && _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vui lòng chọn ngày kết thúc',
                        style: GoogleFonts.montserrat(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                _bloc.add(FilterReservationsEvent(
                  userId: userId,
                  lotId: widget.lotId,
                  startDate: _startDate,
                  endDate: _endDate,
                  status: _selectedStatus,
                ));
              },
              child: Text(
                'Áp dụng',
                style: GoogleFonts.montserrat(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Đơn đặt - ${widget.lotName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: BlocBuilder<ReservationBloc, ReservationState>(
          builder: (context, state) {
            if (state is ReservationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ReservationError) {
              return Center(child: Text(state.message));
            }
            if (state is ReservationLoaded) {
              if (state.reservations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có đơn đặt nào',
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
                padding: const EdgeInsets.all(16),
                itemCount: state.reservations.length,
                itemBuilder: (context, index) {
                  final doc = state.reservations[index];
                  final reservation = doc.data() as Map<String, dynamic>;
                  final startTime = (reservation['startTime'] as Timestamp).toDate();
                  final endTime = (reservation['endTime'] as Timestamp).toDate();
                  final totalPrice = reservation['totalPrice'] as double;
                  final slotId = reservation['slotId'] as String? ?? '';
                  final name = reservation['name'] as String? ?? '';
                  final phoneNumber = reservation['phoneNumber'] as String? ?? '';
                  final vehicleId = reservation['vehicleId'] as String? ?? '';
                  final status = reservation['status'] as String? ?? 'pending';
                  
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showReservationDetails(context, doc),
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
                                    color: status == 'pending' ? Colors.orange.shade100 : 
                                           status == 'confirmed' ? Colors.green.shade100 :
                                           Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status == 'pending' ? 'Chờ xác nhận' : 
                                    status == 'confirmed' ? 'Đã xác nhận' : 'Đã hủy',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: status == 'pending' ? Colors.orange.shade900 : 
                                             status == 'confirmed' ? Colors.green.shade900 :
                                             Colors.red.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                  'Biển số xe: $vehicleId',
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
                                  'Slot: $slotId',
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
                                  'Thời gian:',
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
                                  'Tổng tiền: ',
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
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
} 