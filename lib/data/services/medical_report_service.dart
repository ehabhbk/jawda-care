import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class MedicalReportService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadReport({
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref('medical_reports/$fileName');
    final task = ref.putFile(file);
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }
}
