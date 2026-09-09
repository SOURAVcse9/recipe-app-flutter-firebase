import 'package:cloud_firestore/cloud_firestore.dart';

/// Structured ingredient model for production recipe composition.
class IngredientItem {
  final String name;
  final String amount;
  final String image;

  const IngredientItem({
    required this.name,
    required this.amount,
    this.image = '',
  });

  factory IngredientItem.fromMap(Map<String, dynamic> map) {
    return IngredientItem(
      name: (map['name'] ?? '').toString(),
      amount: (map['amount'] ?? '').toString(),
      image: (map['image'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'image': image,
    };
  }

  IngredientItem copyWith({
    String? name,
    String? amount,
    String? image,
  }) {
    return IngredientItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      image: image ?? this.image,
    );
  }
}

/// Recipe model mapped to Firestore with dual structured and parallel array support.
class Recipe {
  final String id;
  final String name;
  final String calorie;
  final String category;
  final String categoryId;
  final String image;
  final double rating;
  final int review;
  final int time;
  final bool isFavorite;
  final bool isPublished;
  final List<IngredientItem> ingredients;
  final List<String> ingredientImage;
  final List<String> ingredientName;
  final List<String> ingredientAmount;
  final List<String> instructions;
  final int viewCount;
  final int favoriteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String searchName;

  const Recipe({
    required this.id,
    required this.name,
    required this.calorie,
    required this.category,
    String? categoryId,
    required this.image,
    required this.rating,
    required this.review,
    required this.time,
    required this.isFavorite,
    this.isPublished = true,
    List<IngredientItem>? ingredients,
    required this.ingredientImage,
    required this.ingredientName,
    required this.ingredientAmount,
    required this.instructions,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    String? searchName,
  })  : categoryId = categoryId ?? category,
        ingredients = ingredients ?? const [],
        searchName = searchName ?? name;

  /// Empty/placeholder recipe used for error/empty states.
  factory Recipe.empty() => const Recipe(
        id: '',
        name: '',
        calorie: '0',
        category: '',
        categoryId: '',
        image: '',
        rating: 0,
        review: 0,
        time: 0,
        isFavorite: false,
        isPublished: true,
        ingredients: [],
        ingredientImage: [],
        ingredientName: [],
        ingredientAmount: [],
        instructions: [],
        viewCount: 0,
        favoriteCount: 0,
      );

  /// Safely builds a Recipe from a Firestore document.
  factory Recipe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final rawName = _asString(data['name'], fallback: 'Untitled Recipe');
    final rawCategory = _asString(data['category'], fallback: 'Uncategorized');
    final rawNames = _asStringList(data['ingredientName']);
    final rawAmounts = _asStringList(data['ingredientAmount']);
    final rawImages = _asStringList(data['ingredientImage']);

    // Build structured ingredients from structured list or fallback to parallel arrays
    final structuredList = <IngredientItem>[];
    if (data['ingredients'] is List && (data['ingredients'] as List).isNotEmpty) {
      for (final item in data['ingredients'] as List) {
        if (item is Map<String, dynamic>) {
          structuredList.add(IngredientItem.fromMap(item));
        } else if (item is Map) {
          structuredList.add(
            IngredientItem.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    } else {
      final count = [rawNames.length, rawAmounts.length, rawImages.length];
      count.sort();
      final safeLen = count.first;
      for (var i = 0; i < safeLen; i++) {
        structuredList.add(
          IngredientItem(
            name: rawNames[i],
            amount: rawAmounts[i],
            image: rawImages[i],
          ),
        );
      }
    }

    // Ensure parallel arrays match structured ingredients if missing
    final names = rawNames.isNotEmpty
        ? rawNames
        : structuredList.map((e) => e.name).toList();
    final amounts = rawAmounts.isNotEmpty
        ? rawAmounts
        : structuredList.map((e) => e.amount).toList();
    final images = rawImages.isNotEmpty
        ? rawImages
        : structuredList.map((e) => e.image).toList();

    return Recipe(
      id: doc.id,
      name: rawName,
      calorie: _asString(data['calorie'], fallback: '0'),
      category: rawCategory,
      categoryId: _asString(data['categoryId'], fallback: rawCategory.toLowerCase()),
      image: _asString(data['image']),
      rating: _asDouble(data['rating']),
      review: _asInt(data['review']),
      time: _asInt(data['time']),
      isFavorite: data['isFavorite'] == true,
      isPublished: data['isPublished'] is bool ? data['isPublished'] as bool : true,
      ingredients: structuredList,
      ingredientImage: images,
      ingredientName: names,
      ingredientAmount: amounts,
      instructions: _asStringList(data['instructions']),
      viewCount: _asInt(data['viewCount']),
      favoriteCount: _asInt(data['favoriteCount']),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] as String?,
      searchName: _asString(data['searchName'], fallback: rawName.toLowerCase()),
    );
  }

  Map<String, dynamic> toMap() {
    // Generate both structured items and legacy parallel arrays
    final names = ingredients.isNotEmpty
        ? ingredients.map((e) => e.name).toList()
        : ingredientName;
    final amounts = ingredients.isNotEmpty
        ? ingredients.map((e) => e.amount).toList()
        : ingredientAmount;
    final images = ingredients.isNotEmpty
        ? ingredients.map((e) => e.image).toList()
        : ingredientImage;

    final structList = ingredients.isNotEmpty
        ? ingredients.map((e) => e.toMap()).toList()
        : List.generate(
            names.length,
            (i) => {
              'name': names[i],
              'amount': i < amounts.length ? amounts[i] : '',
              'image': i < images.length ? images[i] : '',
            },
          );

    return {
      'id': id,
      'name': name,
      'calorie': calorie,
      'category': category,
      'categoryId': categoryId.isNotEmpty ? categoryId : category.toLowerCase(),
      'image': image,
      'rating': rating,
      'review': review,
      'time': time,
      'isFavorite': isFavorite,
      'isPublished': isPublished,
      'ingredients': structList,
      'ingredientImage': images,
      'ingredientName': names,
      'ingredientAmount': amounts,
      'instructions': instructions,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'searchName': name.toLowerCase(),
      if (createdBy != null) 'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? calorie,
    String? category,
    String? categoryId,
    String? image,
    double? rating,
    int? review,
    int? time,
    bool? isFavorite,
    bool? isPublished,
    List<IngredientItem>? ingredients,
    List<String>? ingredientImage,
    List<String>? ingredientName,
    List<String>? ingredientAmount,
    List<String>? instructions,
    int? viewCount,
    int? favoriteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? searchName,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      calorie: calorie ?? this.calorie,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      time: time ?? this.time,
      isFavorite: isFavorite ?? this.isFavorite,
      isPublished: isPublished ?? this.isPublished,
      ingredients: ingredients ?? this.ingredients,
      ingredientImage: ingredientImage ?? this.ingredientImage,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientAmount: ingredientAmount ?? this.ingredientAmount,
      instructions: instructions ?? this.instructions,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      searchName: searchName ?? this.searchName,
    );
  }

  int get safeIngredientCount {
    if (ingredients.isNotEmpty) return ingredients.length;
    final lengths = [
      ingredientName.length,
      ingredientAmount.length,
      ingredientImage.length,
    ];
    lengths.sort();
    return lengths.first;
  }

  bool get hasMismatchedIngredientArrays {
    if (ingredients.isNotEmpty) return false;
    return !(ingredientName.length == ingredientAmount.length &&
        ingredientAmount.length == ingredientImage.length);
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return const [];
  }
}
