import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bed_model.dart';

class BedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BedModel>> getBedsByDepartment(String departmentId) {
    return _firestore
        .collection('beds')
        .where('departmentId', isEqualTo: departmentId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BedModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Stream<List<BedModel>> getAvailableBedsByHospital(String hospitalId) {
    return _firestore
        .collection('beds')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BedModel.fromMap(doc.data(), doc.id))
              .where((bed) => bed.status == 'available')
              .toList();
        });
  }

  Future<void> _adjustHospitalAvailableBeds(
    String hospitalId,
    int delta,
  ) async {
    if (hospitalId.isEmpty) return;
    try {
      await _firestore.collection('hospitals').doc(hospitalId).update({
        'availableBeds': FieldValue.increment(delta),
      });
    } catch (_) {}
  }

  Future<void> addBed(BedModel bed) async {
    await _firestore.collection('beds').add(bed.toMap());
    if (bed.status == 'available') {
      await _adjustHospitalAvailableBeds(bed.hospitalId, 1);
    }
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
    final oldDoc = await _firestore.collection('beds').doc(bedId).get();
    final oldStatus = oldDoc.exists
        ? (oldDoc.data()?['status'] ?? 'available')
        : 'available';
    final hospitalId = oldDoc.exists
        ? (oldDoc.data()?['hospitalId'] ?? '') as String
        : '';

    final data = <String, dynamic>{'status': status};
    if (patientName != null) data['patientName'] = patientName;
    if (patientId != null) data['patientId'] = patientId;
    if (bookingId != null) data['bookingId'] = bookingId;
    await _firestore.collection('beds').doc(bedId).update(data);

    if (hospitalId.isNotEmpty && oldStatus != status) {
      if (oldStatus == 'available') {
        await _adjustHospitalAvailableBeds(hospitalId, -1);
      } else if (status == 'available') {
        await _adjustHospitalAvailableBeds(hospitalId, 1);
      }
    }
  }

  Future<void> deleteBed(String bedId) async {
    final doc = await _firestore.collection('beds').doc(bedId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['status'] == 'available') {
        await _adjustHospitalAvailableBeds(data['hospitalId'] ?? '', -1);
      }
    }
    await _firestore.collection('beds').doc(bedId).delete();
  }
}
