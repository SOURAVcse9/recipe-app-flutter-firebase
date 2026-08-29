import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recently_viewed.dart';
import '../repositories/recently_viewed_repository.dart';

enum RecentlyViewedStatus { loading, loaded, error }

class RecentlyViewedProvider extends ChangeNotifier {
  final RecentlyViewedRepository _repository;
  final FirebaseAuth _auth;

  RecentlyViewedProvider({
    RecentlyViewedRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? RecentlyViewedRepository(),
        _auth = auth ?? FirebaseAuth.instance {
    _initAuthSubscription();
  }

  RecentlyViewedStatus _status = RecentlyViewedStatus.loading;
  RecentlyViewedStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<RecentlyViewed> _recentlyViewed = [];
  List<RecentlyViewed> get recentlyViewed => _recentlyViewed;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<RecentlyViewed>>? _recentlyViewedSub;
  String? _uid;

  void _initAuthSubscription() {
    _authSub = _auth.userChanges().listen((user) {
      if (user?.uid != _uid) {
        _uid = user?.uid;
        if (_uid != null) {
          _subscribeToRecentlyViewed(_uid!);
        } else {
          _recentlyViewedSub?.cancel();
          _recentlyViewed = [];
          _status = RecentlyViewedStatus.loaded;
          notifyListeners();
        }
      }
    });
  }

  void _subscribeToRecentlyViewed(String uid) {
    _recentlyViewedSub?.cancel();
    _status = RecentlyViewedStatus.loading;
    notifyListeners();

    _recentlyViewedSub = _repository.watchRecentlyViewed(uid).listen(
      (list) {
        // limit to 20 items in query/provider
        _recentlyViewed = list.take(20).toList();
        _status = RecentlyViewedStatus.loaded;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _status = RecentlyViewedStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> addRecipeToRecentlyViewed(String recipeId) async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.addOrUpdateRecentlyViewed(uid, recipeId);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _recentlyViewedSub?.cancel();
    super.dispose();
  }
}
