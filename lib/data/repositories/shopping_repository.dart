import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/shopping_item_model.dart';

class ShoppingRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _shoppingRef => _firestore.collection('shopping_items');

  Stream<List<ShoppingItemModel>> getItems() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _shoppingRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ShoppingItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<ShoppingItemModel>> getItemsOnce() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _shoppingRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => ShoppingItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem(String name, String category) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newItem = ShoppingItemModel(
      id: '', // Firestore lo genera automáticamente
      name: name,
      category: category,
      isBought: false,
      isRecurring: false,
      createdAt: DateTime.now(),
      userId: user.uid,
    );

    await _shoppingRef.add(newItem.toMap());
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    await _shoppingRef.doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _shoppingRef.doc(id).delete();
  }

  Future<void> toggleIsBought(ShoppingItemModel item) async {
    await _shoppingRef.doc(item.id).update({'isBought': !item.isBought});
  }
}
