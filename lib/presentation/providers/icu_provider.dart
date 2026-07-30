import 'package:flutter/material.dart';
import '../../data/models/icu_model.dart';
import '../../data/services/icu_service.dart';

class IcuProvider extends ChangeNotifier {
  final IcuService _icuService = IcuService();

  List<IcuModel> _icus = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<IcuModel> get icus => _icus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadIcus({String? hospitalId}) {
    _icuService.getAvailableIcus(hospitalId: hospitalId).listen((icus) {
      _icus = icus;
      _isLoading = false;
      notifyListeners();
    }).onError((error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<List<IcuModel>> searchIcus({
    String? hospitalName,
    String? city,
    double? maxPrice,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _icuService.searchIcus(
        hospitalName: hospitalName,
        city: city,
        maxPrice: maxPrice,
      );
      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<IcuModel?> getIcuById(String icuId) async {
    try {
      return await _icuService.getIcuById(icuId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }
}
