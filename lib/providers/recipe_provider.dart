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

  // ---- Authentication & Mode state -----------------------------------
  bool _authLoading = true;
  String? _authError;
  String? _uid;
  bool _isAdminMode = false;

  bool get authLoading => _authLoading;
  String? get authError => _authError;
  String? get uid => _uid;
  bool get isAdminMode => _isAdminMode;

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

  List<Recipe> get allRecipes => _allRecipes;
  List<FoodCategory> get categories => _categories;
  Set<String> get favoriteIds => _favoriteIds;

  List<String> get categoryNames => [
        'All',
        ..._categories.map((c) => c.name).where((n) => n.isNotEmpty),
      ];

  /// Recipes after search + category filtering + favorite mapping are applied.
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
            recipe.category.toLowerCase().contains(q) ||
            recipe.ingredientName.any((ing) => ing.toLowerCase().contains(q)) ||
            recipe.ingredients.any((ing) => ing.name.toLowerCase().contains(q));
      } else {
        matchesSearch = recipe.name.contains(query) ||
            recipe.category.contains(query) ||
            recipe.ingredientName.any((ing) => ing.contains(query)) ||
            recipe.ingredients.any((ing) => ing.name.contains(query));
      }

      return matchesCategory && matchesSearch;
    }).map((recipe) {
      final isFav = _favoriteIds.contains(recipe.id);
      return recipe.isFavorite == isFav
          ? recipe
          : recipe.copyWith(isFavorite: isFav);
    }).toList();
  }

  /// Popular recipes ordered by viewCount desc.
  List<Recipe> get popularRecipes {
    final sorted = List<Recipe>.from(_allRecipes)
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted
        .map((r) => r.copyWith(isFavorite: _favoriteIds.contains(r.id)))
        .toList();
  }

  /// Top rated recipes ordered by rating and review count desc.
  List<Recipe> get topRatedRecipes {
    final sorted = List<Recipe>.from(_allRecipes)
      ..sort((a, b) {
        final ratingCmp = b.rating.compareTo(a.rating);
        if (ratingCmp != 0) return ratingCmp;
        return b.review.compareTo(a.review);
      });
    return sorted
        .map((r) => r.copyWith(isFavorite: _favoriteIds.contains(r.id)))
        .toList();
  }

  /// User's favorite recipes list.
  List<Recipe> get favoriteRecipes {
    return _allRecipes
        .where((r) => _favoriteIds.contains(r.id))
        .map((r) => r.copyWith(isFavorite: true))
        .toList();
  }

  Recipe recipeById(String id) =>
      _allRecipes.firstWhere((r) => r.id == id, orElse: () => Recipe.empty());

  int getQuantity(String recipeId) => _quantities[recipeId] ?? 1;

  int quantityFor(String recipeId, {int defaultQuantity = 1}) =>
      _quantities[recipeId] ?? defaultQuantity;

  void setQuantity(String recipeId, int qty) {
    if (qty < 1) return;
    _quantities[recipeId] = qty;
    notifyListeners();
  }

  void resetQuantity(String recipeId) {
    _quantities.remove(recipeId);
    notifyListeners();
  }

  void incrementQuantity(String recipeId, {int defaultQuantity = 1}) =>
      setQuantity(recipeId,
          quantityFor(recipeId, defaultQuantity: defaultQuantity) + 1);

  void decrementQuantity(String recipeId,
          {int defaultQuantity = 1}) =>
      setQuantity(
          recipeId,
          (quantityFor(recipeId, defaultQuantity: defaultQuantity) - 1)
              .clamp(1, 999));

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedCategory(String category) => selectCategory(category);

  void retry() => _subscribeToContentStreams();

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
  }

  void setAdminMode(bool enabled) {
    if (_isAdminMode == enabled) return;
    _isAdminMode = enabled;
    _subscribeToContentStreams();
  }

  // ---- Internal subscription initialization ---------------------------

  void _initAuthAndStreams() {
    _authSub = _auth.authStateChanges().listen((user) {
      _uid = user?.uid;
      _authLoading = false;
      _authError = null;

      _subscribeToFavorites(user?.uid);
      _subscribeToContentStreams();
      notifyListeners();
    }, onError: (e) {
      _authLoading = false;
      _authError = e.toString();
      notifyListeners();
    });
  }

  void _subscribeToFavorites(String? uid) {
    _favoritesSub?.cancel();
    _favoritesSub = null;

    if (uid == null) {
      _favoriteIds = {};
      notifyListeners();
      return;
    }

    _favoritesSub = _repository.watchFavoriteIds(uid).listen(
      (favs) {
        _favoriteIds = favs;
        notifyListeners();
      },
      onError: (_) {
        // Silently preserve local favorites state
      },
    );
  }

  void _subscribeToContentStreams() {
    _recipeSub?.cancel();
    _categorySub?.cancel();

    _recipeStatus = LoadStatus.loading;
    _categoryStatus = LoadStatus.loading;
    notifyListeners();

    final recipeStream = _isAdminMode
        ? _repository.watchAllRecipes()
        : _repository.watchPublishedRecipes();

    final categoryStream = _isAdminMode
        ? _repository.watchAllCategories()
        : _repository.watchActiveCategories();

    _recipeSub = recipeStream.listen(
      (recipes) {
        _allRecipes = recipes;
        _recipeStatus = LoadStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _recipeStatus = LoadStatus.error;
        _errorMessage = 'Failed to load recipes. Please try again.';
        notifyListeners();
      },
    );

    _categorySub = categoryStream.listen(
      (categories) {
        _categories = categories;
        _categoryStatus = LoadStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        _categoryStatus = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  // ---- User Actions: Favorites & Views ---------------------------------

  Future<void> toggleFavorite(dynamic recipeOrId) async {
    final String recipeId =
        recipeOrId is Recipe ? recipeOrId.id : recipeOrId.toString();
    final uid = _uid;
    if (uid == null) return;

    final wasFavorite = _favoriteIds.contains(recipeId);
    if (wasFavorite) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(uid, recipeId);
      } else {
        await _repository.addFavorite(uid, recipeId);
      }
    } catch (_) {
      // Revert optimistic update
      if (wasFavorite) {
        _favoriteIds.add(recipeId);
      } else {
        _favoriteIds.remove(recipeId);
      }
      notifyListeners();
    }
  }

  Future<void> recordRecipeView(String recipeId) async {
    try {
      await _repository.incrementViewCount(recipeId);
    } catch (_) {}
  }

  Future<void> incrementRecipeViewCount(String recipeId) =>
      recordRecipeView(recipeId);

  // ---- Admin Operations -----------------------------------------------

  Future<bool> createRecipe(Recipe recipe, String uid) async {
    try {
      await _repository.createRecipe(recipe, uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecipe(Recipe recipe, String uid) async {
    try {
      await _repository.updateRecipe(recipe, uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePublishRecipe(String recipeId, bool isPublished) async {
    try {
      await _repository.togglePublishRecipe(recipeId, isPublished);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _repository.deleteRecipe(recipeId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCategory(FoodCategory category, String uid) async {
    try {
      await _repository.createCategory(category, uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(FoodCategory category) async {
    try {
      await _repository.updateCategory(category);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCategoryActive(String categoryId, bool isActive) async {
    try {
      await _repository.toggleCategoryActive(categoryId, isActive);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> isCategoryNameTaken(String name, {String? excludeId}) async {
    return await _repository.categoryNameExists(name, excludeId: excludeId);
  }

  Future<int> getRecipeCountForCategory(String categoryName) async {
    return await _repository.countRecipesInCategory(categoryName);
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
