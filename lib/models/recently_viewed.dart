import 'package:cloud_firestore/cloud_firestore.dart';

class RecentlyViewed {
  final String recipeId;
  final DateTime? viewedAt;

  const RecentlyViewed({
    required this.recipeId,
    this.viewedAt,
  });

  factory RecentlyViewed.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final viewedVal = data['viewedAt'];

    return RecentlyViewed(
      recipeId: doc.id,
      viewedAt: viewedVal is Timestamp ? viewedVal.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
