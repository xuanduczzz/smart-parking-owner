import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as path;

class CloudinaryService {
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dqnbclzi5', // Thay thế bằng cloud name của bạn
    'avatar_img', // Thay thế bằng upload preset của bạn
  );

  Future<String> uploadImage(File imageFile) async {
    try {
      final result = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'owner_app', // Thư mục lưu trữ trên Cloudinary
        ),
      );
      return result.secureUrl;
    } catch (e) {
      throw Exception('Lỗi khi tải ảnh lên: ${e.toString()}');
    }
  }
} 