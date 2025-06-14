import '../entities/shopping_item.dart';
import '../repositories/shopping_repository.dart';

class AddShoppingItemUseCase {
  final ShoppingRepository _repository;
  AddShoppingItemUseCase(this._repository);

  Future<void> call(ShoppingItem item) {
    return _repository.addItem(item);
  }
}
