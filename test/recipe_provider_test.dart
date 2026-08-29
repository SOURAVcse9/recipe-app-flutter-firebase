import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/app_preferences.dart';
import 'package:recipe_app/models/food_category.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/repositories/recipe_repository.dart';

class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeUser implements User {
  @override
  String get uid => 'test_uid_123';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeUserCredential implements UserCredential {
  @override
  User get user => FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseAuth implements FirebaseAuth {
  final _userChangesController = StreamController<User?>.broadcast();
  User? _currentUser;

  FakeFirebaseAuth({User? initialUser}) : _currentUser = initialUser {
    _userChangesController.onListen = () {
      _userChangesController.add(_currentUser);
    };
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> userChanges() => _userChangesController.stream;

  @override
  Future<UserCredential> signInAnonymously() async {
    final cred = FakeUserCredential();
    _currentUser = cred.user;
    _userChangesController.add(_currentUser);
    return cred;
  }

  void emitUser(User? user) {
    _currentUser = user;
    _userChangesController.add(user);
  }

  void dispose() {
    _userChangesController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockRecipeRepository extends RecipeRepository {
  final _recipesController = StreamController<List<Recipe>>.broadcast();
  final _categoriesController = StreamController<List<FoodCategory>>.broadcast();
  final _favoritesController = StreamController<Set<String>>.broadcast();

  MockRecipeRepository()
      : super(
          firestore: FakeFirebaseFirestore(),
        );

  @override
  Stream<List<Recipe>> watchRecipes() => _recipesController.stream;

  @override
  Stream<List<FoodCategory>> watchCategories() => _categoriesController.stream;

  @override
  Stream<Set<String>> watchFavoriteIds(String uid) => _favoritesController.stream;

  @override
  Future<void> addFavorite(String uid, String recipeId) async {
    // Stub implementation
  }

  @override
  Future<void> removeFavorite(String uid, String recipeId) async {
    // Stub implementation
  }

  void emitRecipes(List<Recipe> recipes) {
    _recipesController.add(recipes);
  }

  void emitCategories(List<FoodCategory> categories) {
    _categoriesController.add(categories);
  }

  void emitFavoriteIds(Set<String> favoriteIds) {
    _favoritesController.add(favoriteIds);
  }

  void dispose() {
    _recipesController.close();
    _categoriesController.close();
    _favoritesController.close();
  }
}

void main() {
  late MockRecipeRepository mockRepo;
  late FakeFirebaseAuth mockAuth;
  late RecipeProvider provider;

  const defaultPrefs = AppPreferences();

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
      instructions: ['Step 1'],
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
      isFavorite: false,
      ingredientImage: ['https://...'],
      ingredientName: ['Avocado'],
      ingredientAmount: ['1 piece'],
      instructions: ['Step 1'],
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
      instructions: ['Step 1'],
    ),
  ];

  final sampleCategories = [
    const FoodCategory(id: 'c1', name: 'Breakfast'),
    const FoodCategory(id: 'c2', name: 'Food'),
  ];

  Future<void> waitForAuth() async {
    while (provider.authLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  setUp(() {
    mockRepo = MockRecipeRepository();
    mockAuth = FakeFirebaseAuth(initialUser: FakeUser());
    provider = RecipeProvider(repository: mockRepo, auth: mockAuth);
  });

  tearDown(() {
    mockRepo.dispose();
    mockAuth.dispose();
  });

  group('RecipeProvider Tests', () {
    test('Loads recipes and categories successfully from streams', () async {
      // Wait for auth to complete
      await waitForAuth();

      expect(provider.authLoading, isFalse);
      expect(provider.uid, equals('test_uid_123'));

      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitCategories(sampleCategories);
      mockRepo.emitFavoriteIds({'2'}); // Avocado Toast is favorited

      await Future<void>.delayed(const Duration(milliseconds: 2));

      expect(provider.recipeStatus, equals(LoadStatus.loaded));
      expect(provider.categoryStatus, equals(LoadStatus.loaded));
      expect(provider.filteredRecipes(defaultPrefs).length, equals(3));
      expect(provider.categoryNames, equals(['All', 'Breakfast', 'Food']));

      // Avocado Toast should dynamically evaluate as favorite
      expect(provider.filteredRecipes(defaultPrefs)[1].isFavorite, isTrue);
      expect(provider.filteredRecipes(defaultPrefs)[0].isFavorite, isFalse);
    });

    test('Category filtering works correctly', () async {
      await waitForAuth();
      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitFavoriteIds({});
      await Future<void>.delayed(const Duration(milliseconds: 2));

      // Default is All
      expect(provider.filteredRecipes(defaultPrefs).length, equals(3));

      // Filter by Breakfast
      provider.setSelectedCategory('Breakfast');
      expect(provider.filteredRecipes(defaultPrefs).length, equals(2));
      expect(
          provider
              .filteredRecipes(defaultPrefs)
              .any((r) => r.name == 'Pasta Primavera'),
          isFalse);

      // Filter by Food
      provider.setSelectedCategory('Food');
      expect(provider.filteredRecipes(defaultPrefs).length, equals(1));
      expect(provider.filteredRecipes(defaultPrefs).first.name,
          equals('Pasta Primavera'));
    });

    test('Case-insensitive search works correctly', () async {
      await waitForAuth();
      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitFavoriteIds({});
      await Future<void>.delayed(const Duration(milliseconds: 2));

      // Search matching lower/uppercase
      provider.setSearchQuery('paneer');
      expect(provider.filteredRecipes(defaultPrefs).length, equals(1));
      expect(provider.filteredRecipes(defaultPrefs).first.name,
          equals('Butter Paneer'));

      provider.setSearchQuery('PANEER');
      expect(provider.filteredRecipes(defaultPrefs).length, equals(1));
      expect(provider.filteredRecipes(defaultPrefs).first.name,
          equals('Butter Paneer'));
    });

    test('Search by ingredients works correctly', () async {
      await waitForAuth();
      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitFavoriteIds({});
      await Future<void>.delayed(const Duration(milliseconds: 2));

      // Search matching ingredient name "Avocado"
      provider.setSearchQuery('avocado');
      expect(provider.filteredRecipes(defaultPrefs).length, equals(1));
      expect(provider.filteredRecipes(defaultPrefs).first.name,
          equals('Avocado Toast'));
    });

    test('Case-sensitive search works correctly when disabled', () async {
      await waitForAuth();
      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitFavoriteIds({});
      await Future<void>.delayed(const Duration(milliseconds: 2));

      // Case-insensitive search enabled by default: "paneer" matches "Butter Paneer"
      provider.setSearchQuery('paneer');
      expect(
          provider
              .filteredRecipes(
                  const AppPreferences(caseInsensitiveSearch: true))
              .length,
          equals(1));

      // Case-insensitive search disabled: "paneer" does not match "Butter Paneer"
      expect(
          provider
              .filteredRecipes(
                  const AppPreferences(caseInsensitiveSearch: false))
              .length,
          equals(0));

      // Matches exactly
      provider.setSearchQuery('Paneer');
      expect(
          provider
              .filteredRecipes(
                  const AppPreferences(caseInsensitiveSearch: false))
              .length,
          equals(1));
    });

    test('Search + Category filtering combine correctly', () async {
      await waitForAuth();
      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitFavoriteIds({});
      await Future<void>.delayed(const Duration(milliseconds: 2));

      provider.setSelectedCategory('Breakfast');
      provider.setSearchQuery('Toast');

      expect(provider.filteredRecipes(defaultPrefs).length, equals(1));
      expect(provider.filteredRecipes(defaultPrefs).first.name,
          equals('Avocado Toast'));

      // If we switch to 'Food' category with the same search term, it should match nothing
      provider.setSelectedCategory('Food');
      expect(provider.filteredRecipes(defaultPrefs).isEmpty, isTrue);
    });

    test('Favorites filtering works correctly', () async {
      await waitForAuth();
      mockRepo.emitRecipes(sampleRecipes);
      mockRepo.emitFavoriteIds({'2'}); // Avocado Toast is favorite
      await Future<void>.delayed(const Duration(milliseconds: 2));

      expect(provider.favoriteRecipes.length, equals(1));
      expect(provider.favoriteRecipes.first.name, equals('Avocado Toast'));
    });

    test('Quantity increment, decrement, and minimum boundary logic', () async {
      await waitForAuth();
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

    test('Serving quantity respects dynamic default servings', () async {
      await waitForAuth();
      const recipeId = '1';

      // Default servings set to 4
      expect(provider.quantityFor(recipeId, defaultQuantity: 4), equals(4));

      // Increment based on default 4
      provider.incrementQuantity(recipeId, defaultQuantity: 4);
      expect(provider.quantityFor(recipeId, defaultQuantity: 4), equals(5));

      // Decrement back to 4
      provider.decrementQuantity(recipeId, defaultQuantity: 4);
      expect(provider.quantityFor(recipeId, defaultQuantity: 4), equals(4));
    });
  });
}
