import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_model.dart';
import 'dart:developer' as developer;

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    String avatar = '',
    String qrcode = '',
  }) async {
    developer.log('Bắt đầu tạo tài khoản Firebase', name: 'AuthRepository');
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      developer.log('Tạo tài khoản Firebase thành công: ${userCredential.user?.uid}', name: 'AuthRepository');

      final owner = OwnerModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        address: address,
        createdAt: DateTime.now(),
        avatar: avatar,
        qrcode: qrcode,
        status: false,
      );
      developer.log('Tạo model Owner thành công', name: 'AuthRepository');

      await _firestore
          .collection('user_owner')
          .doc(userCredential.user!.uid)
          .set(owner.toMap());
      developer.log('Lưu thông tin owner vào Firestore thành công', name: 'AuthRepository');

      return userCredential;
    } catch (e) {
      developer.log('Lỗi trong quá trình đăng ký: ${e.toString()}', name: 'AuthRepository', error: e);
      throw Exception(e.toString());
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        // Kiểm tra kết nối internet
        try {
          await _firestore.collection('user_owner').limit(1).get();
        } catch (e) {
          throw Exception('Không có kết nối internet. Vui lòng kiểm tra lại kết nối của bạn.');
        }

      // Kiểm tra email có tồn tại trong collection user_owner không
      final querySnapshot = await _firestore
          .collection('user_owner')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Email không tồn tại trong hệ thống');
      }

      // Kiểm tra status của tài khoản
      final ownerData = querySnapshot.docs.first.data();
      if (ownerData['status'] != true) {
        throw Exception('Tài khoản chưa được xác nhận');
      }

      // Nếu email tồn tại và status là true, tiến hành đăng nhập
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email không tồn tại');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không đúng');
        } else if (e.code == 'network-request-failed') {
          retryCount++;
          if (retryCount == maxRetries) {
            throw Exception('Lỗi kết nối mạng. Vui lòng thử lại sau.');
          }
          await Future.delayed(Duration(seconds: retryCount));
          continue;
      } else {
        throw Exception(e.message ?? 'Lỗi đăng nhập');
      }
    } catch (e) {
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          retryCount++;
          if (retryCount == maxRetries) {
            throw Exception('Lỗi kết nối mạng. Vui lòng thử lại sau.');
          }
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        }
      throw Exception(e.toString());
      }
    }
    throw Exception('Đã hết số lần thử lại. Vui lòng thử lại sau.');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 