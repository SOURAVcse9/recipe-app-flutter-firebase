import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/food_category.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

enum LoadStatus { initial, loading, loaded, error }

/// Single source of truth for recipe/category state, filtering, search,
/// favorites, and per-recipe serving quantity.
///
/// Widgets read from this via `context.watch<RecipeProvider>()` /
/// `Consumer` / `Selector`, and never touch Firestore directly.
class RecipeProvider extends ChangeNotifier {
  RecipeProvider({RecipeRepository? repository})
      : _repository = repository ?? RecipeRepository() {
    _subscribeToRecipes();
    _subscribeToCategories();
  }

  final RecipeRepository _repository;

  StreamSubscription<List<Recipe>>? _recipeSub;
  StreamSubscription<List<FoodCategory>>? _categorySub;

  // ---- Raw data -----------------------------------------------------
  List<Recipe> _allRecipes = [];
  List<FoodCategory> _categories = [];

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

  /// Recipes after search + category filtering are both applied.
  List<Recipe> get filteredRecipes {
    final query = _searchQuery.trim().toLowerCase();

    return _allRecipes.where((recipe) {
      final matchesCategory = _selectedCategory == 'All' ||
          recipe.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch = query.isEmpty ||
          recipe.name.toLowerCase().contains(query) ||
          recipe.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Recipe> get favoriteRecipes =>
      _allRecipes.where((r) => r.isFavorite).toList();

  int quantityFor(String recipeId) => _quantities[recipeId] ?? 1;

  /// Looks up a single recipe by id from the full (unfiltered) live set.
  /// Used by the detail screen so it stays correct regardless of whatever
  /// search/category filter is currently active on Home.
  Recipe? recipeById(String id) {
    for (final r in _allRecipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ---- Subscriptions ------------------------------------------------
  void _subscribeToRecipes() {
    _recipeStatus = LoadStatus.loading;
    _recipeSub = _repository.getRecipeStream().listen(
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
  }

  void _subscribeToCategories() {
    _categoryStatus = LoadStatus.loading;
    _categorySub = _repository.getCategoryStream().listen(
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

  /// Retries subscribing to recipes — useful for a "Try again" button
  /// after an error state.
  void retry() {
    _recipeSub?.cancel();
    _categorySub?.cancel();
    _subscribeToRecipes();
    _subscribeToCategories();
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

  /// Optimistically flips the favorite flag locally, then writes through
  /// to Firestore. If the write fails, the local flag is reverted so the
  /// UI never shows a "favorited" state that isn't actually persisted.
  Future<void> toggleFavorite(Recipe recipe) async {
    final index = _allRecipes.indexWhere((r) => r.id == recipe.id);
    if (index == -1) return;

    final newValue = !recipe.isFavorite;
    _allRecipes[index] = recipe.copyWith(isFavorite: newValue);
    notifyListeners();

    try {
      await _repository.updateFavorite(recipe.id, newValue);
    } catch (_) {
      // Revert optimistic update on failure.
      _allRecipes[index] = recipe.copyWith(isFavorite: !newValue);
      notifyListeners();
    }
  }

  // ---- Quantity / serving scaling --------------------------------------
  void incrementQuantity(String recipeId) {
    final current = quantityFor(recipeId);
    _quantities[recipeId] = current + 1;
    notifyListeners();
  }

  void decrementQuantity(String recipeId, {int minimum = 1}) {
    final current = quantityFor(recipeId);
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
    _recipeSub?.cancel();
    _categorySub?.cancel();
    super.dispose();
  }
}
