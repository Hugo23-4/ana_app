import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/shopping_item.dart';
import '../notifiers/shopping_notifier.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  bool _searchMode = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showEditor([ShoppingItem? item]) async {
    final notifier = context.read<ShoppingNotifier>();
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final qtyCtrl =
        TextEditingController(text: item?.quantity.toString() ?? '1');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    String category = item?.category ?? 'Otros';
    bool recurring = item?.isRecurring ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Añadir artículo' : 'Editar artículo'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Nota')),
              DropdownButton<String>(
                  isExpanded: true,
                  value: category,
                  items: ['Alimentación', 'Hogar', 'Tecnología', 'Personal', 'Otros']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (c) => setState(() => category = c ?? 'Otros')),
              CheckboxListTile(
                value: recurring,
                onChanged: (v) => setState(() => recurring = v ?? false),
                title: const Text('Recurrente'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              if (item == null) {
                notifier.addItem(ShoppingItem(
                  id: '',
                  name: name,
                  quantity: qty,
                  note: noteCtrl.text.trim(),
                  category: category,
                  isRecurring: recurring,
                ));
              } else {
                notifier.updateItem(ShoppingItem(
                  id: item.id,
                  name: name,
                  quantity: qty,
                  note: noteCtrl.text.trim(),
                  category: category,
                  isBought: item.isBought,
                  isRecurring: recurring,
                  createdAt: item.createdAt,
                ));
              }
              Navigator.pop(ctx);
            },
            child: Text(item == null ? 'Añadir' : 'Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ShoppingNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Buscar...'),
                onChanged: notifier.setSearchQuery,
              )
            : const Text('Lista de la compra'),
        actions: [
          IconButton(
              icon: Icon(_searchMode ? Icons.close : Icons.search),
              onPressed: () {
                setState(() => _searchMode = !_searchMode);
                if (!_searchMode) notifier.setSearchQuery('');
              }),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: notifier.selectedCategoryFilter,
            onSelected: notifier.setCategoryFilter,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'Todas', child: Text('Todas')),
              ...ShoppingNotifier.categories
                  .map((c) => PopupMenuItem(value: c, child: Text(c)))
            ],
          )
        ],
      ),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifier.pendingItems.isEmpty
              ? const Center(child: Text('No hay artículos'))
              : ListView.builder(
                  itemCount: notifier.pendingItems.length,
                  itemBuilder: (_, i) {
                    final item = notifier.pendingItems[i];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => notifier.deleteItem(item.id),
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isBought,
                          onChanged: (_) => notifier.toggleItemBought(item.id),
                        ),
                        title: Text(
                          item.quantity > 1
                              ? '${item.name} x${item.quantity}'
                              : item.name,
                          style: TextStyle(
                            decoration: item.isBought
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: item.note.isNotEmpty ? Text(item.note) : null,
                        trailing: IconButton(
                          icon: Icon(
                            Icons.autorenew,
                            color: item.isRecurring ? Colors.green : Colors.grey,
                          ),
                          onPressed: () =>
                              notifier.toggleItemRecurring(item.id),
                        ),
                        onTap: () => _showEditor(item),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
