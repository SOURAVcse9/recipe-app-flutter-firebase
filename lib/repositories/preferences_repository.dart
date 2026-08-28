import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_preferences.dart';

/// Deals with reading/writing user preference documents on Cloud Firestore
/// under users/{uid}/preferences/settings.
class PreferencesRepository {
  PreferencesRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('settings');

  /// Streams preferences for the given user, returning default values if
  /// the document is absent.
  Stream<AppPreferences> watchPreferences(String uid) {
    return _settingsDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return const AppPreferences();
      }
      return AppPreferences.fromMap(snapshot.data()!);
    });
  }

  /// Saves the updated preferences document in Firestore.
  Future<void> updatePreferences(String uid, AppPreferences preferences) async {
    await _settingsDoc(uid).set(preferences.toMap(), SetOptions(merge: true));
  }
}
