import 'dart:io';

abstract class ParkingLotEvent {}

class LoadParkingLotsEvent extends ParkingLotEvent {}

class LoadParkingSlotsEvent extends ParkingLotEvent {
  final String parkingLotId;

  LoadParkingSlotsEvent(this.parkingLotId);
}

class CheckAvailableSlotsEvent extends ParkingLotEvent {
  final String lotId;
  final String vehicleType;
  final DateTime startTime;
  final DateTime endTime;

  CheckAvailableSlotsEvent({
    required this.lotId,
    required this.vehicleType,
    required this.startTime,
    required this.endTime,
  });
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
}

class UpdateParkingLotStatusEvent extends ParkingLotEvent {
  final String parkingLotId;
  final bool status;

  UpdateParkingLotStatusEvent({
    required this.parkingLotId,
    required this.status,
  });
}

class LoadExistingSlotsEvent extends ParkingLotEvent {
  final String parkingLotId;

  LoadExistingSlotsEvent(this.parkingLotId);
}

class SaveSlotsEvent extends ParkingLotEvent {
  final String? parkingLotId;
  final List<Map<String, dynamic>> slots;
  final bool isEditing;

  SaveSlotsEvent({
    this.parkingLotId,
    required this.slots,
    required this.isEditing,
  });
} 