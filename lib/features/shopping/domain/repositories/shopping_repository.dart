import '../entities/shopping_item.dart';

abstract class ShoppingRepository {
  Stream<List<ShoppingItem>> getPendingItems();
  Stream<List<ShoppingItem>> getPurchasedItems();
  Future<void> addItem(ShoppingItem item);
  Future<void> updateItem(ShoppingItem item);
  Future<void> deleteItem(String id);
  Future<void> toggleBought(String id);
  Future<void> toggleRecurring(String id);
}
