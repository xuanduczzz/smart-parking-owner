import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'discount_event.dart';
import 'discount_state.dart';
import '../../models/discount_code.dart';

class DiscountBloc extends Bloc<DiscountEvent, DiscountState> {
  final FirebaseFirestore _firestore;

  DiscountBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(DiscountInitial()) {
    on<LoadDiscounts>(_onLoadDiscounts);
    on<CreateDiscount>(_onCreateDiscount);
    on<UpdateDiscountStatus>(_onUpdateDiscountStatus);
    on<DeleteDiscount>(_onDeleteDiscount);
    on<SendDiscountNotification>(_onSendDiscountNotification);
  }

  Future<void> _onLoadDiscounts(
    LoadDiscounts event,
    Emitter<DiscountState> emit,
  ) async {
    try {
      emit(DiscountLoading());
      final snapshot = await _firestore
          .collection('vouchers')
          .where('parkingLotId', isEqualTo: event.parkingLotId)
          .get();

      final discounts = snapshot.docs
          .map((doc) => DiscountCode.fromFirestore(doc))
          .toList();

      emit(DiscountLoaded(discounts));
    } catch (e) {
      emit(DiscountError(e.toString()));
    }
  }

  Future<void> _onCreateDiscount(
    CreateDiscount event,
    Emitter<DiscountState> emit,
  ) async {
    try {
      emit(DiscountLoading());
      
      final discount = DiscountCode(
        id: '',
        code: event.code,
        discountPercent: event.discountPercent,
        expiresAt: Timestamp.fromDate(event.expiresAt),
        usageLimit: event.usageLimit,
        usedCount: 0,
        isActive: true,
        parkingLotId: event.parkingLotId,
        usedBy: [],
      );

      final docRef = await _firestore.collection('vouchers').add(discount.toMap());
      
      emit(DiscountCreated());
      add(LoadDiscounts(event.parkingLotId));
    } catch (e) {
      emit(DiscountError(e.toString()));
    }
  }

  Future<void> _onUpdateDiscountStatus(
    UpdateDiscountStatus event,
    Emitter<DiscountState> emit,
  ) async {
    try {
      emit(DiscountLoading());
      
      await _firestore
          .collection('vouchers')
          .doc(event.discountId)
          .update({'isActive': event.isActive});

      emit(DiscountUpdated());
      add(LoadDiscounts(event.parkingLotId));
    } catch (e) {
      emit(DiscountError(e.toString()));
    }
  }

  Future<void> _onDeleteDiscount(
    DeleteDiscount event,
    Emitter<DiscountState> emit,
  ) async {
    try {
      emit(DiscountLoading());
      
      await _firestore
          .collection('vouchers')
          .doc(event.discountId)
          .delete();

      emit(DiscountDeleted());
    } catch (e) {
      emit(DiscountError(e.toString()));
    }
  }

  Future<void> _onSendDiscountNotification(
    SendDiscountNotification event,
    Emitter<DiscountState> emit,
  ) async {
    try {
      emit(DiscountLoading());
      
      // Gửi thông báo đến tất cả người dùng
      await _firestore.collection('notifications').add({
        'title': 'Mã giảm giá mới',
        'body': 'Bạn có mã giảm giá mới: ${event.code} với ${event.discountPercent}% giảm giá',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'discount',
      });

      emit(NotificationSent());
    } catch (e) {
      emit(DiscountError(e.toString()));
    }
  }
} 