import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final _cloudinary = CloudinaryPublic('dqnbclzi5', 'avatar_img', cache: false);
  final _imagePicker = ImagePicker();

  Future<String?> uploadImage({
    required ImageSource source,
    double maxWidth = 400.0,
    double maxHeight = 400.0,
    double imageQuality = 0.6,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: (imageQuality * 100).toInt(),
      );

      if (pickedFile != null) {
        final cloudinaryFile = CloudinaryFile.fromFile(
          pickedFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: "avatar_img",
        );

        final response = await _cloudinary.uploadFile(
          cloudinaryFile,
          onProgress: (count, total) {
            // Có thể thêm xử lý progress ở đây nếu cần
          },
        );

        // Áp dụng transformation cho URL
        final transformedUrl = response.secureUrl.replaceAll(
          '/upload/',
          '/upload/c_fill,w_200,h_200,q_60/',
        );

        return transformedUrl;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImageFromPath({
    required String path,
    double imageQuality = 0.6,
  }) async {
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        path,
        resourceType: CloudinaryResourceType.Image,
        folder: "avatar_img",
      );

      final response = await _cloudinary.uploadFile(
        cloudinaryFile,
        onProgress: (count, total) {
          // Có thể thêm xử lý progress ở đây nếu cần
        },
      );

      // Áp dụng transformation cho URL
      final transformedUrl = response.secureUrl.replaceAll(
        '/upload/',
        '/upload/c_fill,w_200,h_200,q_60/',
      );

      return transformedUrl;
    } catch (e) {
      rethrow;
    }
  }
} 