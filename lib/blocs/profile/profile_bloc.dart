import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../../models/owner_model.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseFirestore _firestore;
  OwnerModel? _currentProfile;

  ProfileBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateAvatarEvent>(_onUpdateAvatar);
    on<UpdateQRCodeEvent>(_onUpdateQRCode);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      final doc = await _firestore.collection('user_owner').doc(event.userId).get();
      
      if (!doc.exists) {
        emit(const ProfileError('Không tìm thấy thông tin người dùng'));
        return;
      }

      _currentProfile = OwnerModel.fromMap(doc.data()!);
      emit(ProfileLoaded(_currentProfile!));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileUpdating());
      
      final docRef = _firestore.collection('user_owner').doc(event.userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        emit(const ProfileError('Không tìm thấy thông tin người dùng'));
        return;
      }

      final currentData = doc.data()!;
      final updatedData = {
        ...currentData,
        'name': event.name,
        'phone': event.phone,
        'address': event.address,
      };

      await docRef.update(updatedData);
      
      _currentProfile = OwnerModel.fromMap(updatedData);
      emit(ProfileUpdated(_currentProfile!));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatarEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileUpdating());
      
      final docRef = _firestore.collection('user_owner').doc(event.userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        emit(const ProfileError('Không tìm thấy thông tin người dùng'));
        return;
      }

      final currentData = doc.data()!;
      final updatedData = {
        ...currentData,
        'avatar': event.avatarUrl,
      };

      await docRef.update(updatedData);
      
      _currentProfile = OwnerModel.fromMap(updatedData);
      emit(ProfileUpdated(_currentProfile!));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateQRCode(
    UpdateQRCodeEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileUpdating());
      
      final docRef = _firestore.collection('user_owner').doc(event.userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        emit(const ProfileError('Không tìm thấy thông tin người dùng'));
        return;
      }

      final currentData = doc.data()!;
      final updatedData = {
        ...currentData,
        'qrcode': event.qrCodeUrl,
      };

      await docRef.update(updatedData);
      
      _currentProfile = OwnerModel.fromMap(updatedData);
      emit(ProfileUpdated(_currentProfile!));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
} 