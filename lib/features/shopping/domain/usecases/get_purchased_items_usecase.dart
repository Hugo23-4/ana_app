import 'dart:async';
import '../entities/shopping_item.dart';
import '../repositories/shopping_repository.dart';

class GetPurchasedItemsUseCase {
  final ShoppingRepository _repository;
  GetPurchasedItemsUseCase(this._repository);

  Stream<List<ShoppingItem>> call() {
    return _repository.getPurchasedItems();
  }
}
