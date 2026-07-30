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

  Stream<QuerySnapshot> get hospitalsStream =>
      _firestore.collection('hospitals').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot> get ambulancesStream =>
      _firestore.collection('ambulances').orderBy('createdAt', descending: true).snapshots();

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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
        adminUid: FirebaseAuth.instance.currentUser!.uid,
      );

      await _firestore.collection('hospitals').doc(hospitalId).set(hospital.toMap());

      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: 'hospital',
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

  Future<bool> addAmbulance({
    required String hospitalId,
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
      final ambulanceData = AmbulanceModel(
        hospitalId: hospitalId,
        plateNumber: plateNumber,
        driverName: driverName,
        driverPhone: driverPhone,
        driverEmail: driverEmail,
        driverPassword: driverPassword,
      );

      await _firestore.collection('ambulances').add(ambulanceData.toMap());

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

  Future<void> deleteHospital(String hospitalId) async {
    await _firestore.collection('hospitals').doc(hospitalId).update({'isActive': false});
  }

  Future<void> deleteAmbulance(String ambulanceId) async {
    await _firestore.collection('ambulances').doc(ambulanceId).delete();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
