import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to the `categories` Firestore collection.
class FoodCategory {
  final String id;
  final String name;
  final String? image;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String searchName;

  const FoodCategory({
    required this.id,
    required this.name,
    this.image,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    String? searchName,
  }) : searchName = searchName ?? name;

  factory FoodCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = (data['name'] ?? '').toString().trim();

    return FoodCategory(
      id: doc.id,
      name: name,
      image: data['image'] as String?,
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] as String?,
      searchName: (data['searchName'] ?? name.toLowerCase()).toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'isActive': isActive,
      'searchName': name.toLowerCase(),
      if (createdBy != null) 'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FoodCategory copyWith({
    String? id,
    String? name,
    String? image,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? searchName,
  }) {
    return FoodCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      searchName: searchName ?? this.searchName,
    );
  }
}
