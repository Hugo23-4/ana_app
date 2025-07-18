import 'dart:async';
import '../entities/shopping_item.dart';
import '../repositories/shopping_repository.dart';

class GetShoppingItemsUseCase {
  final ShoppingRepository _repository;
  GetShoppingItemsUseCase(this._repository);

  Stream<List<ShoppingItem>> call() {
    return _repository.getPendingItems();
  }
}
