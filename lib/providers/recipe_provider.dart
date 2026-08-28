import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_preferences.dart';
import '../models/food_category.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

enum LoadStatus { initial, loading, loaded, error }

/// Single source of truth for recipe/category state, filtering, search,
/// user-specific favorites, and serving quantity.
class RecipeProvider extends ChangeNotifier {
  RecipeProvider({
    RecipeRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? RecipeRepository(),
        _auth = auth ?? FirebaseAuth.instance {
    _initAuthAndStreams();
  }

  final RecipeRepository _repository;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Recipe>>? _recipeSub;
  StreamSubscription<List<FoodCategory>>? _categorySub;
  StreamSubscription<Set<String>>? _favoritesSub;

  // ---- Authentication state -----------------------------------------
  bool _authLoading = true;
  String? _authError;
  String? _uid;

  bool get authLoading => _authLoading;
  String? get authError => _authError;
  String? get uid => _uid;

  // ---- Raw data -----------------------------------------------------
  List<Recipe> _allRecipes = [];
  List<FoodCategory> _categories = [];
  Set<String> _favoriteIds = {};

  // ---- UI-facing state ------------------------------------------------
  LoadStatus _recipeStatus = LoadStatus.initial;
  LoadStatus _categoryStatus = LoadStatus.initial;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  /// Serving-quantity per recipe id. Defaults to 1 when absent.
  final Map<String, int> _quantities = {};

  // ---- Getters ----------------------------------------------------------
  LoadStatus get recipeStatus => _recipeStatus;
  LoadStatus get categoryStatus => _categoryStatus;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categoryNames => [
        'All',
        ..._categories.map((c) => c.name).where((n) => n.isNotEmpty),
      ];

  /// Recipes after search + category filtering + favorite mapping are applied,
  /// matching case-sensitivity from [AppPreferences].
  List<Recipe> filteredRecipes(AppPreferences prefs) {
    final query = _searchQuery.trim();
    final isCaseInsensitive = prefs.caseInsensitiveSearch;

    return _allRecipes.where((recipe) {
      final matchesCategory = _selectedCategory == 'All' ||
          recipe.category.toLowerCase() == _selectedCategory.toLowerCase();

      bool matchesSearch;
      if (query.isEmpty) {
        matchesSearch = true;
      } else if (isCaseInsensitive) {
        final q = query.toLowerCase();
        matchesSearch = recipe.name.toLowerCase().contains(q) ||
            recipe.category.toLowerCase().contains(q);
      } else {
        matchesSearch = recipe.name.contains(query) ||
            recipe.category.contains(query);
      }

      return matchesCategory && matchesSearch;
    }).map((recipe) {
      final isFav = _favoriteIds.contains(recipe.id);
      return recipe.isFavorite == isFav
          ? recipe
          : recipe.copyWith(isFavorite: isFav);
    }).toList();
  }

  List<Recipe> get favoriteRecipes {
    return _allRecipes
        .where((r) => _favoriteIds.contains(r.id))
        .map((r) => r.isFavorite ? r : r.copyWith(isFavorite: true))
        .toList();
  }

  int quantityFor(String recipeId, {int defaultQuantity = 1}) =>
      _quantities[recipeId] ?? defaultQuantity;

  /// Looks up a single recipe by id from the full (unfiltered) live set.
  Recipe? recipeById(String id) {
    for (final r in _allRecipes) {
      if (r.id == id) {
        final isFav = _favoriteIds.contains(r.id);
        return r.isFavorite == isFav ? r : r.copyWith(isFavorite: isFav);
      }
    }
    return null;
  }

  // ---- Authentication and Streams Setup -------------------------------
  void _initAuthAndStreams() {
    _authSub = _auth.userChanges().listen((user) {
      if (user != null) {
        _uid = user.uid;
        _authLoading = false;
        _authError = null;
        notifyListeners();
        _subscribeToStreams();
      } else {
        _signInAnonymously();
      }
    }, onError: (Object error) {
      _authLoading = false;
      _authError = 'Authentication failed. Please check your connection.';
      notifyListeners();
    });
  }

  Future<void> _signInAnonymously() async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final credentials = await _auth.signInAnonymously();
      _uid = credentials.user?.uid;
      _authLoading = false;
      notifyListeners();
      _subscribeToStreams();
    } catch (e) {
      _authLoading = false;
      _authError = 'Failed to connect to backend anonymously. Retrying...';
      notifyListeners();
    }
  }

  /// Triggered manually via the Retry button in the UI if auth fails.
  void retryAuthentication() {
    _signInAnonymously();
  }

  void _subscribeToStreams() {
    final currentUid = _uid;
    if (currentUid == null) return;

    _recipeSub?.cancel();
    _categorySub?.cancel();
    _favoritesSub?.cancel();

    _recipeStatus = LoadStatus.loading;
    _recipeSub = _repository.watchRecipes().listen(
      (recipes) {
        _allRecipes = recipes;
        _recipeStatus = LoadStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace _) {
        _recipeStatus = LoadStatus.error;
        _errorMessage = _friendlyError(error);
        notifyListeners();
      },
    );

    _categoryStatus = LoadStatus.loading;
    _categorySub = _repository.watchCategories().listen(
      (categories) {
        _categories = categories;
        _categoryStatus = LoadStatus.loaded;
        notifyListeners();
      },
      onError: (Object error, StackTrace _) {
        _categoryStatus = LoadStatus.error;
        notifyListeners();
      },
    );

    _favoritesSub = _repository.watchFavoriteIds(currentUid).listen(
      (favIds) {
        _favoriteIds = favIds;
        notifyListeners();
      },
      onError: (Object _) {
        // Fail silently for favorites, keep loading recipe stream
      },
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission')) {
      return "You don't have permission to view this content right now.";
    }
    if (text.contains('network') || text.contains('unavailable')) {
      return 'No internet connection. Showing the latest data we have.';
    }
    return 'Something went wrong loading recipes. Please try again.';
  }

  /// Retries subscribing to the main content streams.
  void retry() {
    _subscribeToStreams();
  }

  // ---- Search / filter actions ---------------------------------------
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ---- Favorites ------------------------------------------------------
  Future<void> toggleFavorite(Recipe recipe) async {
    final currentUid = _uid;
    if (currentUid == null) return;

    final recipeId = recipe.id;
    final wasFavorite = _favoriteIds.contains(recipeId);

    // Optimistic UI update
    if (wasFavorite) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(currentUid, recipeId);
      } else {
        await _repository.addFavorite(currentUid, recipeId);
      }
    } catch (_) {
      // Revert optimistic update on write failure
      if (wasFavorite) {
        _favoriteIds.add(recipeId);
      } else {
        _favoriteIds.remove(recipeId);
      }
      notifyListeners();
    }
  }

  // ---- Quantity / serving scaling --------------------------------------
  void incrementQuantity(String recipeId, {int defaultQuantity = 1}) {
    final current = quantityFor(recipeId, defaultQuantity: defaultQuantity);
    _quantities[recipeId] = current + 1;
    notifyListeners();
  }

  void decrementQuantity(String recipeId, {int defaultQuantity = 1, int minimum = 1}) {
    final current = quantityFor(recipeId, defaultQuantity: defaultQuantity);
    if (current <= minimum) return;
    _quantities[recipeId] = current - 1;
    notifyListeners();
  }

  void resetQuantity(String recipeId) {
    _quantities[recipeId] = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _recipeSub?.cancel();
    _categorySub?.cancel();
    _favoritesSub?.cancel();
    super.dispose();
  }
}
