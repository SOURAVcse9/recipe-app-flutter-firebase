import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to the `categories` Firestore collection.
/// Named `FoodCategory` (not `Category`) to avoid clashing with Flutter's
/// own widget-tree `Category` concepts / Dart's `Category` annotations.
class FoodCategory {
  final String id;
  final String name;

  const FoodCategory({required this.id, required this.name});

  factory FoodCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FoodCategory(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name};
}
