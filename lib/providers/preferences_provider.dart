import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_preferences.dart';
import '../repositories/preferences_repository.dart';

/// Single source of truth for the settings and customization state of the application.
class PreferencesProvider extends ChangeNotifier {
  PreferencesProvider({
    PreferencesRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? PreferencesRepository(),
        _auth = auth ?? FirebaseAuth.instance {
    _initAuthSub();
  }

  final PreferencesRepository _repository;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppPreferences>? _prefsSub;

  AppPreferences _current = const AppPreferences();
  AppPreferences get current => _current;

  String? _uid;

  void _initAuthSub() {
    _authSub = _auth.userChanges().listen((user) {
      if (user != null) {
        _uid = user.uid;
        _subscribeToPrefs(user.uid);
      } else {
        _uid = null;
        _prefsSub?.cancel();
        _current = const AppPreferences();
        notifyListeners();
      }
    });
  }

  void _subscribeToPrefs(String uid) {
    _prefsSub?.cancel();
    _prefsSub = _repository.watchPreferences(uid).listen((prefs) {
      _current = prefs;
      notifyListeners();
    });
  }

  Future<void> _update(AppPreferences updated) async {
    final uid = _uid;
    if (uid == null) return;

    // Optimistic UI updates
    _current = updated;
    notifyListeners();

    try {
      await _repository.updatePreferences(uid, updated);
    } catch (_) {
      // Stream updates from Firestore will auto-sync on error.
    }
  }

  Future<void> setThemeMode(String themeMode) =>
      _update(_current.copyWith(themeMode: themeMode));

  Future<void> setRecipeRecommendations(bool value) =>
      _update(_current.copyWith(recipeRecommendations: value));

  Future<void> setNewRecipes(bool value) =>
      _update(_current.copyWith(newRecipes: value));

  Future<void> setCookingReminders(bool value) =>
      _update(_current.copyWith(cookingReminders: value));

  Future<void> setDefaultServingQuantity(int value) =>
      _update(_current.copyWith(defaultServingQuantity: value));

  Future<void> setShowCalories(bool value) =>
      _update(_current.copyWith(showCalories: value));

  Future<void> setShowCookingTime(bool value) =>
      _update(_current.copyWith(showCookingTime: value));

  Future<void> setCaseInsensitiveSearch(bool value) =>
      _update(_current.copyWith(caseInsensitiveSearch: value));

  @override
  void dispose() {
    _authSub?.cancel();
    _prefsSub?.cancel();
    super.dispose();
  }
}
