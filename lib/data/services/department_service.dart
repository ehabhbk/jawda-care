import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/department_model.dart';

class DepartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DepartmentModel>> getDepartments(String hospitalId) {
    return _firestore
        .collection('departments')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => DepartmentModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addDepartment(DepartmentModel department) async {
    await _firestore.collection('departments').add(department.toMap());
  }

  Future<void> updateDepartment({
    required String departmentId,
    required String name,
    required String nameAr,
  }) async {
    await _firestore.collection('departments').doc(departmentId).update({
      'name': name,
      'nameAr': nameAr,
    });
  }

  Future<void> deleteDepartment(String departmentId) async {
    await _firestore.collection('departments').doc(departmentId).delete();
  }

  Future<void> deleteDepartmentWithBeds(String departmentId) async {
    final beds = await _firestore
        .collection('beds')
        .where('departmentId', isEqualTo: departmentId)
        .get();
    final batch = _firestore.batch();
    for (final bed in beds.docs) {
      batch.delete(bed.reference);
    }
    batch.delete(_firestore.collection('departments').doc(departmentId));
    await batch.commit();
  }
}
