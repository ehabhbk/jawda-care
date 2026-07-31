import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bed_model.dart';

class BedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BedModel>> getBedsByDepartment(String departmentId) {
    return _firestore
        .collection('beds')
        .where('departmentId', isEqualTo: departmentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BedModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<BedModel>> getAvailableBedsByHospital(String hospitalId) {
    return _firestore
        .collection('beds')
        .where('hospitalId', isEqualTo: hospitalId)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BedModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addBed(BedModel bed) async {
    await _firestore.collection('beds').add(bed.toMap());
  }

  Future<void> updateBed({
    required String bedId,
    required String name,
    required String nameAr,
  }) async {
    await _firestore.collection('beds').doc(bedId).update({
      'name': name,
      'nameAr': nameAr,
    });
  }

  Future<void> updateBedStatus({
    required String bedId,
    required String status,
    String? patientName,
    String? patientId,
    String? bookingId,
  }) async {
    final data = <String, dynamic>{
      'status': status,
    };
    if (patientName != null) data['patientName'] = patientName;
    if (patientId != null) data['patientId'] = patientId;
    if (bookingId != null) data['bookingId'] = bookingId;
    await _firestore.collection('beds').doc(bedId).update(data);
  }

  Future<void> deleteBed(String bedId) async {
    await _firestore.collection('beds').doc(bedId).delete();
  }
}
