import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class MedicalReportService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadReport({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final ref = _storage.ref('medical_reports/$fileName');
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }
}
