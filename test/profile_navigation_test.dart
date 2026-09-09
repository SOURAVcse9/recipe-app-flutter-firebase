import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/app_preferences.dart';
import 'package:recipe_app/providers/preferences_provider.dart';
import 'package:recipe_app/repositories/preferences_repository.dart';
import 'package:recipe_app/screens/about_app_screen.dart';
import 'package:recipe_app/screens/app_preferences_screen.dart';
import 'package:recipe_app/screens/notifications_screen.dart';
import 'package:recipe_app/screens/profile_screen.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/repositories/auth_repository.dart';
import 'package:recipe_app/services/notification_service.dart';

class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeUser implements User {
  @override
  String get uid => 'test_uid_123';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeUserCredential implements UserCredential {
  @override
  User get user => FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseAuth implements FirebaseAuth {
  final _userChangesController = StreamController<User?>.broadcast();
  User? _currentUser;

  FakeFirebaseAuth({User? initialUser}) : _currentUser = initialUser {
    _userChangesController.onListen = () {
      _userChangesController.add(_currentUser);
    };
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> userChanges() => _userChangesController.stream;

  @override
  Stream<User?> authStateChanges() => _userChangesController.stream;

  @override
  Future<UserCredential> signInAnonymously() async {
    final cred = FakeUserCredential();
    _currentUser = cred.user;
    _userChangesController.add(_currentUser);
    return cred;
  }

  void emitUser(User? user) {
    _currentUser = user;
    _userChangesController.add(user);
  }

  void dispose() {
    _userChangesController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakePreferencesRepository extends PreferencesRepository {
  final _prefsController = StreamController<AppPreferences>.broadcast();
  AppPreferences _current = const AppPreferences();

  FakePreferencesRepository() : super(firestore: FakeFirebaseFirestore()) {
    _prefsController.onListen = () {
      _prefsController.add(_current);
    };
  }

  @override
  Stream<AppPreferences> watchPreferences(String uid) =>
      _prefsController.stream;

  @override
  Future<void> updatePreferences(String uid, AppPreferences preferences) async {
    _current = preferences;
    _prefsController.add(preferences);
  }

  void emitPreferences(AppPreferences preferences) {
    _current = preferences;
    _prefsController.add(preferences);
  }

  void dispose() {
    _prefsController.close();
  }
}

void main() {
  NotificationService.isTest = true;
  group('Profile Navigation & Firestore Preferences Tests', () {
    late FakeFirebaseAuth mockAuth;
    late FakePreferencesRepository mockRepo;
    late PreferencesProvider prefsProvider;
    late AuthProvider authProvider;

    setUp(() {
      mockAuth = FakeFirebaseAuth(initialUser: FakeUser());
      mockRepo = FakePreferencesRepository();
      prefsProvider = PreferencesProvider(repository: mockRepo, auth: mockAuth);
      authProvider = AuthProvider(
        repository:
            AuthRepository(auth: mockAuth, firestore: FakeFirebaseFirestore()),
      );

      mockRepo.emitPreferences(const AppPreferences(
        recipeRecommendations: true,
        newRecipes: false,
        cookingReminders: true,
        defaultServingQuantity: 3,
        showCalories: true,
        showCookingTime: false,
      ));
    });

    tearDown(() {
      mockAuth.dispose();
      mockRepo.dispose();
    });

    testWidgets('ProfileScreen renders option cards and navigates successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PreferencesProvider>.value(
                value: prefsProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      // Wait for auth & preferences streams to emit
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // Verify the list of choices render
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('App preferences'), findsOneWidget);
      expect(find.text('About this app'), findsOneWidget);

      // 1. Test Notifications Screen Navigation
      final notifFinder = find.text('Notifications');
      await tester.ensureVisible(notifFinder);
      await tester.tap(notifFinder);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // Verify toggle values are correctly read from PreferencesProvider
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.length, equals(3));
      expect(switches[0].value, isTrue); // Recommendations: true
      expect(switches[1].value, isFalse); // New Recipes: false
      expect(switches[2].value, isTrue); // Reminders: true

      // Toggle switch and verify repository callback is made
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(mockRepo._current.recipeRecommendations, isFalse);

      // Back navigation
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // 2. Test App Preferences Screen Navigation
      final appPrefsFinder = find.text('App preferences');
      await tester.ensureVisible(appPrefsFinder);
      await tester.tap(appPrefsFinder);
      await tester.pumpAndSettle();
      expect(find.byType(AppPreferencesScreen), findsOneWidget);

      // Verify dropdown and switches in Preferences
      expect(find.text('3'), findsOneWidget); // Default serving quantity value
      final prefSwitches =
          tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(prefSwitches.length, equals(3));
      expect(prefSwitches[0].value, isTrue); // Show calories: true
      expect(prefSwitches[1].value, isFalse); // Show time: false
      expect(prefSwitches[2].value, isTrue); // Case-insensitive: true

      // Back navigation
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // 3. Test About Screen Navigation
      final aboutFinder = find.text('About this app');
      await tester.ensureVisible(aboutFinder);
      await tester.tap(aboutFinder);
      await tester.pumpAndSettle();
      expect(find.byType(AboutAppScreen), findsOneWidget);

      // Verify features descriptions and stack info
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('• '), findsAtLeastNWidgets(6));

      // Back navigation
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
