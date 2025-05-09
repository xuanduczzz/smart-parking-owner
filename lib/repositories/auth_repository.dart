import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_model.dart';

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
    String payimg = '',
    String qrcode = '',
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final owner = OwnerModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        address: address,
        createdAt: DateTime.now(),
        avatar: avatar,
        payimg: payimg,
        qrcode: qrcode,
        status: false,
      );

      await _firestore
          .collection('user_owner')
          .doc(userCredential.user!.uid)
          .set(owner.toMap());

      return userCredential;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
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
      } else {
        throw Exception(e.message ?? 'Lỗi đăng nhập');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 