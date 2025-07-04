import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/parking_repository.dart';
import 'parking_lot_event.dart';
import 'parking_lot_state.dart';

class ParkingLotBloc extends Bloc<ParkingLotEvent, ParkingLotState> {
  final CloudinaryPublic _cloudinary;
  final ParkingRepository _parkingRepository;
  final FirebaseFirestore _firestore;

  ParkingLotBloc(
    this._cloudinary, {
    ParkingRepository? parkingRepository,
    FirebaseFirestore? firestore,
  })  : _parkingRepository = parkingRepository ?? ParkingRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(ParkingLotInitial()) {
    on<LoadParkingLotsEvent>(_onLoadParkingLots);
    on<LoadParkingSlotsEvent>(_onLoadParkingSlots);
    on<SaveParkingLotWithSlotsEvent>(_onSaveParkingLotWithSlots);
    on<UpdateParkingLotWithSlotsEvent>(_onUpdateParkingLotWithSlots);
    on<UpdateParkingLotStatusEvent>(_onUpdateParkingLotStatus);
    on<CheckAvailableSlotsEvent>(_onCheckAvailableSlots);
    on<LoadExistingSlotsEvent>(_onLoadExistingSlots);
    on<SaveSlotsEvent>(_onSaveSlots);
  }

  Future<void> _onLoadParkingLots(
    LoadParkingLotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      final snapshot = await _parkingRepository.getParkingLots().first;
      emit(ParkingLotLoaded(snapshot));
    } catch (e) {
      print('Error loading parking lots: $e');
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onLoadParkingSlots(
    LoadParkingSlotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      final slots = await _parkingRepository.getParkingSlots(event.parkingLotId);
      emit(ParkingSlotsLoaded(slots));
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onCheckAvailableSlots(
    CheckAvailableSlotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      print('--- [ParkingLotBloc] CheckAvailableSlots ---');
      print('LotId: ${event.lotId}');
      print('VehicleType: ${event.vehicleType}');
      print('Start: ${event.startTime}');
      print('End: ${event.endTime}');

      // Lấy tất cả các slot từ Firestore và lọc theo vehicleType
      final snapshot = await _firestore
          .collection('parking_lots')
          .doc(event.lotId)
          .collection('slots')
          .where('vehicle', isEqualTo: event.vehicleType)
          .get();
      print('Tổng số slot lấy được: ${snapshot.docs.length}');

      // Lấy tất cả các đặt chỗ trong collection reservations
      final reservationSnapshot = await _firestore
          .collection('reservations')
          .where('lotId', isEqualTo: event.lotId)
          .get();
      print('Tổng số reservation lấy được: ${reservationSnapshot.docs.length}');

      // Danh sách các slot đã bị đặt
      final bookedSlotIds = reservationSnapshot.docs.where((reservationDoc) {
        final reservationData = reservationDoc.data();
        final startTime = (reservationData['startTime'] as Timestamp).toDate();
        final endTime = (reservationData['endTime'] as Timestamp).toDate();
        print('Reservation: slotId=${reservationData['slotId']} start=$startTime end=$endTime');
        // Kiểm tra nếu thời gian đặt chỗ trùng với khoảng thời gian người dùng nhập
        return (event.startTime.isBefore(endTime) && event.endTime.isAfter(startTime));
      }).map((reservationDoc) => reservationDoc['slotId'] as String).toList();
      print('SlotId đã bị đặt/reserved: $bookedSlotIds');

      final slots = snapshot.docs.map((doc) {
        final data = doc.data();
        final slot = {
          'id': doc.id,
          'isBooked': bookedSlotIds.contains(doc.id),
          'vehicleType': data['vehicle'],
          'pendingReservations': data['pendingReservations'] ?? [],
        };
        return slot;
      }).toList();

      print('Số slot còn lại sau lọc: ${slots.where((s) => !s['isBooked']).length}');
      emit(AvailableSlotsLoaded(slots));
    } catch (e) {
      print('Lỗi khi check available slots: $e');
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onSaveParkingLotWithSlots(
    SaveParkingLotWithSlotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      
      print('=== [ParkingLotBloc] SaveParkingLotWithSlots ===');
      print('Creating new parking lot...');
      
      // Upload ảnh lên Cloudinary
      final imageUrls = await Future.wait(
        event.imageFiles.map((file) => _cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        )),
      );

      final mapUrls = await Future.wait(
        event.mapFiles.map((file) => _cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        )),
      );

      // Tạo document mới trong collection parking_lots
      final docRef = await _firestore.collection('parking_lots').add({
        'name': event.name,
        'address': event.address,
        'pricePerHour': event.pricePerHour,
        'location': GeoPoint(event.lat, event.lng),
        'imageUrl': imageUrls.map((response) => response.secureUrl).toList(),
        'parkingLotMap': mapUrls.map((response) => response.secureUrl).toList(),
        'status': event.status,
        'oid': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Created parking lot with ID: ${docRef.id}');
      print('Saving slots...');

      // Lưu thông tin slots
      for (var slot in event.slots) {
        final slotId = slot['documentId'] as String;
        print('Creating slot with ID: $slotId');
        
        final slotRef = _firestore
            .collection('parking_lots')
            .doc(docRef.id)
            .collection('slots')
            .doc(slotId);
            
        print('Slot document path: ${slotRef.path}');
        
        await slotRef.set({
          'id': slot['id'],
          'vehicle': slot['vehicle'],
          'isBooked': slot['isBooked'],
        });
        
        print('Created slot document with ID: ${slotRef.id}');
      }

      print('All slots saved successfully');
      emit(ParkingLotSuccess());
    } catch (e) {
      print('Error saving parking lot and slots: $e');
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onUpdateParkingLotWithSlots(
    UpdateParkingLotWithSlotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      
      // Upload ảnh mới lên Cloudinary nếu có
      final newImageUrls = await Future.wait(
        event.imageFiles.map((file) => _cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        )),
      );

      final newMapUrls = await Future.wait(
        event.mapFiles.map((file) => _cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
        )),
      );

      // Cập nhật thông tin bãi đỗ xe
      await _firestore.collection('parking_lots').doc(event.docId).update({
        'name': event.name,
        'address': event.address,
        'pricePerHour': event.pricePerHour,
        'location': GeoPoint(event.lat, event.lng),
        'imageUrl': [...event.existingImageUrls, ...newImageUrls.map((response) => response.secureUrl)],
        'parkingLotMap': [...event.existingMapUrls, ...newMapUrls.map((response) => response.secureUrl)],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật thông tin slots
      final batch = _firestore.batch();
      final slotsCollection = _firestore.collection('parking_lots').doc(event.docId).collection('slots');
      
      // Xóa tất cả slots cũ
      final existingSlots = await slotsCollection.get();
      for (var doc in existingSlots.docs) {
        batch.delete(doc.reference);
      }

      // Thêm slots mới
      for (var slot in event.slots) {
        final slotId = slot['documentId'] as String;
        final slotRef = slotsCollection.doc(slotId);
        batch.set(slotRef, {
          'id': slot['id'],
          'vehicle': slot['vehicle'],
          'isBooked': slot['isBooked'],
        });
      }
      await batch.commit();

      emit(ParkingLotSuccess());
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onUpdateParkingLotStatus(
    UpdateParkingLotStatusEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      await _parkingRepository.updateParkingLotStatus(
        event.parkingLotId,
        event.status,
      );
      emit(ParkingLotSuccess());
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onLoadExistingSlots(
    LoadExistingSlotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      final slotsSnapshot = await _firestore
          .collection('parking_lots')
          .doc(event.parkingLotId)
          .collection('slots')
          .get();
      
      final slots = slotsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'],
          'vehicle': data['vehicle'],
        };
      }).toList();

      emit(ExistingSlotsLoaded(slots));
    } catch (e) {
      emit(ParkingLotError(e.toString()));
    }
  }

  Future<void> _onSaveSlots(
    SaveSlotsEvent event,
    Emitter<ParkingLotState> emit,
  ) async {
    try {
      emit(ParkingLotLoading());
      
      print('=== [ParkingLotBloc] SaveSlots ===');
      print('Parking lot ID: ${event.parkingLotId}');
      
      if (event.isEditing && event.parkingLotId != null) {
        final slotsCollection = _firestore
            .collection('parking_lots')
            .doc(event.parkingLotId)
            .collection('slots');
        
        print('Getting existing slots...');
        // Lấy danh sách slots hiện tại
        final existingSlotsSnapshot = await slotsCollection.get();
        final existingSlots = existingSlotsSnapshot.docs.map((doc) => doc.data()).toList();
        print('Found ${existingSlots.length} existing slots');

        // Tạo batch để thực hiện tất cả các thao tác
        final batch = _firestore.batch();
        
        // Xử lý từng slot mới
        for (var newSlot in event.slots) {
          final slotId = newSlot['id'] as String;
          print('\nProcessing slot with ID: $slotId');
          
          final existingSlot = existingSlots.firstWhere(
            (slot) => slot['id'] == slotId,
            orElse: () => {'id': null},
          );

          if (existingSlot['id'] == null) {
            print('Creating new slot...');
            // Slot mới - tạo mới với ID được nhập làm document ID
            final slotRef = slotsCollection.doc(slotId);
                
            print('Slot document path: ${slotRef.path}');
            
            // Thêm vào batch
            batch.set(slotRef, {
              'id': slotId,
              'vehicle': newSlot['vehicle'],
              'isBooked': false,
            });
            
            print('Added to batch: Create slot document with ID: $slotId');
          } else {
            print('Updating existing slot...');
            // Slot đã tồn tại - cập nhật nếu có thay đổi
            if (existingSlot['vehicle'] != newSlot['vehicle']) {
              final slotRef = slotsCollection.doc(slotId);
                  
              print('Slot document path: ${slotRef.path}');
              
              // Thêm vào batch
              batch.update(slotRef, {
                'vehicle': newSlot['vehicle'],
              });
              
              print('Added to batch: Update slot document with ID: $slotId');
            } else {
              print('No changes needed for this slot');
            }
          }
        }

        print('\nRemoving slots not in new list...');
        // Xóa các slot không còn trong danh sách mới
        final newSlotIds = event.slots.map((slot) => slot['id'] as String).toList();
        for (var existingSlot in existingSlots) {
          if (!newSlotIds.contains(existingSlot['id'])) {
            print('Removing slot with ID: ${existingSlot['id']}');
            final slotRef = slotsCollection.doc(existingSlot['id']);
                
            print('Slot document path: ${slotRef.path}');
            
            // Thêm vào batch
            batch.delete(slotRef);
            
            print('Added to batch: Delete slot document with ID: ${existingSlot['id']}');
          }
        }
        
        // Thực hiện tất cả các thao tác trong batch
        print('\nCommitting batch...');
        await batch.commit();
        print('Batch committed successfully');
        
        print('All slots processed successfully');
      }

      emit(ParkingLotSuccess());
    } catch (e) {
      print('Error saving slots: $e');
      emit(ParkingLotError(e.toString()));
    }
  }
} 