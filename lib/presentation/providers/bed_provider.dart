import 'package:flutter/material.dart';
import '../../data/models/bed_model.dart';
import '../../data/services/bed_service.dart';

class BedProvider extends ChangeNotifier {
  final BedService _bedService = BedService();

  List<BedModel> _beds = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BedModel> get beds => _beds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadBedsByDepartment(String departmentId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _bedService.getBedsByDepartment(departmentId).listen((beds) {
      _beds = beds;
      _isLoading = false;
      notifyListeners();
    }).onError((error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addBed({
    required String departmentId,
    required String hospitalId,
    required String name,
    required String nameAr,
  }) async {
    try {
      final bed = BedModel(
        departmentId: departmentId,
        hospitalId: hospitalId,
        name: name,
        nameAr: nameAr,
      );
      await _bedService.addBed(bed);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateBedName({
    required String bedId,
    required String name,
    required String nameAr,
  }) async {
    try {
      await _bedService.updateBed(bedId: bedId, name: name, nameAr: nameAr);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> updateBedStatus({
    required String bedId,
    required String status,
    String? patientName,
    String? patientId,
    String? bookingId,
  }) async {
    await _bedService.updateBedStatus(
      bedId: bedId,
      status: status,
      patientName: patientName,
      patientId: patientId,
      bookingId: bookingId,
    );
  }

  Future<bool> deleteBed(String bedId) async {
    try {
      await _bedService.deleteBed(bedId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void loadAvailableBeds(String hospitalId) {
    _errorMessage = null;
    _bedService.getAvailableBedsByHospital(hospitalId).listen((beds) {
      _beds = beds;
      _isLoading = false;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
