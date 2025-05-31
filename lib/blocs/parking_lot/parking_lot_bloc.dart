import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parking_lot_event.dart';
import 'parking_lot_state.dart';

class ParkingLotBloc extends Bloc<ParkingLotEvent, ParkingLotState> {
  final CloudinaryPublic cloudinary;

  ParkingLotBloc(this.cloudinary) : super(ParkingLotInitial()) {
    on<AddParkingLotEvent>(_onAddParkingLot);
    on<SaveParkingLotWithSlotsEvent>(_onSaveParkingLotWithSlots);
    on<UpdateParkingLotWithSlotsEvent>(_onUpdateParkingLotWithSlots);
  }

  Future<void> _onAddParkingLot(AddParkingLotEvent event, Emitter<ParkingLotState> emit) async {
    emit(ParkingLotLoading());
    try {
      List<String> imageUrls = [];
      List<String> mapUrls = [];
      for (var file in event.imageFiles) {
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        );
        imageUrls.add(res.secureUrl);
      }
      for (var file in event.mapFiles) {
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        );
        mapUrls.add(res.secureUrl);
      }
      await FirebaseFirestore.instance.collection('parking_lots').add({
        'name': event.name,
        'address': event.address,
        'pricePerHour': event.pricePerHour,
        'location': GeoPoint(event.lat, event.lng),
        'imageUrl': imageUrls,
        'parkingLotMap': mapUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(ParkingLotSuccess());
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onSaveParkingLotWithSlots(SaveParkingLotWithSlotsEvent event, Emitter<ParkingLotState> emit) async {
    emit(ParkingLotLoading());
    try {
      List<String> imageUrls = [];
      List<String> mapUrls = [];
      for (var file in event.imageFiles) {
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        );
        imageUrls.add(res.secureUrl);
      }
      for (var file in event.mapFiles) {
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        );
        mapUrls.add(res.secureUrl);
      }
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final parkingLotRef = await FirebaseFirestore.instance.collection('parking_lots').add({
        'name': event.name,
        'address': event.address,
        'pricePerHour': event.pricePerHour,
        'location': GeoPoint(event.lat, event.lng),
        'imageUrl': imageUrls,
        'parkingLotMap': mapUrls,
        'totalSlots': event.slots.length,
        'oid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': event.status,
      });
      for (final slot in event.slots) {
        await parkingLotRef.collection('slots').doc(slot['id']).set(slot);
      }
      emit(ParkingLotSuccess());
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onUpdateParkingLotWithSlots(UpdateParkingLotWithSlotsEvent event, Emitter<ParkingLotState> emit) async {
    emit(ParkingLotLoading());
    try {
      List<String> imageUrls = [...event.existingImageUrls];
      List<String> mapUrls = [...event.existingMapUrls];

      // Upload new images
      for (var file in event.imageFiles) {
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        );
        imageUrls.add(res.secureUrl);
      }
      for (var file in event.mapFiles) {
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        );
        mapUrls.add(res.secureUrl);
      }

      // Update parking lot
      await FirebaseFirestore.instance.collection('parking_lots').doc(event.docId).update({
        'name': event.name,
        'address': event.address,
        'pricePerHour': event.pricePerHour,
        'location': GeoPoint(event.lat, event.lng),
        'imageUrl': imageUrls,
        'parkingLotMap': mapUrls,
        'totalSlots': event.slots.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete all existing slots
      final slotsSnapshot = await FirebaseFirestore.instance
          .collection('parking_lots')
          .doc(event.docId)
          .collection('slots')
          .get();
      
      for (var doc in slotsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Add new slots
      for (final slot in event.slots) {
        await FirebaseFirestore.instance
            .collection('parking_lots')
            .doc(event.docId)
            .collection('slots')
            .doc(slot['id'])
            .set(slot);
      }

      emit(ParkingLotSuccess());
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }
} 