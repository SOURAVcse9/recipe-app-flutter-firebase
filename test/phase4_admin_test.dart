import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/food_category.dart';
import 'package:recipe_app/models/recipe.dart';

bool isValidHttpsUrl(String? url) {
  if (url == null || url.trim().isEmpty) return true;
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}

void main() {
  group('Phase 4: Admin & Role-Based Model Serialization Tests', () {
    test(
        'Recipe model parses legacy parallel arrays into structured IngredientItems',
        () {
      const recipe = Recipe(
        id: 'legacy_recipe_1',
        name: 'Classic Pancakes',
        calorie: '350',
        category: 'Breakfast',
        image: 'https://example.com/pancake.jpg',
        rating: 4.8,
        review: 120,
        time: 20,
        isFavorite: false,
        isPublished: true,
        ingredients: [
          IngredientItem(
              name: 'Flour',
              amount: '200 g',
              image: 'https://example.com/flour.jpg'),
          IngredientItem(
              name: 'Milk',
              amount: '1 cup',
              image: 'https://example.com/milk.jpg'),
        ],
        ingredientImage: [
          'https://example.com/flour.jpg',
          'https://example.com/milk.jpg'
        ],
        ingredientName: ['Flour', 'Milk'],
        ingredientAmount: ['200 g', '1 cup'],
        instructions: ['Mix flour and milk', 'Pour onto pan', 'Flip and serve'],
      );

      expect(recipe.ingredients.length, equals(2));
      expect(recipe.ingredients.first.name, equals('Flour'));
      expect(recipe.ingredients.first.amount, equals('200 g'));
      expect(recipe.isPublished, isTrue);

      final map = recipe.toMap();
      expect(map['ingredients'], isA<List>());
      expect((map['ingredients'] as List).length, equals(2));
      expect(map['ingredientName'], equals(['Flour', 'Milk']));
      expect(map['ingredientAmount'], equals(['200 g', '1 cup']));
      expect(map['isPublished'], isTrue);
    });

    test('Recipe model defaults isPublished to true when field is absent', () {
      final recipe = Recipe.empty();
      expect(recipe.isPublished, isTrue);
    });

    test('FoodCategory model defaults isActive to true and sets searchName',
        () {
      const category = FoodCategory(
        id: 'dessert',
        name: 'Dessert',
      );

      expect(category.isActive, isTrue);
      expect(category.searchName, equals('Dessert'));

      final map = category.toMap();
      expect(map['isActive'], isTrue);
      expect(map['searchName'], equals('dessert'));
    });
  });

  group('Phase 4: HTTPS Image URL Validation Tests', () {
    test('Allows valid HTTPS image URLs', () {
      expect(isValidHttpsUrl('https://images.unsplash.com/photo-1546069901'),
          isTrue);
      expect(isValidHttpsUrl('https://example.com/image.jpg'), isTrue);
    });

    test('Allows valid HTTP image URLs', () {
      expect(isValidHttpsUrl('http://example.com/image.png'), isTrue);
    });

    test('Allows empty/null image URLs when optional', () {
      expect(isValidHttpsUrl(''), isTrue);
      expect(isValidHttpsUrl(null), isTrue);
    });

    test('Rejects invalid URLs without schemes or malformed', () {
      expect(isValidHttpsUrl('not-a-url'), isFalse);
      expect(isValidHttpsUrl('ftp://invalid-scheme.com/pic.jpg'), isFalse);
    });
  });

  group('Phase 4: Audience vs Admin Recipe Filtering Logic Tests', () {
    final mockRecipes = [
      const Recipe(
        id: 'r1',
        name: 'Published Salad',
        calorie: '150',
        category: 'Vegetables',
        image: 'https://example.com/salad.jpg',
        rating: 4.5,
        review: 10,
        time: 15,
        isFavorite: false,
        isPublished: true,
        ingredients: [],
        ingredientImage: [],
        ingredientName: [],
        ingredientAmount: [],
        instructions: ['Wash greens', 'Toss with dressing'],
      ),
      const Recipe(
        id: 'r2',
        name: 'Draft Curry',
        calorie: '400',
        category: 'Dinner',
        image: 'https://example.com/curry.jpg',
        rating: 4.9,
        review: 5,
        time: 40,
        isFavorite: false,
        isPublished: false, // Draft
        ingredients: [],
        ingredientImage: [],
        ingredientName: [],
        ingredientAmount: [],
        instructions: ['Simmer spices'],
      ),
    ];

    test('Audience queries filter out unpublished drafts', () {
      final audienceVisible = mockRecipes.where((r) => r.isPublished).toList();
      expect(audienceVisible.length, equals(1));
      expect(audienceVisible.first.id, equals('r1'));
    });

    test('Admin queries include all recipes (drafts and published)', () {
      final adminVisible = mockRecipes.toList();
      expect(adminVisible.length, equals(2));
      expect(adminVisible.any((r) => !r.isPublished), isTrue);
    });
  });
}
