import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recipe Seed JSON Data Validation Test', () {
    final file = File('assets/data/recipe_firebase_seed.json');
    expect(file.existsSync(), isTrue,
        reason: 'recipe_firebase_seed.json does not exist');

    final jsonContent = file.readAsStringSync();
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;

    final categories = data['categories'] as Map<String, dynamic>;
    final recipes = data['recipes'] as Map<String, dynamic>;

    // 1. Verify exactly 5 categories
    expect(categories.keys.length, equals(5),
        reason: 'Must have exactly 5 categories');

    // 2. Verify exactly 25 recipes
    expect(recipes.keys.length, equals(25),
        reason: 'Must have exactly 25 recipes');

    // Track recipes per category
    final categoryCounts = <String, int>{};
    for (var cat in categories.values) {
      final name = cat['name'] as String;
      categoryCounts[name] = 0;
    }

    for (var entry in recipes.entries) {
      final recipeId = entry.key;
      final recipe = entry.value as Map<String, dynamic>;

      // 3. Every recipe has a valid name
      final name = recipe['name'];
      expect(name, isNotNull, reason: '$recipeId name is missing');
      expect(name, isInstanceOf<String>(),
          reason: '$recipeId name must be a string');
      expect((name as String).trim(), isNotEmpty,
          reason: '$recipeId name must not be empty');

      // 4. Every recipe has a category
      final category = recipe['category'] as String?;
      expect(category, isNotNull, reason: '$recipeId category is missing');
      expect(categoryCounts.containsKey(category), isTrue,
          reason: '$recipeId has invalid category: $category');

      // Increment counts
      categoryCounts[category!] = categoryCounts[category]! + 1;

      // 5. Every recipe has a non-empty image URL
      final image = recipe['image'];
      expect(image, isNotNull, reason: '$recipeId image is missing');
      expect(image, isInstanceOf<String>(),
          reason: '$recipeId image must be a string');
      expect((image as String).trim(), isNotEmpty,
          reason: '$recipeId image URL must not be empty');
      expect(image.startsWith('https://'), isTrue,
          reason: '$recipeId image URL must start with https://');

      // 6. ingredientName.length == ingredientAmount.length == ingredientImage.length
      final ingredientName = recipe['ingredientName'] as List;
      final ingredientAmount = recipe['ingredientAmount'] as List;
      final ingredientImage = recipe['ingredientImage'] as List;

      expect(ingredientName.length, equals(ingredientAmount.length),
          reason:
              '$recipeId ingredientName and ingredientAmount length mismatch');
      expect(ingredientAmount.length, equals(ingredientImage.length),
          reason:
              '$recipeId ingredientAmount and ingredientImage length mismatch');

      // 7. Every recipe has at least 5 instructions
      final instructions = recipe['instructions'] as List?;
      expect(instructions, isNotNull,
          reason: '$recipeId instructions is missing');
      expect(instructions!.length >= 5, isTrue,
          reason:
              '$recipeId must have at least 5 instructions, found ${instructions.length}');

      // 8. Every instruction is a non-empty string
      for (var i = 0; i < instructions.length; i++) {
        final step = instructions[i];
        expect(step, isInstanceOf<String>(),
            reason: '$recipeId instruction index $i must be a string');
        expect((step as String).trim(), isNotEmpty,
            reason: '$recipeId instruction index $i must not be empty');
      }

      // 9. rating is numeric
      final rating = recipe['rating'];
      expect(rating, isNotNull, reason: '$recipeId rating is missing');
      expect(rating is num, isTrue,
          reason: '$recipeId rating must be a number');

      // 10. review is numeric
      final review = recipe['review'];
      expect(review, isNotNull, reason: '$recipeId review is missing');
      expect(review is int, isTrue,
          reason: '$recipeId review must be an integer');

      // 11. time is numeric
      final time = recipe['time'];
      expect(time, isNotNull, reason: '$recipeId time is missing');
      expect(time is int, isTrue, reason: '$recipeId time must be an integer');

      // 12. isFavorite is boolean
      final isFavorite = recipe['isFavorite'];
      expect(isFavorite, isNotNull, reason: '$recipeId isFavorite is missing');
      expect(isFavorite is bool, isTrue,
          reason: '$recipeId isFavorite must be a boolean');
    }

    // 13. Verify exactly 5 recipes per category
    for (var entry in categoryCounts.entries) {
      expect(entry.value, equals(5),
          reason:
              'Category ${entry.key} must have exactly 5 recipes, found ${entry.value}');
    }
  });
}
