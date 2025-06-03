import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/repositories/shopping_repository.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _itemsCollection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Usuario no autenticado; uid nulo');
    }
    // shopping_lists / <uid> / items
    return _db.collection('shopping_lists').doc(uid).collection('items');
  }

  @override
  Stream<List<ShoppingItem>> getPendingItems() {
    return _itemsCollection()
        .where('isBought', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map(
              (d) => ShoppingItem(
                id: d.id,
                name: d['name'] ?? '',
                quantity: d['quantity'] ?? 1,
                note: d['note'] ?? '',
                category: d['category'] ?? '',
                isBought: d['isBought'] ?? false,
                isRecurring: d['isRecurring'] ?? false,
                createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              ),
            )
            .toList());
  }

  @override
  Stream<List<ShoppingItem>> getPurchasedItems() {
    return _itemsCollection()
        .where('isBought', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(
              (d) => ShoppingItem(
                id: d.id,
                name: d['name'] ?? '',
                quantity: d['quantity'] ?? 1,
                note: d['note'] ?? '',
                category: d['category'] ?? '',
                isBought: d['isBought'] ?? false,
                isRecurring: d['isRecurring'] ?? false,
                createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              ),
            )
            .toList());
  }

  @override
  Future<void> addItem(ShoppingItem item) async {
    await _itemsCollection().add({
      'name': item.name,
      'quantity': item.quantity,
      'note': item.note,
      'category': item.category,
      'isBought': false,
      'isRecurring': item.isRecurring,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateItem(ShoppingItem item) {
    return _itemsCollection().doc(item.id).update({
      'name': item.name,
      'quantity': item.quantity,
      'note': item.note,
      'category': item.category,
      'isRecurring': item.isRecurring,
    });
  }

  @override
  Future<void> deleteItem(String id) {
    return _itemsCollection().doc(id).delete();
  }

  @override
  Future<void> toggleBought(String id) async {
    final doc = _itemsCollection().doc(id);
    final snap = await doc.get();
    final current = snap['isBought'] as bool? ?? false;
    await doc.update({'isBought': !current});
  }

  @override
  Future<void> toggleRecurring(String id) async {
    final doc = _itemsCollection().doc(id);
    final snap = await doc.get();
    final current = snap['isRecurring'] as bool? ?? false;
    await doc.update({'isRecurring': !current});
  }
}
