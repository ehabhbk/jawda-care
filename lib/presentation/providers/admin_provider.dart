import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/hospital_model.dart';
import '../../data/models/ambulance_model.dart';
import '../../data/services/auth_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<QuerySnapshot> get hospitalsStream => _firestore
      .collection('hospitals')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<QuerySnapshot> get ambulancesStream => _firestore
      .collection('ambulances')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        email,
      );
      return methods.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addHospital({
    required String name,
    required String nameAr,
    required String address,
    required String addressAr,
    required String city,
    required String cityAr,
    required double latitude,
    required double longitude,
    required String phone,
    required String email,
    required String password,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final exists = await checkEmailExists(email);
      if (exists) {
        _errorMessage = 'البريد الإلكتروني مستخدم بالفعل في حساب آخر';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final admin = FirebaseAuth.instance.currentUser;
      final adminUid = admin!.uid;

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(name);

      final hospitalId = credential.user!.uid;

      final hospital = HospitalModel(
        id: hospitalId,
        name: name,
        nameAr: nameAr,
        address: address,
        addressAr: addressAr,
        city: city,
        cityAr: cityAr,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        email: email,
        password: password,
        adminUid: adminUid,
        imageUrl: imageUrl,
      );

      await _firestore
          .collection('hospitals')
          .doc(hospitalId)
          .set(hospital.toMap());

      await _firestore.collection('users').doc(hospitalId).set({
        'id': hospitalId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'hospital',
        'hospitalId': hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHospital({
    required String hospitalId,
    required String name,
    required String nameAr,
    required String address,
    required String addressAr,
    required String city,
    required String cityAr,
    required double latitude,
    required double longitude,
    required String phone,
    required bool isActive,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('hospitals').doc(hospitalId).update({
        'name': name,
        'nameAr': nameAr,
        'address': address,
        'addressAr': addressAr,
        'city': city,
        'cityAr': cityAr,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'isActive': isActive,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAmbulance({
    String hospitalId = '',
    required String plateNumber,
    required String driverName,
    required String driverPhone,
    required String driverEmail,
    required String driverPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final exists = await checkEmailExists(driverEmail);
      if (exists) {
        _errorMessage = 'البريد الإلكتروني مستخدم بالفعل في حساب آخر';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final ambulanceData = AmbulanceModel(
        hospitalId: hospitalId,
        plateNumber: plateNumber,
        driverName: driverName,
        driverPhone: driverPhone,
        driverEmail: driverEmail,
        driverPassword: driverPassword,
      );

      final ref = await _firestore
          .collection('ambulances')
          .add(ambulanceData.toMap());
      final ambulanceId = ref.id;

      await _authService.signUp(
        name: driverName,
        email: driverEmail,
        password: driverPassword,
        phone: driverPhone,
        role: 'driver',
        hospitalId: hospitalId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAmbulance({
    required String ambulanceId,
    String hospitalId = '',
    required String plateNumber,
    required String driverName,
    required String driverPhone,
    required String status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('ambulances').doc(ambulanceId).update({
        'hospitalId': hospitalId,
        'plateNumber': plateNumber,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'status': status,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final exists = await checkEmailExists(email);
      if (exists) {
        _errorMessage = 'البريد الإلكتروني مستخدم بالفعل في حساب آخر';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(name);

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleHospitalActive(String hospitalId, bool isActive) async {
    await _firestore.collection('hospitals').doc(hospitalId).update({
      'isActive': isActive,
    });
  }

  Future<bool> deleteHospital(String hospitalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('hospitals').doc(hospitalId));
      batch.delete(_firestore.collection('users').doc(hospitalId));

      final ambulances = await _firestore
          .collection('ambulances')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();
      for (final a in ambulances.docs) {
        batch.delete(a.reference);
      }

      final departments = await _firestore
          .collection('departments')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();
      for (final d in departments.docs) {
        batch.delete(d.reference);
      }

      final beds = await _firestore
          .collection('beds')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();
      for (final b in beds.docs) {
        batch.delete(b.reference);
      }

      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAmbulance(String ambulanceId) async {
    await _firestore.collection('ambulances').doc(ambulanceId).delete();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
