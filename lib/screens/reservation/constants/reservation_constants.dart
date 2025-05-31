class ReservationConstants {
  static const List<String> statusList = [
    'pending',
    'confirmed',
    'checkin',
    'checkout',
    'completed',
    'cancelled',
  ];

  static const Map<String, String> statusTextMap = {
    'pending': 'Chờ xác nhận',
    'confirmed': 'Đã xác nhận',
    'cancelled': 'Đã hủy',
    'checkin': 'Đã check-in',
    'checkout': 'Đã check-out',
    'completed': 'Đã kết thúc',
  };

  static const Map<String, String> statusIconMap = {
    'pending': 'Icons.hourglass_empty',
    'confirmed': 'Icons.check_circle',
    'cancelled': 'Icons.cancel',
    'checkin': 'Icons.login',
    'checkout': 'Icons.logout',
    'completed': 'Icons.check_circle_outline',
  };
} 