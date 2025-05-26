import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/shopping_item_model.dart';
import '../../../data/repositories/shopping_repository.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final ShoppingRepository _repo = ShoppingRepository();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedCategory = 'Todas';
  String _searchQuery = '';

  final List<String> _categories = [
    'Todas',
    'Comida',
    'Ropa',
    'Hogar',
    'Tecnología',
    'Accesorios',
    'Otros'
  ];

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Añadir producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre del producto'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory == 'Todas' ? 'Comida' : _selectedCategory,
              items: _categories
                  .where((cat) => cat != 'Todas')
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
              decoration: InputDecoration(labelText: 'Categoría'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              await _repo.addItem(name, _selectedCategory == 'Todas' ? 'Comida' : _selectedCategory);
              _nameController.clear();
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ShoppingItemModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar producto'),
        content: Text('¿Seguro que deseas eliminar "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _repo.deleteItem(item.id);
              Navigator.pop(context);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Icon _categoryIcon(String category) {
    switch (category) {
      case 'Comida': return Icon(Icons.fastfood, color: Colors.orange);
      case 'Ropa': return Icon(Icons.shopping_bag, color: Colors.purple);
      case 'Hogar': return Icon(Icons.chair, color: Colors.blueGrey);
      case 'Tecnología': return Icon(Icons.devices, color: Colors.blue);
      case 'Accesorios': return Icon(Icons.watch, color: Colors.teal);
      default: return Icon(Icons.category, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛒 Lista de la compra'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddDialog,
            tooltip: 'Añadir producto',
          )
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history),
          tooltip: 'Historial de compras',
          onPressed: () {
            Navigator.pushNamed(context, '/historial-compras');
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar producto...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: 'Filtrar por categoría'),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: StreamBuilder<List<ShoppingItemModel>>(
              stream: _repo.getItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                var items = snapshot.data ?? [];

                // 🔍 Búsqueda
                if (_searchQuery.isNotEmpty) {
                  items = items
                      .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                // 🗂️ Filtro por categoría
                if (_selectedCategory != 'Todas') {
                  items = items.where((e) => e.category == _selectedCategory).toList();
                }

                if (items.isEmpty) {
                  return Center(child: Text('No se encontraron productos'));
                }

                final grouped = <String, List<ShoppingItemModel>>{};
                for (var item in items) {
                  grouped[item.category] = grouped[item.category] ?? [];
                  grouped[item.category]!.add(item);
                }

                return ListView(
                  padding: EdgeInsets.only(bottom: 16),
                  children: grouped.entries.map((entry) {
                    final category = entry.key;
                    final categoryItems = entry.value;

                    final pending = categoryItems.where((e) => !e.isBought).toList();
                    final bought = categoryItems.where((e) => e.isBought).toList();

                    return ExpansionTile(
                      title: Row(
                        children: [
                          _categoryIcon(category),
                          SizedBox(width: 8),
                          Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      initiallyExpanded: true,
                      children: [
                        ...pending.map((item) => _buildItemTile(item)).toList(),
                        if (bought.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text('✔ Comprado',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ...bought.map((item) => _buildItemTile(item)).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(ShoppingItemModel item) {
  return Dismissible(
    key: Key(item.id),
    direction: DismissDirection.horizontal,
    background: Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 20),
      color: Colors.green,
      child: Icon(Icons.check, color: Colors.white),
    ),
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20),
      color: Colors.orange,
      child: Icon(Icons.undo, color: Colors.white),
    ),
    confirmDismiss: (_) async {
      await _repo.toggleBought(item);
      return false; // Para no eliminarlo
    },
    child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: item.isBought ? Colors.green.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(
          item.isBought ? Icons.check_circle : Icons.radio_button_unchecked,
          color: item.isBought ? Colors.green : Colors.grey,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isBought ? TextDecoration.lineThrough : null,
            color: item.isBought ? Colors.grey : null,
          ),
        ),
        subtitle: Text('Añadido el ${DateFormat('dd/MM/yyyy').format(item.createdAt)}'),
        trailing: Icon(Icons.drag_handle),
        onTap: () => _showItemOptions(item),
      ),
    ),
  );
}

  void _showItemOptions(ShoppingItemModel item) {
  final nameController = TextEditingController(text: item.name);
  String selectedCategory = item.category;

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(item.isRecurring ? Icons.repeat_on : Icons.repeat),
            title: Text(item.isRecurring ? '❌ Quitar como recurrente' : '🔁 Marcar como recurrente'),
            onTap: () async {
              Navigator.pop(context);
              await _repo.toggleRecurring(item);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('✏️ Editar'),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(item, nameController, selectedCategory);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('🗑️ Eliminar'),
            onTap: () async {
              Navigator.pop(context);
              _confirmDelete(item);
            },
          ),
        ],
      ),
    ),
  );
}

void _showEditDialog(ShoppingItemModel item, TextEditingController nameController, String selectedCategory) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Editar producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Nombre del producto'),
          ),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            items: _categories
                .where((cat) => cat != 'Todas')
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (value) {
              if (value != null) selectedCategory = value;
            },
            decoration: InputDecoration(labelText: 'Categoría'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final updated = item.copyWith(
              name: nameController.text.trim(),
              category: selectedCategory,
            );
            await _repo.deleteItem(item.id); // 🔁 eliminar viejo
            await _repo.addItem(updated.name, updated.category); // 💾 agregar actualizado
            Navigator.pop(context);
          },
          child: Text('Guardar'),
        ),
      ],
    ),
  );
}
}
