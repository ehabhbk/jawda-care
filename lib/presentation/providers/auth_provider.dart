import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/models/hospital_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/hospital_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/booking_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final HospitalService _hospitalService = HospitalService();

  UserModel? _userModel;
  HospitalModel? _hospitalAccount;
  bool _isLoading = false;
  String? _errorMessage;
  bool _justRegistered = false;
  bool _isReady = false;

  UserModel? get userModel => _userModel;
  HospitalModel? get hospitalAccount => _hospitalAccount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _userModel != null;
  bool get justRegistered => _justRegistered;
  bool get isReady => _isReady;
  bool get isEmailVerified => _authService.currentUser?.emailVerified ?? false;
  User? get firebaseUser => _authService.currentUser;
  bool get isAdmin => _userModel?.role == 'admin';
  bool get isHospital => _userModel?.role == 'hospital';
  bool get isDriver => _userModel?.role == 'driver';
  bool get isPatient => _userModel?.role == 'patient';

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        if (await _isSessionExpired()) {
          await signOut();
        } else {
          await loadUserData(user.uid);
        }
      } else {
        _userModel = null;
        _hospitalAccount = null;
      }
      _isReady = true;
      notifyListeners();
    });
  }

  Future<bool> _isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getInt('session_start');
    if (start == null) return false;
    return DateTime.now().millisecondsSinceEpoch - start > 3600000;
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_start', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userModel = await _authService.getUserData(uid);
      if (_userModel != null) {
        await NotificationService.saveTokenToFirestore(uid);
        if (_userModel!.role == 'hospital' && _userModel!.hospitalId != null) {
          _hospitalAccount = await _hospitalService.getHospitalById(_userModel!.hospitalId!);
        }
        BookingNotificationWatcher.instance.start(
          userId: uid,
          hospitalId: _userModel!.role == 'hospital' ? _userModel!.hospitalId : null,
        );
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
      await _saveSession();
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
      await _saveSession();
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

  Future<void> checkSession() async {
    if (_userModel != null && await _isSessionExpired()) {
      await signOut();
    }
  }

  Future<bool> checkEmailVerified() async {
    return _authService.isEmailVerified();
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> signOut() async {
    BookingNotificationWatcher.instance.stop();
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_start');
    _userModel = null;
    _hospitalAccount = null;
    _errorMessage = null;
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
