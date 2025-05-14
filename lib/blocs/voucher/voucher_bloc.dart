import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'voucher_event.dart';
import 'voucher_state.dart';
import '../../models/discount_code.dart';
import '../../models/notification.dart';

class VoucherBloc extends Bloc<VoucherEvent, VoucherState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _voucherSubscription;
  StreamSubscription<QuerySnapshot>? _parkingLotSubscription;

  VoucherBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(VoucherInitial()) {
    on<LoadVouchers>(_onLoadVouchers);
    on<CreateVoucher>(_onCreateVoucher);
    on<UpdateVoucherStatus>(_onUpdateVoucherStatus);
    on<_VoucherUpdated>(_onVoucherUpdated);
    on<SendNotification>(_onSendNotification);
    on<DeleteVoucher>(_onDeleteVoucher);
  }

  @override
  Future<void> close() {
    _voucherSubscription?.cancel();
    _parkingLotSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadVouchers(
    LoadVouchers event,
    Emitter<VoucherState> emit,
  ) async {
    try {
      emit(VoucherLoading());
      
      // Hủy subscription cũ nếu có
      await _voucherSubscription?.cancel();
      await _parkingLotSubscription?.cancel();

      // Lắng nghe thay đổi của parking lot
      _parkingLotSubscription = _firestore
          .collection('parking_lots')
          .where('oid', isEqualTo: event.parkingLotId)
          .snapshots()
          .listen((parkingLotSnapshot) {
        if (parkingLotSnapshot.docs.isEmpty) {
          add(LoadVouchers(event.parkingLotId)); // Reload để hiển thị lỗi
          return;
        }

        final parkingLotId = parkingLotSnapshot.docs.first.id;

        // Hủy subscription cũ của vouchers
        _voucherSubscription?.cancel();

        // Lắng nghe thay đổi của vouchers
        _voucherSubscription = _firestore
            .collection('vouchers')
            .where('parkingLotId', isEqualTo: parkingLotId)
            .snapshots()
            .listen((voucherSnapshot) {
          final vouchers = voucherSnapshot.docs
              .map((doc) => DiscountCode.fromFirestore(doc))
              .toList();
          add(_VoucherUpdated(vouchers));
        });
      });
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  void _onVoucherUpdated(
    _VoucherUpdated event,
    Emitter<VoucherState> emit,
  ) {
    emit(VoucherLoaded(event.vouchers));
  }

  Future<void> _onCreateVoucher(
    CreateVoucher event,
    Emitter<VoucherState> emit,
  ) async {
    try {
      emit(VoucherLoading());

      final voucher = DiscountCode(
        id: '', // ID sẽ được Firestore tự động tạo
        code: event.code,
        discountPercent: event.discountPercent,
        expiresAt: Timestamp.fromDate(event.expiresAt),
        isActive: true,
        parkingLotId: event.parkingLotId,
        usageLimit: event.usageLimit,
        usedBy: [],
        usedCount: 0,
      );

      await _firestore.collection('vouchers').add(voucher.toMap());
      // Không cần emit state mới vì snapshots() sẽ tự động cập nhật
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> _onUpdateVoucherStatus(
    UpdateVoucherStatus event,
    Emitter<VoucherState> emit,
  ) async {
    try {
      emit(VoucherLoading());

      await _firestore
          .collection('vouchers')
          .doc(event.voucherId)
          .update({'isActive': event.isActive});
      // Không cần emit state mới vì snapshots() sẽ tự động cập nhật
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> _onSendNotification(
    SendNotification event,
    Emitter<VoucherState> emit,
  ) async {
    try {
      if (event.userId == 'all') {
        // Lấy tất cả người dùng từ collection user_customer
        final usersSnapshot = await _firestore.collection('user_customer').get();
        
        // Gửi thông báo cho từng người dùng
        for (var userDoc in usersSnapshot.docs) {
          final notification = NotificationBody(
            body: event.body,
            isRead: false,
            timestamp: Timestamp.now(),
            title: event.title,
            userId: userDoc.id,
          );

          await _firestore.collection('notifications').add(notification.toMap());
        }
      } else {
        // Gửi thông báo cho một người dùng cụ thể
        final notification = NotificationBody(
          body: event.body,
          isRead: false,
          timestamp: Timestamp.now(),
          title: event.title,
          userId: event.userId,
        );

        await _firestore.collection('notifications').add(notification.toMap());
      }
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> _onDeleteVoucher(
    DeleteVoucher event,
    Emitter<VoucherState> emit,
  ) async {
    try {
      await _firestore.collection('vouchers').doc(event.voucherId).delete();
      // Không cần emit state mới vì snapshots() sẽ tự động cập nhật
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }
}

// Private event để cập nhật state từ stream
class _VoucherUpdated extends VoucherEvent {
  final List<DiscountCode> vouchers;

  _VoucherUpdated(this.vouchers);

  @override
  List<Object> get props => [vouchers];
} 