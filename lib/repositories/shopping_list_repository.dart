import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list_item.dart';

class ShoppingListRepository {
  final FirebaseFirestore _firestore;

  ShoppingListRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _shoppingListRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('shoppingList');

  Stream<List<ShoppingListItem>> watchItems(String uid) {
    return _shoppingListRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingListItem.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addItems(String uid, List<ShoppingListItem> items) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final docRef = _shoppingListRef(uid).doc();
      batch.set(docRef, item.toMap());
    }
    await batch.commit();
  }

  Future<void> updateItemCompleted(
      String uid, String itemId, bool completed) async {
    await _shoppingListRef(uid).doc(itemId).update({'completed': completed});
  }

  Future<void> deleteItem(String uid, String itemId) async {
    await _shoppingListRef(uid).doc(itemId).delete();
  }

  Future<void> clearCompleted(String uid) async {
    final completedItems =
        await _shoppingListRef(uid).where('completed', isEqualTo: true).get();
    final batch = _firestore.batch();
    for (final doc in completedItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> clearAll(String uid) async {
    final allItems = await _shoppingListRef(uid).get();
    final batch = _firestore.batch();
    for (final doc in allItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
