import 'package:cloud_firestore/cloud_firestore.dart';

/// Recipe model mapped 1:1 to the "complete Flutter app" Firestore collection.
///
/// Field names are intentionally kept exactly as they exist in Firestore
/// (e.g. `calorie`, not `calories`) to avoid silent mapping failures.
/// See STRICT FIELD NAMING in the architecture spec.
class Recipe {
  final String id;
  final String name;
  final String calorie;
  final String category;
  final String image;
  final double rating;
  final int review;
  final int time;
  final bool isFavorite;
  final List<String> ingredientImage;
  final List<String> ingredientName;
  final List<String> ingredientAmount;

  const Recipe({
    required this.id,
    required this.name,
    required this.calorie,
    required this.category,
    required this.image,
    required this.rating,
    required this.review,
    required this.time,
    required this.isFavorite,
    required this.ingredientImage,
    required this.ingredientName,
    required this.ingredientAmount,
  });

  /// Empty/placeholder recipe used for error/empty states.
  factory Recipe.empty() => const Recipe(
        id: '',
        name: '',
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
      );

  /// Safely builds a Recipe from a Firestore document.
  ///
  /// Firestore can return numeric fields as int, double, or (due to bad
  /// writes) even String — so every field is defensively coerced instead of
  /// blindly cast. Missing fields fall back to sane defaults rather than
  /// throwing, so a single malformed document never crashes the app.
  factory Recipe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Recipe(
      id: doc.id,
      name: _asString(data['name'], fallback: 'Untitled Recipe'),
      calorie: _asString(data['calorie'], fallback: '0'),
      category: _asString(data['category'], fallback: 'Uncategorized'),
      image: _asString(data['image']),
      rating: _asDouble(data['rating']),
      review: _asInt(data['review']),
      time: _asInt(data['time']),
      isFavorite: data['isFavorite'] == true,
      ingredientImage: _asStringList(data['ingredientImage']),
      ingredientName: _asStringList(data['ingredientName']),
      ingredientAmount: _asStringList(data['ingredientAmount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calorie': calorie,
      'category': category,
      'image': image,
      'rating': rating,
      'review': review,
      'time': time,
      'isFavorite': isFavorite,
      'ingredientImage': ingredientImage,
      'ingredientName': ingredientName,
      'ingredientAmount': ingredientAmount,
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? calorie,
    String? category,
    String? image,
    double? rating,
    int? review,
    int? time,
    bool? isFavorite,
    List<String>? ingredientImage,
    List<String>? ingredientName,
    List<String>? ingredientAmount,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      calorie: calorie ?? this.calorie,
      category: category ?? this.category,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      time: time ?? this.time,
      isFavorite: isFavorite ?? this.isFavorite,
      ingredientImage: ingredientImage ?? this.ingredientImage,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientAmount: ingredientAmount ?? this.ingredientAmount,
    );
  }

  /// Number of ingredients that can be *safely* rendered — i.e. the
  /// shortest of the three parallel arrays. See PARALLEL ARRAY VALIDATION.
  int get safeIngredientCount {
    final lengths = [
      ingredientName.length,
      ingredientAmount.length,
      ingredientImage.length,
    ];
    lengths.sort();
    return lengths.first;
  }

  /// Whether the three parallel ingredient arrays are mismatched in length.
  /// The UI can use this to show a subtle "data may be incomplete" notice
  /// instead of crashing or silently mis-mapping ingredients.
  bool get hasMismatchedIngredientArrays {
    return !(ingredientName.length == ingredientAmount.length &&
        ingredientAmount.length == ingredientImage.length);
  }

  // ---- Safe coercion helpers -------------------------------------------

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
