import '../repositories/shopping_repository.dart';

class ToggleShoppingItemRecurringUseCase {
  final ShoppingRepository _repository;
  ToggleShoppingItemRecurringUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.toggleRecurring(id);
  }
}
