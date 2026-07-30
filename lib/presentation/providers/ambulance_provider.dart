import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/ambulance_model.dart';

class AmbulanceProvider extends ChangeNotifier {
  List<AmbulanceModel> _ambulances = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AmbulanceModel> get ambulances => _ambulances;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadAmbulancesByHospital(String hospitalId) {
    _isLoading = true;
    notifyListeners();

    FirebaseFirestore.instance
        .collection('ambulances')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .listen((snap) {
      _ambulances = snap.docs
          .map((doc) => AmbulanceModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }).onError((error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<AmbulanceModel?> getNearestAmbulance({
    required double userLat,
    required double userLng,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ambulances')
          .where('status', isEqualTo: 'available')
          .get();

      final all = snapshot.docs.map((doc) => AmbulanceModel.fromMap(doc.data(), doc.id)).toList();
      if (all.isEmpty) return null;

      double minDistance = double.infinity;
      AmbulanceModel? nearest;

      for (final ambulance in all) {
        final distance = _calculateDistance(
          userLat, userLng,
          ambulance.currentLat, ambulance.currentLng,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = ambulance;
        }
      }

      return nearest;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return radius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}
