import '../entities/shopping_item.dart';
import '../repositories/shopping_repository.dart';

class UpdateShoppingItemUseCase {
  final ShoppingRepository _repository;
  UpdateShoppingItemUseCase(this._repository);

  Future<void> call(ShoppingItem item) {
    return _repository.updateItem(item);
  }
}
