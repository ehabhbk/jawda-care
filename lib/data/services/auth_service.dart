import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'patient',
    String? hospitalId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);

    if (role == 'patient') {
      await credential.user!.sendEmailVerification();
    }

    final userModel = UserModel(
      id: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      hospitalId: hospitalId,
    );

    try {
      await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toMap());
    } catch (_) {}

    return userModel;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    var userData = await _getUserData(credential.user!.uid);
    if (userData == null) {
      userData = UserModel(
        id: credential.user!.uid,
        name: credential.user!.displayName ?? 'User',
        email: credential.user!.email!,
        phone: '',
      );
      await _firestore.collection('users').doc(credential.user!.uid).set(userData.toMap());
    }

    if (userData.role == 'patient' && !credential.user!.emailVerified) {
      await _auth.signOut();
      throw Exception('email-not-verified');
    }

    return userData;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser!.emailVerified;
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> _getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<UserModel?> getUserData(String uid) => _getUserData(uid);

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
