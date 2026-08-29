import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

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
        // Ensure profile exists in Firestore and retrieve it
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
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Authentication failed.';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during login.';
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
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed.';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during sign up.';
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
