import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    return _firestore.collection(collection).doc(docId).get();
  }

  Future<QuerySnapshot> getDocuments({
    required String collection,
    String? field,
    dynamic value,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore.collection(collection);

    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.get();
  }

  Stream<QuerySnapshot> streamDocuments({
    required String collection,
    String? field,
    dynamic value,
    String? orderBy,
    bool descending = false,
  }) {
    Query query = _firestore.collection(collection);

    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots();
  }

  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final doc = await _firestore.collection(collection).add(data);
    return doc.id;
  }

  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<void> runTransaction(TransactionHandler handler) async {
    await _firestore.runTransaction(handler);
  }
}
