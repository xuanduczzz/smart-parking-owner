import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createStatusChangeNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    print('📨 Đang tạo thông báo trạng thái...');
    print('👤 User ID: $userId');
    print('📝 Tiêu đề: $title');
    print('📄 Nội dung: $body');

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Đã tạo thông báo trạng thái thành công');
  }

  Future<void> createTimeRemainingNotification({
    required String userId,
    required int minutesRemaining,
  }) async {
    final title = 'Thông báo thời gian còn lại';
    final body = 'Reservation của bạn còn ${minutesRemaining} phút nữa sẽ kết thúc';
    
    print('⏰ Đang tạo thông báo thời gian còn lại...');
    print('👤 User ID: $userId');
    print('⏳ Thời gian còn lại: $minutesRemaining phút');
    print('📝 Tiêu đề: $title');
    print('📄 Nội dung: $body');

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Đã tạo thông báo thời gian còn lại thành công');
  }

  Future<void> scheduleTimeRemainingNotifications({
    required String userId,
    required DateTime endTime,
  }) async {
    final now = DateTime.now();
    final timeUntilEnd = endTime.difference(now);
    final minutesRemaining = timeUntilEnd.inMinutes;
    
    print('🔄 Đang kiểm tra thời gian để tạo thông báo...');
    print('⏱️ Thời gian hiện tại: ${now.toString()}');
    print('⏱️ Thời gian kết thúc: ${endTime.toString()}');
    print('⏱️ Thời gian còn lại: $minutesRemaining phút');
    
    // Tính thời điểm chính xác cho 10 phút và 5 phút trước khi kết thúc
    final tenMinutesBefore = endTime.subtract(const Duration(minutes: 10));
    final fiveMinutesBefore = endTime.subtract(const Duration(minutes: 5));
    
    // Kiểm tra xem thời gian hiện tại có nằm trong khoảng 1 phút của thời điểm cần tạo thông báo không
    final isWithinTenMinutes = now.isAfter(tenMinutesBefore.subtract(const Duration(minutes: 1))) && 
                              now.isBefore(tenMinutesBefore.add(const Duration(minutes: 1)));
    
    final isWithinFiveMinutes = now.isAfter(fiveMinutesBefore.subtract(const Duration(minutes: 1))) && 
                               now.isBefore(fiveMinutesBefore.add(const Duration(minutes: 1)));
    
    if (isWithinTenMinutes) {
      print('🔔 Đang tạo thông báo cho 10 phút còn lại');
      await createTimeRemainingNotification(
        userId: userId,
        minutesRemaining: 10,
      );
    } else if (isWithinFiveMinutes) {
      print('🔔 Đang tạo thông báo cho 5 phút còn lại');
      await createTimeRemainingNotification(
        userId: userId,
        minutesRemaining: 5,
      );
    } else {
      print('⏳ Chưa đến thời điểm tạo thông báo (cần 10p hoặc 5p)');
    }
  }
} 