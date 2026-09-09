import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Review>> watchReviews(String recipeId) {
    return _firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> watchUserReviews(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> submitReview({
    required String recipeId,
    required String userId,
    required String userName,
    required double rating,
    required String reviewText,
  }) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final userReviewQuery = await recipeRef
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    final hasExisting = userReviewQuery.docs.isNotEmpty;
    final reviewRef = hasExisting
        ? userReviewQuery.docs.first.reference
        : recipeRef.collection('reviews').doc();

    await _firestore.runTransaction((transaction) async {
      final recipeSnap = await transaction.get(recipeRef);
      if (!recipeSnap.exists) throw Exception('Recipe not found');

      final recipeData = recipeSnap.data() ?? {};
      final double currentRating = _asDouble(recipeData['rating']);
      final int currentReviewCount = _asInt(recipeData['review']);

      double newRating;
      int newReviewCount;

      if (hasExisting) {
        final oldReviewData = userReviewQuery.docs.first.data();
        final double oldRating = _asDouble(oldReviewData['rating']);

        newReviewCount = currentReviewCount;
        newRating = currentReviewCount > 0
            ? ((currentRating * currentReviewCount) - oldRating + rating) /
                currentReviewCount
            : rating;
      } else {
        newReviewCount = currentReviewCount + 1;
        newRating =
            ((currentRating * currentReviewCount) + rating) / newReviewCount;
      }

      final dynamic oldCreatedAt =
          hasExisting ? userReviewQuery.docs.first.data()['createdAt'] : null;
      final dynamic timestampVal = oldCreatedAt ?? FieldValue.serverTimestamp();

      transaction.set(reviewRef, {
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'reviewText': reviewText,
        'createdAt': timestampVal,
        'updatedAt': FieldValue.serverTimestamp(),
        'verifiedPurchase': false,
      });

      final userReviewRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .doc(recipeId);

      transaction.set(userReviewRef, {
        'recipeId': recipeId,
        'reviewId': reviewRef.id,
        'rating': rating,
        'reviewText': reviewText,
        'createdAt': timestampVal,
      });

      transaction.update(recipeRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'review': newReviewCount,
      });
    });
  }

  Future<void> deleteReview(
      String recipeId, String reviewId, String userId) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final reviewRef = recipeRef.collection('reviews').doc(reviewId);

    await _firestore.runTransaction((transaction) async {
      final reviewSnap = await transaction.get(reviewRef);
      if (!reviewSnap.exists) return;

      final reviewData = reviewSnap.data() ?? {};
      if (reviewData['userId'] != userId) {
        throw Exception('Unauthorized deletion');
      }
      final double reviewRating = _asDouble(reviewData['rating']);

      final recipeSnap = await transaction.get(recipeRef);
      if (!recipeSnap.exists) return;

      final recipeData = recipeSnap.data() ?? {};
      final double currentRating = _asDouble(recipeData['rating']);
      final int currentReviewCount = _asInt(recipeData['review']);

      final newReviewCount = currentReviewCount - 1;
      final newRating = newReviewCount > 0
          ? ((currentRating * currentReviewCount) - reviewRating) /
              newReviewCount
          : 0.0;

      transaction.delete(reviewRef);

      final userReviewRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .doc(recipeId);
      transaction.delete(userReviewRef);

      transaction.update(recipeRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'review': newReviewCount >= 0 ? newReviewCount : 0,
      });
    });
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
