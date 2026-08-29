import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String reviewText;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool verifiedPurchase;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.reviewText,
    this.createdAt,
    this.updatedAt,
    this.verifiedPurchase = false,
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdVal = data['createdAt'];
    final updatedVal = data['updatedAt'];

    return Review(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'Anonymous').toString(),
      rating: _asDouble(data['rating']),
      reviewText: (data['reviewText'] ?? '').toString(),
      createdAt: createdVal is Timestamp ? createdVal.toDate() : null,
      updatedAt: updatedVal is Timestamp ? updatedVal.toDate() : null,
      verifiedPurchase: data['verifiedPurchase'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'verifiedPurchase': verifiedPurchase,
    };
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
