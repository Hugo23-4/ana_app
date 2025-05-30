import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/shopping_notifier.dart';
import '../../domain/entities/shopping_item.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({Key? key}) : super(key: key);

  @override
  _ShoppingPageState createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Muestra el cuadro de diálogo para añadir o editar un artículo.
  Future<void> _showItemDialog(BuildContext context, [ShoppingItem? item]) async {
    final notifier = Provider.of<ShoppingNotifier>(context, listen: false);
    final TextEditingController nameController =
        TextEditingController(text: item?.name ?? '');
    final TextEditingController quantityController =
        TextEditingController(text: item != null ? item!.quantity.toString() : '1');
    final TextEditingController noteController =
        TextEditingController(text: item?.note ?? '');
    String category = item?.category ?? 'Otros';
    bool isRecurring = item?.isRecurring ?? false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(item == null ? 'Añadir artículo' : 'Editar artículo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                  ),
                  DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    items: ShoppingNotifier.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          category = val;
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Recurrente'),
                    value: isRecurring,
                    onChanged: (val) {
                      setState(() {
                        isRecurring = val ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              ElevatedButton(
                child: Text(item == null ? 'Añadir' : 'Guardar'),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final note = noteController.text.trim();
                  final qtyStr = quantityController.text.trim();
                  final quantity = int.tryParse(qtyStr) ?? 1;
                  if (name.isEmpty) {
                    // No permitir nombre vacío
                    return;
                  }
                  if (item == null) {
                    // Crear nuevo artículo
                    final newItem = ShoppingItem(
                      id: '', // se generará en el repositorio
                      name: name,
                      quantity: quantity,
                      note: note,
                      category: category,
                      isRecurring: isRecurring,
                    );
                    await notifier.addItem(newItem);
                  } else {
                    // Actualizar artículo existente
                    final updatedItem = ShoppingItem(
                      id: item.id,
                      name: name,
                      quantity: quantity,
                      note: note,
                      category: category,
                      isBought: item.isBought,
                      isRecurring: isRecurring,
                      createdAt: item.createdAt,
                    );
                    await notifier.updateItem(updatedItem);
                  }
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construcción de la AppBar con búsqueda y filtro
    final appBar = AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (query) {
                context.read<ShoppingNotifier>().setSearchQuery(query);
              },
            )
          : const Text('Lista de la compra'),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
              });
              // Limpiar búsqueda
              _searchController.clear();
              context.read<ShoppingNotifier>().setSearchQuery('');
            },
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) {
            context.read<ShoppingNotifier>().setCategoryFilter(value);
          },
          itemBuilder: (ctx) {
            // Opciones de filtro: "Todas" + cada categoría disponible
            final options = <String>[ShoppingNotifier.filterAll, ...ShoppingNotifier.categories];
            return options.map((cat) {
              return PopupMenuItem<String>(
                value: cat,
                child: Text(cat == ShoppingNotifier.filterAll ? 'Todas las categorías' : cat),
              );
            }).toList();
          },
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Consumer<ShoppingNotifier>(
        builder: (context, notifier, _) {
          if (notifier.isLoading) {
            // Mostrar indicador de carga mientras se obtienen los datos
            return const Center(child: CircularProgressIndicator());
          }
          final items = notifier.pendingItems;
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No hay artículos',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (ctx, index) {
              final item = items[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  // Eliminar elemento al hacer swipe
                  notifier.deleteItem(item.id);
                },
                child: ListTile(
                  leading: Checkbox(
                    value: item.isBought,
                    onChanged: (checked) {
                      if (checked != null) {
                        notifier.toggleItemBought(item.id);
                      }
                    },
                  ),
                  title: Text(
                    item.quantity > 1 ? '${item.name} x${item.quantity}' : item.name,
                    style: TextStyle(
                      decoration: item.isBought ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  subtitle: (item.note.isNotEmpty || item.category.isNotEmpty)
                      ? Text([
                          if (item.category.isNotEmpty) 'Categoría: ${item.category}',
                          if (item.note.isNotEmpty) 'Nota: ${item.note}'
                        ].join('   '))
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      Icons.autorenew,
                      color: item.isRecurring ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      notifier.toggleItemRecurring(item.id);
                    },
                    tooltip: item.isRecurring ? 'Marcar como no recurrente' : 'Marcar como recurrente',
                  ),
                  onTap: () {
                    // Editar el artículo al hacer tap
                    _showItemDialog(context, item);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showItemDialog(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Añadir artículo',
      ),
    );
  }
}
