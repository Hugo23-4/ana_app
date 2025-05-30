import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/usecases/add_shopping_item_usecase.dart';
import '../../domain/usecases/get_shopping_items_usecase.dart';
import '../../domain/usecases/get_purchased_items_usecase.dart';
import '../../domain/usecases/delete_shopping_item_usecase.dart';
import '../../domain/usecases/update_shopping_item_usecase.dart';
import '../../domain/usecases/toggle_shopping_item_bought_usecase.dart';
import '../../domain/usecases/toggle_shopping_item_recurring_usecase.dart';

class ShoppingNotifier extends ChangeNotifier {
  // Casos de uso (inyección de dependencias)
  final GetShoppingItemsUseCase _getShoppingItems;
  final GetPurchasedItemsUseCase _getPurchasedItems;
  final AddShoppingItemUseCase _addShoppingItem;
  final UpdateShoppingItemUseCase _updateShoppingItem;
  final DeleteShoppingItemUseCase _deleteShoppingItem;
  final ToggleShoppingItemBoughtUseCase _toggleBought;
  final ToggleShoppingItemRecurringUseCase _toggleRecurring;

  // Estado interno
  List<ShoppingItem> _pendingItems = [];
  List<ShoppingItem> _purchasedItems = [];
  List<ShoppingItem> _filteredPendingItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = filterAll;

  // Suscripciones a streams
  late final StreamSubscription<List<ShoppingItem>> _pendingSub;
  late final StreamSubscription<List<ShoppingItem>> _purchasedSub;

  // Lista de categorías disponibles (sin incluir 'Todas')
  static const List<String> categories = [
    'Alimentación',
    'Hogar',
    'Tecnología',
    'Personal',
    'Otros',
  ];

  // Constante para representar "todas las categorías"
  static const String filterAll = 'Todas';

  ShoppingNotifier({
    required GetShoppingItemsUseCase getShoppingItemsUseCase,
    required GetPurchasedItemsUseCase getPurchasedItemsUseCase,
    required AddShoppingItemUseCase addShoppingItemUseCase,
    required UpdateShoppingItemUseCase updateShoppingItemUseCase,
    required DeleteShoppingItemUseCase deleteShoppingItemUseCase,
    required ToggleShoppingItemBoughtUseCase toggleShoppingItemBoughtUseCase,
    required ToggleShoppingItemRecurringUseCase toggleShoppingItemRecurringUseCase,
  })  : _getShoppingItems = getShoppingItemsUseCase,
        _getPurchasedItems = getPurchasedItemsUseCase,
        _addShoppingItem = addShoppingItemUseCase,
        _updateShoppingItem = updateShoppingItemUseCase,
        _deleteShoppingItem = deleteShoppingItemUseCase,
        _toggleBought = toggleShoppingItemBoughtUseCase,
        _toggleRecurring = toggleShoppingItemRecurringUseCase {
    // Suscribirse a los streams de items pendientes y comprados
    _pendingSub = _getShoppingItems().listen((items) {
      _pendingItems = items;
      if (_isLoading) _isLoading = false;
      _applyFilters();
    }, onError: (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al obtener la lista de compras: $error');
    });

    _purchasedSub = _getPurchasedItems().listen((items) {
      _purchasedItems = items;
      // Notificar cambios en comprados (para actualizar historial/estadísticas)
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error al obtener el historial de compras: $error');
    });
  }

  // Getters para exponer el estado
  List<ShoppingItem> get pendingItems =>
      _selectedCategory == filterAll && _searchQuery.isEmpty
          ? _pendingItems
          : _filteredPendingItems;
  List<ShoppingItem> get purchasedItems => _purchasedItems;
  bool get isLoading => _isLoading;
  String get selectedCategoryFilter => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Aplicar filtros de búsqueda y categoría sobre _pendingItems
  void _applyFilters() {
    if (_searchQuery.isEmpty && (_selectedCategory == filterAll)) {
      // Sin filtros: lista completa
      _filteredPendingItems = List.from(_pendingItems);
    } else {
      _filteredPendingItems = _pendingItems.where((item) {
        final query = _searchQuery;
        final matchesSearch = query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.note.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == filterAll ||
            item.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    }
    notifyListeners();
  }

  // Métodos públicos para acciones
  Future<void> addItem(ShoppingItem item) async {
    try {
      await _addShoppingItem(item);
    } catch (e) {
      debugPrint('Error al añadir artículo: $e');
    }
    // (La lista se actualiza automáticamente por el stream)
  }

  Future<void> updateItem(ShoppingItem item) async {
    try {
      await _updateShoppingItem(item);
    } catch (e) {
      debugPrint('Error al actualizar artículo: $e');
    }
    // La actualización se reflejará en el stream pendiente
  }

  Future<void> deleteItem(String id) async {
    try {
      await _deleteShoppingItem(id);
    } catch (e) {
      debugPrint('Error al eliminar artículo: $e');
    }
    // La eliminación se reflejará automáticamente en la lista
  }

  Future<void> toggleItemBought(String id) async {
    try {
      await _toggleBought(id);
    } catch (e) {
      debugPrint('Error al marcar como comprado: $e');
    }
    // El cambio se reflejará mediante los streams (pasará de pendientes a historial)
  }

  Future<void> toggleItemRecurring(String id) async {
    try {
      await _toggleRecurring(id);
    } catch (e) {
      debugPrint('Error al cambiar recurrencia: $e');
    }
    // El cambio se reflejará en el stream pendiente
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  @override
  void dispose() {
    _pendingSub.cancel();
    _purchasedSub.cancel();
    super.dispose();
  }
}
