import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/department_model.dart';

class DepartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DepartmentModel>> getDepartments(String hospitalId) {
    return _firestore
        .collection('departments')
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DepartmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addDepartment(DepartmentModel department) async {
    await _firestore.collection('departments').add(department.toMap());
  }

  Future<void> deleteDepartment(String departmentId) async {
    await _firestore.collection('departments').doc(departmentId).delete();
  }
}
