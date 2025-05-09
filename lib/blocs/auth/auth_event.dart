abstract class AuthEvent {}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String address;
  final String avatar;
  final String payimg;
  final String qrcode;

  SignUpEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.address,
    required this.avatar,
    required this.payimg,
    required this.qrcode,
  });
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent({
    required this.email,
    required this.password,
  });
}

class SignOutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {} 