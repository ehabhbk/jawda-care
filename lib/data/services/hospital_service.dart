import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital_model.dart';

class HospitalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<HospitalModel>> getHospitals() {
    return _firestore
        .collection('hospitals')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<List<HospitalModel>> getAllHospitals() async {
    final snapshot = await _firestore
        .collection('hospitals')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<HospitalModel?> getHospitalById(String hospitalId) async {
    final doc = await _firestore.collection('hospitals').doc(hospitalId).get();
    if (doc.exists) {
      return HospitalModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<Map<String, int>> countAvailableBedsByHospital() async {
    final snapshot = await _firestore.collection('beds').get();
    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'available') {
        final hospitalId = data['hospitalId'] as String?;
        if (hospitalId != null && hospitalId.isNotEmpty) {
          counts[hospitalId] = (counts[hospitalId] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Future<List<HospitalModel>> getHospitalsWithAvailableBeds() async {
    final snapshot = await _firestore
        .collection('hospitals')
        .where('isActive', isEqualTo: true)
        .get();

    final counts = await countAvailableBedsByHospital();

    final hospitals = snapshot.docs
        .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
        .where((h) => (counts[h.id] ?? 0) > 0)
        .toList();

    return hospitals;
  }

  Future<List<HospitalModel>> getNearestHospitals({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) async {
    final snapshot = await _firestore
        .collection('hospitals')
        .where('isActive', isEqualTo: true)
        .get();

    final counts = await countAvailableBedsByHospital();

    final hospitals = snapshot.docs
        .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
        .where((h) => (counts[h.id] ?? 0) > 0)
        .toList();

    hospitals.sort((a, b) {
      final da = _calculateDistance(lat, lng, a.latitude, a.longitude);
      final db = _calculateDistance(lat, lng, b.latitude, b.longitude);
      return da.compareTo(db);
    });

    return hospitals;
  }

  Future<void> addHospital(HospitalModel hospital) async {
    await _firestore
        .collection('hospitals')
        .doc(hospital.id)
        .set(hospital.toMap());
  }

  Future<void> updateHospital(
    String hospitalId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('hospitals').doc(hospitalId).update(data);
  }

  Future<void> updateAvailableBeds(String hospitalId, int delta) async {
    await _firestore.collection('hospitals').doc(hospitalId).update({
      'availableBeds': FieldValue.increment(delta),
    });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double radius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return radius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}
