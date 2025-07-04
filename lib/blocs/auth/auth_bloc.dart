import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    developer.log('Bắt đầu quá trình đăng ký trong AuthBloc', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      developer.log('Thông tin đăng ký chi tiết:', name: 'AuthBloc');
      developer.log('Email: ${event.email}', name: 'AuthBloc');
      developer.log('Name: ${event.name}', name: 'AuthBloc');
      developer.log('Phone: ${event.phone}', name: 'AuthBloc');
      developer.log('Address: ${event.address}', name: 'AuthBloc');
      developer.log('Avatar URL: ${event.avatar}', name: 'AuthBloc');
      developer.log('QR Code URL: ${event.qrcode}', name: 'AuthBloc');
      
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
        address: event.address,
        avatar: event.avatar,
        qrcode: event.qrcode,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      developer.log('Đăng ký thành công với user ID: ${user?.uid}', name: 'AuthBloc');
      emit(Authenticated(user));
    } catch (e) {
      developer.log('Lỗi đăng ký chi tiết:', name: 'AuthBloc');
      developer.log('Error type: ${e.runtimeType}', name: 'AuthBloc');
      developer.log('Error message: ${e.toString()}', name: 'AuthBloc', error: e);
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      final user = FirebaseAuth.instance.currentUser;
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }
} 