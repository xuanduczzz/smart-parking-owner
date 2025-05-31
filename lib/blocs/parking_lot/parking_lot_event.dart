import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ParkingLotEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddParkingLotEvent extends ParkingLotEvent {
  final String name;
  final String address;
  final double pricePerHour;
  final double lat;
  final double lng;
  final List<File> imageFiles;
  final List<File> mapFiles;

  AddParkingLotEvent({
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.lat,
    required this.lng,
    required this.imageFiles,
    required this.mapFiles,
  });

  @override
  List<Object?> get props => [name, address, pricePerHour, lat, lng, imageFiles, mapFiles];
}

class SaveParkingLotWithSlotsEvent extends ParkingLotEvent {
  final String name;
  final String address;
  final double pricePerHour;
  final double lat;
  final double lng;
  final List<File> imageFiles;
  final List<File> mapFiles;
  final List<Map<String, dynamic>> slots;
  final bool status;

  SaveParkingLotWithSlotsEvent({
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.lat,
    required this.lng,
    required this.imageFiles,
    required this.mapFiles,
    required this.slots,
    required this.status,
  });

  @override
  List<Object?> get props => [name, address, pricePerHour, lat, lng, imageFiles, mapFiles, slots, status];
}

class UpdateParkingLotWithSlotsEvent extends ParkingLotEvent {
  final String docId;
  final String name;
  final String address;
  final double pricePerHour;
  final double lat;
  final double lng;
  final List<File> imageFiles;
  final List<File> mapFiles;
  final List<String> existingImageUrls;
  final List<String> existingMapUrls;
  final List<Map<String, dynamic>> slots;

  UpdateParkingLotWithSlotsEvent({
    required this.docId,
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.lat,
    required this.lng,
    required this.imageFiles,
    required this.mapFiles,
    required this.existingImageUrls,
    required this.existingMapUrls,
    required this.slots,
  });

  @override
  List<Object?> get props => [docId, name, address, pricePerHour, lat, lng, imageFiles, mapFiles, existingImageUrls, existingMapUrls, slots];
} 