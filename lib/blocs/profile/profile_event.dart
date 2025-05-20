import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final String userId;

  const LoadProfileEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final String name;
  final String phone;
  final String address;

  const UpdateProfileEvent({
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
  });

  @override
  List<Object?> get props => [userId, name, phone, address];
}

class UpdateAvatarEvent extends ProfileEvent {
  final String userId;
  final String avatarUrl;

  const UpdateAvatarEvent({
    required this.userId,
    required this.avatarUrl,
  });

  @override
  List<Object?> get props => [userId, avatarUrl];
} 