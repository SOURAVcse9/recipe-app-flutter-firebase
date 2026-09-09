import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_category.dart';
import '../models/recipe.dart';

/// All direct Firebase access (Firestore only) for recipes and categories.
class RecipeRepository {
  RecipeRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String recipesCollection = 'recipes';
  static const String categoriesCollection = 'categories';

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection(recipesCollection);

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection(categoriesCollection);

  // ===========================================================================
  // AUDIENCE STREAMS (Filtered for Published & Active content)
  // ===========================================================================

  /// Real-time stream of published recipes for audience users.
  Stream<List<Recipe>> watchPublishedRecipes() {
    return _recipesRef.snapshots().map((snapshot) {
      final recipes = <Recipe>[];
      for (final doc in snapshot.docs) {
        try {
          final recipe = Recipe.fromFirestore(doc);
          if (recipe.isPublished) {
            recipes.add(recipe);
          }
        } catch (_) {
          continue;
        }
      }
      return recipes;
    });
  }

  /// Real-time stream of active categories for audience users.
  Stream<List<FoodCategory>> watchActiveCategories() {
    return _categoriesRef.orderBy('name').snapshots().map((snapshot) {
      final categories = <FoodCategory>[];
      for (final doc in snapshot.docs) {
        try {
          final category = FoodCategory.fromFirestore(doc);
          if (category.isActive) {
            categories.add(category);
          }
        } catch (_) {
          continue;
        }
      }
      return categories;
    });
  }

  // ===========================================================================
  // ADMIN STREAMS (All content including Drafts & Inactive)
  // ===========================================================================

  /// Real-time stream of ALL recipes (Drafts + Published) for admin management.
  Stream<List<Recipe>> watchAllRecipes() {
    return _recipesRef.snapshots().map((snapshot) {
      final recipes = <Recipe>[];
      for (final doc in snapshot.docs) {
        try {
          recipes.add(Recipe.fromFirestore(doc));
        } catch (_) {
          continue;
        }
      }
      return recipes;
    });
  }

  /// Real-time stream of ALL categories (Active + Inactive) for admin management.
  Stream<List<FoodCategory>> watchAllCategories() {
    return _categoriesRef.orderBy('name').snapshots().map((snapshot) {
      final categories = <FoodCategory>[];
      for (final doc in snapshot.docs) {
        try {
          categories.add(FoodCategory.fromFirestore(doc));
        } catch (_) {
          continue;
        }
      }
      return categories;
    });
  }

  /// Single recipe fetch by ID.
  Future<Recipe?> getRecipeById(String recipeId) async {
    final doc = await _recipesRef.doc(recipeId).get();
    if (!doc.exists) return null;
    return Recipe.fromFirestore(doc);
  }

  // ===========================================================================
  // RECIPE ADMIN CRUD
  // ===========================================================================

  /// Creates a new recipe with server timestamps and audit UID.
  Future<void> createRecipe(Recipe recipe, String uid) async {
    final docRef =
        recipe.id.isNotEmpty ? _recipesRef.doc(recipe.id) : _recipesRef.doc();

    final data = recipe.toMap();
    data['id'] = docRef.id;
    data['createdBy'] = uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
  }

  /// Updates an existing recipe document.
  Future<void> updateRecipe(Recipe recipe, String uid) async {
    final data = recipe.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _recipesRef.doc(recipe.id).update(data);
  }

  /// Toggles the published status of a recipe.
  Future<void> togglePublishRecipe(String recipeId, bool isPublished) async {
    await _recipesRef.doc(recipeId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a recipe document from Firestore.
  Future<void> deleteRecipe(String recipeId) async {
    await _recipesRef.doc(recipeId).delete();
  }

  // ===========================================================================
  // CATEGORY ADMIN CRUD
  // ===========================================================================

  /// Checks if a category name already exists (case-insensitive).
  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    final normalized = name.trim().toLowerCase();
    final snapshot = await _categoriesRef.get();
    for (final doc in snapshot.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      final docName =
          (doc.data()['name'] ?? '').toString().trim().toLowerCase();
      if (docName == normalized) return true;
    }
    return false;
  }

  /// Creates a new category document.
  Future<void> createCategory(FoodCategory category, String uid) async {
    final docRef = category.id.isNotEmpty
        ? _categoriesRef.doc(category.id)
        : _categoriesRef.doc();

    final data = category.toMap();
    data['id'] = docRef.id;
    data['createdBy'] = uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
  }

  /// Updates an existing category document.
  Future<void> updateCategory(FoodCategory category) async {
    final data = category.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _categoriesRef.doc(category.id).update(data);
  }

  /// Toggles active/inactive status of a category.
  Future<void> toggleCategoryActive(String categoryId, bool isActive) async {
    await _categoriesRef.doc(categoryId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a category document.
  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  /// Counts how many recipes belong to a given category name.
  Future<int> countRecipesInCategory(String categoryName) async {
    final snapshot =
        await _recipesRef.where('category', isEqualTo: categoryName).get();
    return snapshot.size;
  }

  // ===========================================================================
  // USER-SPECIFIC FAVORITES & ENGAGEMENT
  // ===========================================================================

  /// Streams the authenticated user's favorite recipe IDs.
  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  /// Adds a favorite entry to the user's favorites subcollection.
  Future<void> addFavorite(String uid, String recipeId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(recipeId)
        .set({
      'recipeId': recipeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a favorite entry from the user's favorites subcollection.
  Future<void> removeFavorite(String uid, String recipeId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(recipeId)
        .delete();
  }

  /// Increments viewCount on the recipe document to track popularity.
  Future<void> incrementViewCount(String recipeId) {
    return _recipesRef.doc(recipeId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Backward-compatibility alias
  Stream<List<Recipe>> watchRecipes() => watchPublishedRecipes();
  Stream<List<FoodCategory>> watchCategories() => watchActiveCategories();
}
