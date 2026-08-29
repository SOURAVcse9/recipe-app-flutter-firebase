import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class AuthExceptionMapper {
  static String toMessage(dynamic exception) {
    if (exception is FirebaseAuthException) {
      switch (exception.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password is too weak. Must be at least 6 characters.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Please check your internet connection and try again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email address but different sign-in credentials. Please login using your original provider.';
        case 'credential-already-in-use':
          return 'This credential is already associated with a different user.';
        case 'operation-not-allowed':
          return 'This sign-in operation is not enabled.';
        case 'sign_in_canceled':
          return 'Google sign-in was canceled.';
        default:
          return exception.message ?? 'An unexpected authentication error occurred.';
      }
    }
    return exception.toString();
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _initAuthListener();
  }

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  StreamSubscription<User?>? _authSub;

  void _initAuthListener() {
    _authSub = _repository.authStateChanges.listen((user) async {
      _currentUser = user;
      _error = null;
      if (user != null) {
        try {
          await _repository.ensureUserProfile(user);
          _userProfile = await _repository.fetchUserProfile(user.uid);
        } catch (_) {
          // Graceful fallback
        }
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  void setError(String? err) {
    _error = err;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.signIn(email, password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.signUp(name: name, email: email, password: password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.signInWithGoogle();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'sign_in_canceled') {
        _error = null;
      } else {
        _error = AuthExceptionMapper.toMessage(e);
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.sendPasswordReset(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendVerificationEmail() async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.sendEmailVerification();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkEmailVerification() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.reloadUser();
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _userProfile = await _repository.fetchUserProfile(_currentUser!.uid);
      }
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.reauthenticate(currentPassword);
      await _repository.updatePassword(newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _currentUser;
      if (user != null) {
        await _repository.updateUserProfileName(user.uid, newName);
        _userProfile = await _repository.fetchUserProfile(user.uid);
      }
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthExceptionMapper.toMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _error = null;
    await _repository.signOut();
  }

  Future<void> refreshProfile() async {
    final user = _currentUser;
    if (user != null) {
      try {
        _userProfile = await _repository.fetchUserProfile(user.uid);
        notifyListeners();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
