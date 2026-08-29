import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recently_viewed.dart';

class RecentlyViewedRepository {
  final FirebaseFirestore _firestore;

  RecentlyViewedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _recentlyViewedRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('recentlyViewed');

  Stream<List<RecentlyViewed>> watchRecentlyViewed(String uid) {
    return _recentlyViewedRef(uid)
        .orderBy('viewedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecentlyViewed.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addOrUpdateRecentlyViewed(String uid, String recipeId) async {
    final docRef = _recentlyViewedRef(uid).doc(recipeId);
    await docRef.set({
      'viewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
