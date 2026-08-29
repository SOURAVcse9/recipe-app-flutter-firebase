import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_list_item.dart';
import '../repositories/shopping_list_repository.dart';

enum ShoppingListStatus { loading, loaded, error }

class ShoppingListProvider extends ChangeNotifier {
  final ShoppingListRepository _repository;
  final FirebaseAuth _auth;

  ShoppingListProvider({
    ShoppingListRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? ShoppingListRepository(),
        _auth = auth ?? FirebaseAuth.instance {
    _initAuthSubscription();
  }

  ShoppingListStatus _status = ShoppingListStatus.loading;
  ShoppingListStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ShoppingListItem> _items = [];
  List<ShoppingListItem> get items => _items;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<ShoppingListItem>>? _itemsSub;
  String? _uid;

  void _initAuthSubscription() {
    _authSub = _auth.userChanges().listen((user) {
      if (user?.uid != _uid) {
        _uid = user?.uid;
        if (_uid != null) {
          _subscribeToItems(_uid!);
        } else {
          _itemsSub?.cancel();
          _items = [];
          _status = ShoppingListStatus.loaded;
          notifyListeners();
        }
      }
    });
  }

  void _subscribeToItems(String uid) {
    _itemsSub?.cancel();
    _status = ShoppingListStatus.loading;
    notifyListeners();

    _itemsSub = _repository.watchItems(uid).listen(
      (list) {
        _items = list;
        _status = ShoppingListStatus.loaded;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _status = ShoppingListStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> addIngredientsToShoppingList({
    required String recipeId,
    required String recipeName,
    required List<String> names,
    required List<String> amounts,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final List<ShoppingListItem> listItems = [];
    for (int i = 0; i < names.length; i++) {
      listItems.add(
        ShoppingListItem(
          id: '',
          name: names[i],
          amount: amounts[i],
          recipeId: recipeId,
          recipeName: recipeName,
          completed: false,
        ),
      );
    }
    await _repository.addItems(uid, listItems);
  }

  Future<void> toggleItemCompleted(String itemId, bool completed) async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.updateItemCompleted(uid, itemId, completed);
  }

  Future<void> deleteItem(String itemId) async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.deleteItem(uid, itemId);
  }

  Future<void> clearCompleted() async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.clearCompleted(uid);
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.clearAll(uid);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _itemsSub?.cancel();
    super.dispose();
  }
}
