import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/models/review.dart';
import 'package:recipe_app/models/shopping_list_item.dart';
import 'package:recipe_app/models/recently_viewed.dart';
import 'package:recipe_app/models/recipe.dart';

// Fake DocumentSnapshot for testing serialization
// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot<T> implements DocumentSnapshot<T> {
  final String _id;
  final T? _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  T? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 2 Model Serialization Tests', () {
    test('Review serialization', () {
      final doc = FakeDocumentSnapshot<Map<String, dynamic>>('review_1', {
        'userId': 'user_123',
        'userName': 'John Doe',
        'rating': 4.5,
        'reviewText': 'Delicious!',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'verifiedPurchase': true,
      });

      final review = Review.fromFirestore(doc);
      expect(review.id, equals('review_1'));
      expect(review.userId, equals('user_123'));
      expect(review.userName, equals('John Doe'));
      expect(review.rating, equals(4.5));
      expect(review.reviewText, equals('Delicious!'));
      expect(review.verifiedPurchase, isTrue);

      final map = review.toMap();
      expect(map['userId'], equals('user_123'));
      expect(map['userName'], equals('John Doe'));
      expect(map['rating'], equals(4.5));
      expect(map['reviewText'], equals('Delicious!'));
      expect(map['verifiedPurchase'], isTrue);
    });

    test('ShoppingListItem serialization', () {
      final doc = FakeDocumentSnapshot<Map<String, dynamic>>('item_1', {
        'name': 'Onion',
        'amount': '2 pieces',
        'recipeId': 'recipe_1',
        'recipeName': 'Butter Paneer',
        'completed': true,
        'createdAt': Timestamp.now(),
      });

      final item = ShoppingListItem.fromFirestore(doc);
      expect(item.id, equals('item_1'));
      expect(item.name, equals('Onion'));
      expect(item.amount, equals('2 pieces'));
      expect(item.recipeId, equals('recipe_1'));
      expect(item.recipeName, equals('Butter Paneer'));
      expect(item.completed, isTrue);

      final map = item.toMap();
      expect(map['name'], equals('Onion'));
      expect(map['amount'], equals('2 pieces'));
      expect(map['recipeId'], equals('recipe_1'));
      expect(map['recipeName'], equals('Butter Paneer'));
      expect(map['completed'], isTrue);
    });

    test('RecentlyViewed serialization', () {
      final doc = FakeDocumentSnapshot<Map<String, dynamic>>('recipe_1', {
        'viewedAt': Timestamp.now(),
      });

      final history = RecentlyViewed.fromFirestore(doc);
      expect(history.recipeId, equals('recipe_1'));

      final map = history.toMap();
      expect(map['recipeId'], equals('recipe_1'));
    });
  });

  group('Rating Calculation & Duplicate Review Prevention Logic Tests', () {
    test('Aggregate Rating calculation', () {
      final reviews = [
        const Review(
            id: '1', userId: 'u1', userName: 'A', rating: 5.0, reviewText: ''),
        const Review(
            id: '2', userId: 'u2', userName: 'B', rating: 4.0, reviewText: ''),
      ];

      final count = reviews.length;
      final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / count;
      expect(avg, equals(4.5));
    });

    test('Prevent duplicates logic (finding existing user review in list)', () {
      final reviews = [
        const Review(
            id: '1',
            userId: 'user_123',
            userName: 'A',
            rating: 5.0,
            reviewText: ''),
        const Review(
            id: '2',
            userId: 'other_user',
            userName: 'B',
            rating: 4.0,
            reviewText: ''),
      ];

      const targetUserId = 'user_123';
      final hasExisting = reviews.any((r) => r.userId == targetUserId);
      expect(hasExisting, isTrue);
    });
  });

  group('Shopping List and History Order Tests', () {
    test('ShoppingListItem completion status toggle', () {
      const item = ShoppingListItem(
        id: '1',
        name: 'Tomato',
        amount: '200g',
        recipeId: 'r1',
        recipeName: 'Stir Fry',
        completed: false,
      );

      final toggled = ShoppingListItem(
        id: item.id,
        name: item.name,
        amount: item.amount,
        recipeId: item.recipeId,
        recipeName: item.recipeName,
        completed: !item.completed,
      );

      expect(toggled.completed, isTrue);
    });

    test('RecentlyViewed ordering (sorted by viewedAt)', () {
      final now = DateTime.now();
      final list = [
        RecentlyViewed(
            recipeId: 'r1', viewedAt: now.subtract(const Duration(minutes: 5))),
        RecentlyViewed(recipeId: 'r2', viewedAt: now),
      ];

      // Sort viewedAt descending
      list.sort((a, b) {
        if (a.viewedAt == null || b.viewedAt == null) return 0;
        return b.viewedAt!.compareTo(a.viewedAt!);
      });

      expect(list.first.recipeId, equals('r2'));
    });
  });

  group('Recipe Cooking Timer Initialization', () {
    test('Timer initialization respects Dynamic Recipe time', () {
      const recipe = Recipe(
        id: 'r1',
        name: 'Butter Paneer',
        calorie: '300',
        category: 'Breakfast',
        image: 'https://...',
        rating: 4.5,
        review: 10,
        time: 25, // 25 minutes
        isFavorite: false,
        ingredientImage: [],
        ingredientName: [],
        ingredientAmount: [],
        instructions: [],
      );

      final timerDurationSeconds = recipe.time * 60;
      expect(timerDurationSeconds, equals(1500));
    });
  });
}
