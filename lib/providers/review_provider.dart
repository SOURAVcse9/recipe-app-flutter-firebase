import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';

enum ReviewStatus { initial, loading, loaded, success, error }

class ReviewProvider extends ChangeNotifier {
  final ReviewRepository _repository;
  final FirebaseAuth _auth;

  ReviewProvider({
    ReviewRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? ReviewRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  ReviewStatus _status = ReviewStatus.initial;
  ReviewStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  StreamSubscription<List<Review>>? _reviewsSub;

  void watchReviews(String recipeId) {
    _reviewsSub?.cancel();
    _status = ReviewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _reviewsSub = _repository.watchReviews(recipeId).listen(
      (list) {
        _reviews = list;
        _status = ReviewStatus.loaded;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _status = ReviewStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> submitReview({
    required String recipeId,
    required double rating,
    required String reviewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'Must be signed in to review recipes.';
      _status = ReviewStatus.error;
      notifyListeners();
      return;
    }

    _status = ReviewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final name = user.displayName ?? 'Anonymous User';
      await _repository.submitReview(
        recipeId: recipeId,
        userId: user.uid,
        userName: name.isNotEmpty ? name : 'Anonymous User',
        rating: rating,
        reviewText: reviewText,
      );
      _status = ReviewStatus.success;
      notifyListeners();
    } catch (err) {
      _errorMessage = err.toString();
      _status = ReviewStatus.error;
      notifyListeners();
    }
  }

  Future<void> deleteReview(String recipeId, String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _repository.deleteReview(recipeId, reviewId, user.uid);
    } catch (err) {
      _errorMessage = err.toString();
      _status = ReviewStatus.error;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _userReviews = [];
  List<Map<String, dynamic>> get userReviews => _userReviews;

  StreamSubscription<List<Map<String, dynamic>>>? _userReviewsSub;

  void watchUserReviews(String uid) {
    _userReviewsSub?.cancel();
    _status = ReviewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _userReviewsSub = _repository.watchUserReviews(uid).listen(
      (list) {
        _userReviews = list;
        _status = ReviewStatus.loaded;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _status = ReviewStatus.error;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    _userReviewsSub?.cancel();
    super.dispose();
  }
}
