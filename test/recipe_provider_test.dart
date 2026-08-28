import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/food_category.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/repositories/recipe_repository.dart';

class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockRecipeRepository extends RecipeRepository {
  final _recipesController = StreamController<List<Recipe>>.broadcast();
  final _categoriesController = StreamController<List<FoodCategory>>.broadcast();

  MockRecipeRepository()
      : super(
          firestore: FakeFirebaseFirestore(),
          storage: FakeFirebaseStorage(),
        );

  @override
  Stream<List<Recipe>> getRecipeStream() => _recipesController.stream;

  @override
  Stream<List<FoodCategory>> getCategoryStream() => _categoriesController.stream;

  @override
  Future<void> updateFavorite(String recipeId, bool isFavorite) async {
    // Stub implementation
  }

  void emitRecipes(List<Recipe> recipes) {
    _recipesController.add(recipes);
  }

  void emitCategories(List<FoodCategory> categories) {
    _categoriesController.add(categories);
  }

  void dispose() {
    _recipesController.close();
    _categoriesController.close();
  }
}

void main() {
  late MockRecipeRepository mockRepo;
  late RecipeProvider provider;

  final sampleRecipes = [
    const Recipe(
      id: '1',
      name: 'Butter Paneer',
      calorie: '300',
      category: 'Breakfast',
      image: 'https://...',
      rating: 4.5,
      review: 10,
      time: 25,
      isFavorite: false,
      ingredientImage: ['https://...'],
      ingredientName: ['Paneer'],
      ingredientAmount: ['100 g'],
    ),
    const Recipe(
      id: '2',
      name: 'Avocado Toast',
      calorie: '220',
      category: 'Breakfast',
      image: 'https://...',
      rating: 4.7,
      review: 34,
      time: 15,
      isFavorite: true,
      ingredientImage: ['https://...'],
      ingredientName: ['Avocado'],
      ingredientAmount: ['1 piece'],
    ),
    const Recipe(
      id: '3',
      name: 'Pasta Primavera',
      calorie: '410',
      category: 'Food',
      image: 'https://...',
      rating: 4.3,
      review: 21,
      time: 30,
      isFavorite: false,
      ingredientImage: ['https://...'],
      ingredientName: ['Penne Pasta'],
      ingredientAmount: ['300 g'],
    ),
  ];

  final sampleCategories = [
    const FoodCategory(id: 'c1', name: 'Breakfast'),
    const FoodCategory(id: 'c2', name: 'Food'),
  ];

  setUp(() {
    mockRepo = MockRecipeRepository();
    provider = RecipeProvider(repository: mockRepo);
  });

  tearDown(() {
    mockRepo.dispose();
  });

  group('RecipeProvider Tests', () {
    test('Loads recipes and categories successfully from streams', () async {
      expect(provider.recipeStatus, equals(LoadStatus.loading));
      expect(provider.categoryStatus, equals(LoadStatus.loading));

      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitCategories(sampleCategories);

      // Allow microtasks to complete and stream events to propagate
      await Future<void>.delayed(Duration.zero);

      expect(provider.recipeStatus, equals(LoadStatus.loaded));
      expect(provider.categoryStatus, equals(LoadStatus.loaded));
      expect(provider.filteredRecipes.length, equals(3));
      expect(provider.categoryNames, equals(['All', 'Breakfast', 'Food']));
    });

    test('Category filtering works correctly', () async {
      mockRepo.emitRecipes(sampleRecipes);
      await Future<void>.delayed(Duration.zero);

      // Default is All
      expect(provider.filteredRecipes.length, equals(3));

      // Filter by Breakfast
      provider.setSelectedCategory('Breakfast');
      expect(provider.filteredRecipes.length, equals(2));
      expect(provider.filteredRecipes.any((r) => r.name == 'Pasta Primavera'), isFalse);

      // Filter by Food
      provider.setSelectedCategory('Food');
      expect(provider.filteredRecipes.length, equals(1));
      expect(provider.filteredRecipes.first.name, equals('Pasta Primavera'));
    });

    test('Case-insensitive search works correctly', () async {
      mockRepo.emitRecipes(sampleRecipes);
      await Future<void>.delayed(Duration.zero);

      // Search matching lower/uppercase
      provider.setSearchQuery('paneer');
      expect(provider.filteredRecipes.length, equals(1));
      expect(provider.filteredRecipes.first.name, equals('Butter Paneer'));

      provider.setSearchQuery('PANEER');
      expect(provider.filteredRecipes.length, equals(1));
      expect(provider.filteredRecipes.first.name, equals('Butter Paneer'));
    });

    test('Search + Category filtering combine correctly', () async {
      mockRepo.emitRecipes(sampleRecipes);
      await Future<void>.delayed(Duration.zero);

      provider.setSelectedCategory('Breakfast');
      provider.setSearchQuery('Toast');

      expect(provider.filteredRecipes.length, equals(1));
      expect(provider.filteredRecipes.first.name, equals('Avocado Toast'));

      // If we switch to 'Food' category with the same search term, it should match nothing
      provider.setSelectedCategory('Food');
      expect(provider.filteredRecipes.isEmpty, isTrue);
    });

    test('Favorites filtering works correctly', () async {
      mockRepo.emitRecipes(sampleRecipes);
      await Future<void>.delayed(Duration.zero);

      expect(provider.favoriteRecipes.length, equals(1));
      expect(provider.favoriteRecipes.first.name, equals('Avocado Toast'));
    });

    test('Quantity increment, decrement, and minimum boundary logic', () {
      const recipeId = '1';
      expect(provider.quantityFor(recipeId), equals(1));

      provider.incrementQuantity(recipeId);
      expect(provider.quantityFor(recipeId), equals(2));

      provider.decrementQuantity(recipeId);
      expect(provider.quantityFor(recipeId), equals(1));

      // Decrement below 1 should be prevented
      provider.decrementQuantity(recipeId);
      expect(provider.quantityFor(recipeId), equals(1));
    });
  });
}
