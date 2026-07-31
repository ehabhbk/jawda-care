import 'package:flutter/material.dart';
import '../../data/models/department_model.dart';
import '../../data/services/department_service.dart';

class DepartmentProvider extends ChangeNotifier {
  final DepartmentService _departmentService = DepartmentService();

  List<DepartmentModel> _departments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DepartmentModel> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadDepartments(String hospitalId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _departmentService.getDepartments(hospitalId).listen((departments) {
      _departments = departments;
      _isLoading = false;
      notifyListeners();
    }).onError((error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addDepartment({
    required String hospitalId,
    required String name,
    required String nameAr,
  }) async {
    try {
      final department = DepartmentModel(
        hospitalId: hospitalId,
        name: name,
        nameAr: nameAr,
      );
      await _departmentService.addDepartment(department);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateDepartment({
    required String departmentId,
    required String name,
    required String nameAr,
  }) async {
    try {
      await _departmentService.updateDepartment(
        departmentId: departmentId,
        name: name,
        nameAr: nameAr,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteDepartment(String departmentId) async {
    try {
      await _departmentService.deleteDepartment(departmentId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteDepartmentWithBeds(String departmentId) async {
    try {
      await _departmentService.deleteDepartmentWithBeds(departmentId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
