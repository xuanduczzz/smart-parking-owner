import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../blocs/reservation/reservation_bloc.dart';
import '../../blocs/reservation/reservation_event.dart';
import '../../blocs/reservation/reservation_state.dart';
import 'widgets/reservation_card.dart';
import 'widgets/reservation_detail_dialog.dart';
import 'utils/reservation_utils.dart';
import 'constants/reservation_constants.dart';

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

  Future<void> _updateReservationStatus(BuildContext context, String reservationId, String status) async {
    try {
      // Nếu đang chuyển từ checkin sang checkout, hiển thị dialog xác nhận
      if (status == 'checkout') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Xác nhận check-out',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            content: Text(
              'Bạn có chắc chắn muốn check-out cho đơn đặt này?',
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Hủy',
                  style: GoogleFonts.montserrat(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Xác nhận',
                  style: GoogleFonts.montserrat(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return;
        }
      }

      // Cập nhật trạng thái thông qua bloc
      _bloc.add(UpdateReservationStatusEvent(
        reservationId: reservationId,
        status: status,
        lotId: widget.lotId,
      ));
    } catch (e) {
      if (!mounted) return;
      ReservationUtils.showErrorDialog(context, 'Có lỗi xảy ra khi cập nhật trạng thái');
    }
  }

  void _showReservationDetails(BuildContext context, QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: _bloc,
        child: ReservationDetailDialog(
          doc: doc,
          onUpdateStatus: (reservationId, status) => 
            _updateReservationStatus(context, reservationId, status),
        ),
      ),
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
                  ...ReservationConstants.statusList.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(ReservationConstants.statusTextMap[status] ?? status),
                  )),
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
          title: Text(tr('reservation') + ' - ' + widget.lotName),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: BlocBuilder<ReservationBloc, ReservationState>(
          buildWhen: (previous, current) {
            return current is ReservationLoading ||
                   current is ReservationLoaded ||
                   current is ReservationError;
          },
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
                  return ReservationCard(
                    doc: doc,
                    onTap: _showReservationDetails,
                    getStatusColor: ReservationUtils.getStatusColor,
                    getStatusText: ReservationUtils.getStatusText,
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