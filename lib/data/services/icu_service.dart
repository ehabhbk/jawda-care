import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/icu_model.dart';

class IcuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<IcuModel>> getAvailableIcus({String? hospitalId}) {
    Query query = _firestore
        .collection('icus')
        .where('isAvailable', isEqualTo: true);

    if (hospitalId != null) {
      query = query.where('hospitalId', isEqualTo: hospitalId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IcuModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<List<IcuModel>> getAllIcus({String? hospitalId}) async {
    Query query = _firestore.collection('icus');

    if (hospitalId != null) {
      query = query.where('hospitalId', isEqualTo: hospitalId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => IcuModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<IcuModel?> getIcuById(String icuId) async {
    final doc = await _firestore.collection('icus').doc(icuId).get();
    if (doc.exists) {
      return IcuModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateIcuAvailability(String icuId, bool isAvailable) async {
    await _firestore.collection('icus').doc(icuId).update({
      'isAvailable': isAvailable,
    });
  }

  Future<List<IcuModel>> searchIcus({
    String? hospitalName,
    String? city,
    double? maxPrice,
  }) async {
    Query query = _firestore
        .collection('icus')
        .where('isAvailable', isEqualTo: true);

    final snapshot = await query.get();
    var icus = snapshot.docs
        .map(
          (doc) => IcuModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    if (city != null) {
      icus = icus
          .where((i) => i.hospitalName == city || i.hospitalNameAr == city)
          .toList();
    }

    if (hospitalName != null) {
      icus = icus
          .where(
            (i) =>
                i.hospitalName.toLowerCase().contains(
                  hospitalName.toLowerCase(),
                ) ||
                i.hospitalNameAr.contains(hospitalName),
          )
          .toList();
    }

    if (maxPrice != null) {
      icus = icus.where((i) => i.pricePerDay <= maxPrice).toList();
    }

    return icus;
  }
}
