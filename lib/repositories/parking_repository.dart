import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParkingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ParkingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<QuerySnapshot> getParkingLots() {
    final userId = _auth.currentUser?.uid ?? '';
    return _firestore
        .collection('parking_lots')
        .where('oid', isEqualTo: userId)
        .snapshots();
  }

  Future<QuerySnapshot> getParkingSlots(String parkingLotId) {
    return _firestore
        .collection('parking_lots')
        .doc(parkingLotId)
        .collection('slots')
        .get();
  }

  Future<void> updateParkingLotStatus(String parkingLotId, bool status) {
    return _firestore
        .collection('parking_lots')
        .doc(parkingLotId)
        .update({'status': status});
  }
} 