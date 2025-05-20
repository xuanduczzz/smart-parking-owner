import 'package:equatable/equatable.dart';

abstract class DiscountEvent extends Equatable {
  const DiscountEvent();

  @override
  List<Object> get props => [];
}

class LoadDiscounts extends DiscountEvent {
  final String parkingLotId;

  const LoadDiscounts(this.parkingLotId);

  @override
  List<Object> get props => [parkingLotId];
}

class CreateDiscount extends DiscountEvent {
  final String code;
  final int discountPercent;
  final DateTime expiresAt;
  final int usageLimit;
  final String parkingLotId;

  const CreateDiscount({
    required this.code,
    required this.discountPercent,
    required this.expiresAt,
    required this.usageLimit,
    required this.parkingLotId,
  });

  @override
  List<Object> get props => [code, discountPercent, expiresAt, usageLimit, parkingLotId];
}

class UpdateDiscountStatus extends DiscountEvent {
  final String discountId;
  final bool isActive;
  final String parkingLotId;

  const UpdateDiscountStatus({
    required this.discountId,
    required this.isActive,
    required this.parkingLotId,
  });

  @override
  List<Object> get props => [discountId, isActive, parkingLotId];
}

class DeleteDiscount extends DiscountEvent {
  final String discountId;

  const DeleteDiscount(this.discountId);

  @override
  List<Object> get props => [discountId];
}

class SendDiscountNotification extends DiscountEvent {
  final String code;
  final int discountPercent;

  const SendDiscountNotification({
    required this.code,
    required this.discountPercent,
  });

  @override
  List<Object> get props => [code, discountPercent];
} 