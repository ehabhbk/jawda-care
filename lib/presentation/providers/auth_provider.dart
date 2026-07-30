import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/models/hospital_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/hospital_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final HospitalService _hospitalService = HospitalService();

  UserModel? _userModel;
  HospitalModel? _hospitalAccount;
  bool _isLoading = false;
  String? _errorMessage;
  bool _justRegistered = false;

  UserModel? get userModel => _userModel;
  HospitalModel? get hospitalAccount => _hospitalAccount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _userModel != null;
  bool get justRegistered => _justRegistered;
  bool get isEmailVerified => _authService.currentUser?.emailVerified ?? false;
  User? get firebaseUser => _authService.currentUser;
  bool get isAdmin => _userModel?.role == 'admin';
  bool get isHospital => _userModel?.role == 'hospital';
  bool get isDriver => _userModel?.role == 'driver';
  bool get isPatient => _userModel?.role == 'patient';

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await loadUserData(user.uid);
      } else {
        _userModel = null;
        _hospitalAccount = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userModel = await _authService.getUserData(uid);
      if (_userModel != null && _userModel!.role == 'hospital' && _userModel!.hospitalId != null) {
        _hospitalAccount = await _hospitalService.getHospitalById(_userModel!.hospitalId!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: 'patient',
      );
      _justRegistered = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userModel = await _authService.signIn(email: email, password: password);
      if (_userModel != null && _userModel!.role == 'hospital' && _userModel!.hospitalId != null) {
        _hospitalAccount = await _hospitalService.getHospitalById(_userModel!.hospitalId!);
      }
      _isLoading = false;
      notifyListeners();
      return 0;
    } catch (e) {
      if (e.toString().contains('email-not-verified')) {
        _isLoading = false;
        notifyListeners();
        return 1;
      }
      _errorMessage = _getFirebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return 2;
    }
  }

  Future<bool> checkEmailVerified() async {
    return _authService.isEmailVerified();
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _hospitalAccount = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_userModel?.id == null) return;
    await _authService.updateUserData(_userModel!.id!, data);
    await loadUserData(_userModel!.id!);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getFirebaseErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'الحساب غير موجود. يرجى إنشاء حساب جديد';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'invalid-credential':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        case 'too-many-requests':
          return 'محاولات كثيرة. حاول لاحقاً';
        case 'network-request-failed':
          return 'لا يوجد اتصال بالإنترنت';
        default:
          return error.message ?? 'حدث خطأ. حاول مرة أخرى';
      }
    }
    return error.toString();
  }
}
