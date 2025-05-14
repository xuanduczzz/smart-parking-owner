import 'package:equatable/equatable.dart';
import '../../models/discount_code.dart';

abstract class VoucherEvent extends Equatable {
  const VoucherEvent();

  @override
  List<Object> get props => [];
}

class LoadVouchers extends VoucherEvent {
  final String parkingLotId;

  const LoadVouchers(this.parkingLotId);

  @override
  List<Object> get props => [parkingLotId];
}

class CreateVoucher extends VoucherEvent {
  final String code;
  final int discountPercent;
  final DateTime expiresAt;
  final int usageLimit;
  final String parkingLotId;

  const CreateVoucher({
    required this.code,
    required this.discountPercent,
    required this.expiresAt,
    required this.usageLimit,
    required this.parkingLotId,
  });

  @override
  List<Object> get props => [code, discountPercent, expiresAt, usageLimit, parkingLotId];
}

class UpdateVoucherStatus extends VoucherEvent {
  final String voucherId;
  final bool isActive;
  final String parkingLotId;

  const UpdateVoucherStatus({
    required this.voucherId,
    required this.isActive,
    required this.parkingLotId,
  });

  @override
  List<Object> get props => [voucherId, isActive, parkingLotId];
}

class SendNotification extends VoucherEvent {
  final String userId;
  final String title;
  final String body;

  const SendNotification({
    required this.userId,
    required this.title,
    required this.body,
  });

  @override
  List<Object> get props => [userId, title, body];
}

class DeleteVoucher extends VoucherEvent {
  final String voucherId;

  const DeleteVoucher({
    required this.voucherId,
  });

  @override
  List<Object> get props => [voucherId];
} 