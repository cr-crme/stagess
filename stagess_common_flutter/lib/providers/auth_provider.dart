import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/models/generic/access_level.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    bool mockMe = false,
    bool automaticallySignInIfMocked = true,
    this.requiredAdminAccess = false,
  }) : _mockMe = mockMe {
    if (_mockMe) {
      _mockMe = true;
      _mockFirebaseAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'Mock User'),
      );
      if (automaticallySignInIfMocked) {
        signInWithEmailAndPassword(
          email: 'email@email.com',
          password: '123123123',
        );
        teacherId = 'mockTeacherId';
      }
    }
  }

  final bool requiredAdminAccess;
  bool _mockMe;
  bool get mockMe => _mockMe;
  FirebaseAuth get _firebaseAuth =>
      mockMe ? _mockFirebaseAuth! : FirebaseAuth.instance;
  MockFirebaseAuth? _mockFirebaseAuth;

  User? get currentUser =>
      isAuthenticatorSignedIn ? _firebaseAuth.currentUser : null;

  static AuthProvider of(BuildContext context, {bool listen = false}) =>
      Provider.of<AuthProvider>(context, listen: listen);

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    notifyListeners();
    return user;
  }

  Future<void> updatePassword(String newPassword) async {
    await _firebaseAuth.currentUser!.updatePassword(newPassword);
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    teacherId = null;
    schoolId = null;
    schoolBoardId = null;
    databaseAccessLevel = null;
    notifyListeners();
  }

  Future<String?> getAuthenticatorIdToken() async {
    if (!isAuthenticatorSignedIn) return null;
    return await _firebaseAuth.currentUser!.getIdToken();
  }

  bool get isAuthenticatorSignedIn {
    return _firebaseAuth.currentUser != null;
  }

  String? _teacherId;
  String? get teacherId => _teacherId;
  set teacherId(String? id) {
    _teacherId = id;
    notifyListeners();
  }

  String? _schoolId;
  String? get schoolId => _schoolId;
  set schoolId(String? id) {
    _schoolId = id;
    notifyListeners();
  }

  String? _schoolBoardId;
  String? get schoolBoardId => _schoolBoardId;
  set schoolBoardId(String? id) {
    _schoolBoardId = id;
    notifyListeners();
  }

  AccessLevel? _databaseAccessLevel;
  AccessLevel get databaseAccessLevel =>
      _databaseAccessLevel ?? AccessLevel.invalid;
  set databaseAccessLevel(AccessLevel? level) {
    _databaseAccessLevel = level;

    if (level != null && requiredAdminAccess && level < AccessLevel.admin) {
      signOut();
      throw Exception(
        'You must have admin access to perform this action. Current access level: $level',
      );
    }

    notifyListeners();
  }

  bool get isBackendConnected {
    return (teacherId != null && teacherId!.isNotEmpty) ||
        _databaseAccessLevel == AccessLevel.superAdmin;
  }

  bool get isFullySignedIn => isAuthenticatorSignedIn && isBackendConnected;
}
