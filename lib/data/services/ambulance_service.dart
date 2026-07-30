import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ambulance_model.dart';

class AmbulanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AmbulanceModel>> getAmbulancesByHospital(String hospitalId) {
    return _firestore
        .collection('ambulances')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AmbulanceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<AmbulanceModel?> getAmbulanceByDriverId(String driverId) async {
    final snapshot = await _firestore
        .collection('ambulances')
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AmbulanceModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    }
    return null;
  }

  Future<void> updateStatus(String ambulanceId, String status) async {
    await _firestore.collection('ambulances').doc(ambulanceId).update({
      'status': status,
    });
  }

  Future<void> updateLocation({
    required String ambulanceId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('ambulances').doc(ambulanceId).update({
      'currentLat': lat,
      'currentLng': lng,
    });
  }

  Future<AmbulanceModel?> getAmbulanceById(String ambulanceId) async {
    final doc = await _firestore.collection('ambulances').doc(ambulanceId).get();
    if (doc.exists) {
      return AmbulanceModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
