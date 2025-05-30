import '../repositories/shopping_repository.dart';

class ToggleShoppingItemBoughtUseCase {
  final ShoppingRepository _repository;
  ToggleShoppingItemBoughtUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.toggleBought(id);
  }
}
