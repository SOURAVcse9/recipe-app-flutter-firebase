import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/food_category.dart';
import '../models/recipe.dart';

/// All direct Firebase access (Firestore + Storage) is isolated here.
///
/// Widgets never talk to Firebase directly — they go through
/// [RecipeProvider], which goes through this repository. This keeps the
/// UI layer free of Firebase-specific types and makes it possible to swap
/// the backend later without touching screens/widgets.
///
/// NOTE ON COLLECTION NAME: the source specification names the primary
/// collection literally `complete Flutter app` (with spaces). That name is
/// preserved here for compatibility, but it is isolated to this one
/// constant so it can be renamed in a single place if desired.
class RecipeRepository {
  RecipeRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String recipesCollection = 'complete Flutter app';
  static const String categoriesCollection = 'categories';

  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _firestore.collection(recipesCollection);

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection(categoriesCollection);

  /// Real-time stream of all recipes. Firestore's built-in offline
  /// persistence means this stream continues to emit cached data even
  /// when the network briefly drops.
  Stream<List<Recipe>> getRecipeStream() {
    return _recipesRef.snapshots().map((snapshot) {
      final recipes = <Recipe>[];
      for (final doc in snapshot.docs) {
        try {
          recipes.add(Recipe.fromFirestore(doc));
        } catch (_) {
          // Skip a single malformed document rather than failing the
          // entire stream / crashing the app.
          continue;
        }
      }
      return recipes;
    });
  }

  /// Real-time stream of categories, ordered by name.
  Stream<List<FoodCategory>> getCategoryStream() {
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

  /// One-off fetch (non-streaming) — kept for completeness / places that
  /// don't need a live subscription (e.g. pull-to-refresh fallback).
  Future<List<Recipe>> getRecipes() async {
    final snapshot = await _recipesRef.get();
    return snapshot.docs.map(Recipe.fromFirestore).toList();
  }

  Future<List<FoodCategory>> getCategories() async {
    final snapshot = await _categoriesRef.orderBy('name').get();
    return snapshot.docs.map(FoodCategory.fromFirestore).toList();
  }

  /// Persists the favorite flag for a single recipe document.
  ///
  /// Kept schema-compatible with the source spec (`isFavorite` lives on
  /// the recipe document itself). If this later migrates to
  /// `users/{uid}/favorites/{recipeId}`, only this method needs to change —
  /// the Provider/UI contract (`toggleFavorite(recipeId, value)`) stays
  /// the same.
  Future<void> updateFavorite(String recipeId, bool isFavorite) {
    return _recipesRef.doc(recipeId).update({'isFavorite': isFavorite});
  }

  /// Uploads a single image file (as bytes) to Firebase Storage under
  /// `image/<subfolder>/<fileName>` and returns its public download URL.
  /// Used by admin/seed tooling, not by the end-user app flow.
  Future<String> uploadImage({
    required String subfolder,
    required String fileName,
    required List<int> bytes,
  }) async {
    final ref = _storage.ref().child('image/$subfolder/$fileName');
    final task = await ref.putData(Uint8List.fromList(bytes));
    return task.ref.getDownloadURL();
  }
}
