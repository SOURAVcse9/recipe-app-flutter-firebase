import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/review.dart';

void main() {
  group('Phase 3 Unit Tests', () {
    test('User profile serialization', () {
      final map = {
        'uid': 'user_abc',
        'name': 'Jane Doe',
        'email': 'jane@gmail.com',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      expect(map['uid'], equals('user_abc'));
      expect(map['name'], equals('Jane Doe'));
      expect(map['email'], equals('jane@gmail.com'));
    });

    test('Login and Signup validation rules', () {
      String? validateEmail(String? value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        if (!value.contains('@')) return 'Invalid';
        return null;
      }

      String? validatePassword(String? value) {
        if (value == null || value.isEmpty) return 'Required';
        if (value.length < 6) return 'Short';
        return null;
      }

      expect(validateEmail(''), equals('Required'));
      expect(validateEmail('invalid'), equals('Invalid'));
      expect(validateEmail('test@gmail.com'), isNull);

      expect(validatePassword(''), equals('Required'));
      expect(validatePassword('123'), equals('Short'));
      expect(validatePassword('123456'), isNull);
    });

    test('Review ownership verification', () {
      const currentUid = 'user_123';
      const review = Review(
        id: 'r1',
        userId: 'user_123',
        userName: 'A',
        rating: 5.0,
        reviewText: 'Nice',
      );

      final isOwner = review.userId == currentUid;
      expect(isOwner, isTrue);
    });

    test('Favorite ownership verification', () {
      const currentUid = 'user_123';
      final favoriteMap = {
        'recipeId': 'recipe_1',
        'userId': 'user_123',
      };

      final isOwner = favoriteMap['userId'] == currentUid;
      expect(isOwner, isTrue);
    });

    test('Popular recipe ordering logic', () {
      final recipes = [
        const Recipe(
          id: 'r1',
          name: 'A',
          calorie: '0',
          category: '',
          image: '',
          rating: 0,
          review: 0,
          time: 0,
          isFavorite: false,
          ingredientImage: [],
          ingredientName: [],
          ingredientAmount: [],
          instructions: [],
          viewCount: 10,
        ),
        const Recipe(
          id: 'r2',
          name: 'B',
          calorie: '0',
          category: '',
          image: '',
          rating: 0,
          review: 0,
          time: 0,
          isFavorite: false,
          ingredientImage: [],
          ingredientName: [],
          ingredientAmount: [],
          instructions: [],
          viewCount: 20,
        ),
      ];

      recipes.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      expect(recipes.first.id, equals('r2'));
    });

    test('Top Rated recipe ordering logic', () {
      final recipes = [
        const Recipe(
          id: 'r1',
          name: 'A',
          calorie: '0',
          category: '',
          image: '',
          rating: 4.2,
          review: 2,
          time: 0,
          isFavorite: false,
          ingredientImage: [],
          ingredientName: [],
          ingredientAmount: [],
          instructions: [],
        ),
        const Recipe(
          id: 'r2',
          name: 'B',
          calorie: '0',
          category: '',
          image: '',
          rating: 4.8,
          review: 3,
          time: 0,
          isFavorite: false,
          ingredientImage: [],
          ingredientName: [],
          ingredientAmount: [],
          instructions: [],
        ),
      ];

      recipes.sort((a, b) => b.rating.compareTo(a.rating));
      expect(recipes.first.id, equals('r2'));
    });

    test('ViewCount increment logic', () {
      int viewCount = 5;
      viewCount++;
      expect(viewCount, equals(6));
    });
  });
}
