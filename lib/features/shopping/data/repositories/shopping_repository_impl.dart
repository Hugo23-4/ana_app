import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Referencia a la colección de artículos de compra del usuario actual en Firestore.
  CollectionReference<Map<String, dynamic>> get _shoppingCollection {
    final user = _auth.currentUser;
    final uid = user?.uid;
    // Si no hay usuario autenticado, apuntamos a una colección vacía ficticia
    if (uid == null) {
      return _firestore.collection('users').doc('guest').collection('shoppingItems');
    }
    return _firestore.collection('users').doc(uid).collection('shoppingItems');
  }

  @override
  Stream<List<ShoppingItem>> getPendingItems() {
    try {
      return _shoppingCollection
          .where('isBought', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map<ShoppingItem>((doc) => ShoppingItemModel.fromSnapshot(doc))
                .toList();
          });
    } catch (e) {
      // En caso de error, retornar stream vacío
      return Stream.value(<ShoppingItem>[]);
    }
  }

  @override
  Stream<List<ShoppingItem>> getPurchasedItems() {
    try {
      return _shoppingCollection
          .where('isBought', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map<ShoppingItem>((doc) => ShoppingItemModel.fromSnapshot(doc))
                .toList();
          });
    } catch (e) {
      return Stream.value(<ShoppingItem>[]);
    }
  }

  @override
  Future<void> addItem(ShoppingItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    // Generar nuevo ID de documento
    final docRef = _shoppingCollection.doc();
    final newId = docRef.id;
    // Crear modelo con el nuevo ID
    final newItemModel = ShoppingItemModel(
      id: newId,
      name: item.name,
      quantity: item.quantity,
      note: item.note,
      category: item.category,
      isBought: false,
      isRecurring: item.isRecurring,
      createdAt: item.createdAt,
    );
    await docRef.set(newItemModel.toMap());
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final docRef = _shoppingCollection.doc(item.id);
    final itemModel = ShoppingItemModel.fromEntity(item);
    await docRef.update(itemModel.toMap());
  }

  @override
  Future<void> deleteItem(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final docRef = _shoppingCollection.doc(id);
    await docRef.delete();
  }

  @override
  Future<void> toggleBought(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final docRef = _shoppingCollection.doc(id);
    // Obtener el estado actual y actualizar al contrario
    final snapshot = await docRef.get();
    final currentStatus = (snapshot.data()?['isBought'] ?? false) as bool;
    await docRef.update({'isBought': !currentStatus});
  }

  @override
  Future<void> toggleRecurring(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final docRef = _shoppingCollection.doc(id);
    final snapshot = await docRef.get();
    final currentStatus = (snapshot.data()?['isRecurring'] ?? false) as bool;
    await docRef.update({'isRecurring': !currentStatus});
  }
}
