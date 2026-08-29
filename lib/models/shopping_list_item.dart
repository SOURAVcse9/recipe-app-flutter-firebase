import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListItem {
  final String id;
  final String name;
  final String amount;
  final String recipeId;
  final String recipeName;
  final bool completed;
  final DateTime? createdAt;

  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.recipeId,
    required this.recipeName,
    this.completed = false,
    this.createdAt,
  });

  factory ShoppingListItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdVal = data['createdAt'];

    return ShoppingListItem(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      amount: (data['amount'] ?? '').toString(),
      recipeId: (data['recipeId'] ?? '').toString(),
      recipeName: (data['recipeName'] ?? '').toString(),
      completed: data['completed'] == true,
      createdAt: createdVal is Timestamp ? createdVal.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'completed': completed,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
