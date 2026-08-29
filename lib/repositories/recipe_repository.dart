import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_category.dart';
import '../models/recipe.dart';

/// All direct Firebase access (Firestore only) is isolated here.
///
/// Widgets never talk to Firebase directly — they go through [RecipeProvider],
/// which goes through this repository.
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

  /// Real-time stream of all recipes.
  Stream<List<Recipe>> watchRecipes() {
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

  /// Real-time stream of categories, ordered by name.
  Stream<List<FoodCategory>> watchCategories() {
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

  /// One-off fetch (non-streaming) — kept for compatibility.
  Future<List<Recipe>> getRecipes() async {
    final snapshot = await _recipesRef.get();
    return snapshot.docs.map(Recipe.fromFirestore).toList();
  }

  Future<List<FoodCategory>> getCategories() async {
    final snapshot = await _categoriesRef.orderBy('name').get();
    return snapshot.docs.map(FoodCategory.fromFirestore).toList();
  }

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
}
