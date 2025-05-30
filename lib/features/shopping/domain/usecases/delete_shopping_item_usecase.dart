import '../repositories/shopping_repository.dart';

class DeleteShoppingItemUseCase {
  final ShoppingRepository _repository;
  DeleteShoppingItemUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteItem(id);
  }
}
