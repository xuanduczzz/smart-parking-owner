import 'package:equatable/equatable.dart';
import '../../models/discount_code.dart';

abstract class DiscountState extends Equatable {
  const DiscountState();

  @override
  List<Object> get props => [];
}

class DiscountInitial extends DiscountState {}

class DiscountLoading extends DiscountState {}

class DiscountLoaded extends DiscountState {
  final List<DiscountCode> discounts;

  const DiscountLoaded(this.discounts);

  @override
  List<Object> get props => [discounts];
}

class DiscountError extends DiscountState {
  final String message;

  const DiscountError(this.message);

  @override
  List<Object> get props => [message];
}

class DiscountCreated extends DiscountState {}

class DiscountUpdated extends DiscountState {}

class DiscountDeleted extends DiscountState {}

class NotificationSent extends DiscountState {} 