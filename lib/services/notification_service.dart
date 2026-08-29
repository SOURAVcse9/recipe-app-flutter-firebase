import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/preferences_provider.dart';
import '../screens/recipe_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notifications in isolate context.
  if (kDebugMode) {
    print('FCM Background message received: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static bool isTest = false;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  bool _initialized = false;

  /// Check if push notifications are supported on the active platform.
  bool get isSupported {
    if (isTest) return false;
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.windows;
  }

  /// Setup global message handlers.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isSupported) {
      _initialized = true;
      return;
    }

    try {
      // Set background handler.
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Listen to foreground messages.
      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // Listen to taps when app is in background.
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message.data);
      });

      // Check if app was opened from terminated state.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage.data);
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('FCM Initialization error: $e');
      }
    }
  }

  /// Request permissions dynamically. Returns null if not supported.
  Future<NotificationSettings?> requestPermission() async {
    if (!isSupported) return null;

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // If permission was granted, re-sync current token automatically.
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await syncToken(user.uid);
      }
    }

    return settings;
  }

  /// Check active system-level authorization status.
  Future<AuthorizationStatus> getAuthorizationStatus() async {
    if (!isSupported) {
      return AuthorizationStatus.denied;
    }
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Synchronize client device registration token with Firestore.
  Future<void> syncToken(String uid) async {
    if (!isSupported) return;

    try {
      // Get current permission status.
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      // VAPID key is only needed for Web.
      final String? token = await _messaging.getToken(
        vapidKey: kIsWeb ? '425044932718-n8fr95f1s7tupn790g764ddv9furao6g.apps.googleusercontent.com' : null,
      );

      if (token == null) return;

      await _registerTokenInFirestore(uid, token);

      // Listen for token updates.
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        await _registerTokenInFirestore(uid, newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('FCM Token sync error: $e');
      }
    }
  }

  /// Helper to record token registration details under users/{uid}/notification_tokens.
  Future<void> _registerTokenInFirestore(String uid, String token) async {
    final deviceId = token.hashCode.toString(); // Deterministic token document ID.
    final tokenRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_tokens')
        .doc(deviceId);

    await tokenRef.set({
      'token': token,
      'platform': _platformName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'enabled': true,
    }, SetOptions(merge: true));
  }

  /// Delete registration token mappings from Firestore on logout.
  Future<void> clearToken(String uid) async {
    if (!isSupported) return;

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? '425044932718-n8fr95f1s7tupn790g764ddv9furao6g.apps.googleusercontent.com' : null,
      );

      if (token != null) {
        final deviceId = token.hashCode.toString();
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('notification_tokens')
            .doc(deviceId)
            .delete();
      }

      // Delete the messaging instance token.
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        print('FCM Token clear error: $e');
      }
    }
  }

  /// Route user clicks.
  void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'];
    final recipeId = data['recipeId'];

    if (type == 'recipe' && recipeId != null && recipeId.toString().isNotEmpty) {
      final context = RecipeApp.navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipeId.toString()),
          ),
        );
      }
    }
  }

  /// Trigger foreground UI notifications if category preference is enabled.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    if (notification == null) return;

    final context = RecipeApp.navigatorKey.currentContext;
    if (context == null) return;

    final type = data['notificationType'];
    final prefs = Provider.of<PreferencesProvider>(context, listen: false).current;

    bool enabled = true;
    if (type == 'new_recipe' && !prefs.newRecipes) enabled = false;
    if (type == 'recommendation' && !prefs.recipeRecommendations) enabled = false;
    if (type == 'reminder' && !prefs.cookingReminders) enabled = false;

    if (!enabled) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(notification.body ?? '', style: const TextStyle(fontSize: 12.5)),
          ],
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _handleNotificationClick(data);
          },
        ),
      ),
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}
