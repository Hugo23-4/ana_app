import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/shopping/data/models/shopping_item_model.dart';
import '../../features/shopping/domain/repositories/shopping_repository.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final ShoppingRepository _repo = ShoppingRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧾 Historial de compras"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/estadisticas-compras');
        },
        icon: const Icon(Icons.bar_chart),
        label: const Text('Ver estadísticas'),
      ),
      body: StreamBuilder<List<ShoppingItemModel>>(
        stream: _repo.getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = (snapshot.data ?? [])
              .where((item) => item.isBought)
              .toList();

          if (items.isEmpty) {
            return const Center(child: Text("No hay compras registradas"));
          }

          // Agrupar por mes/año
          final Map<String, List<ShoppingItemModel>> grouped = {};

          for (var item in items) {
            final key = DateFormat('MMMM yyyy', 'es_ES').format(item.createdAt);
            grouped.putIfAbsent(key, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              final mes = entry.key;
              final productos = entry.value;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    mes,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${productos.length} productos comprados'),
                  children: productos.map((item) {
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(item.name),
                      subtitle: Text('Categoría: ${item.category}'),
                      trailing: item.isRecurring
                          ? const Icon(Icons.repeat, color: Colors.indigo)
                          : null,
                      onTap: () {
                        // 🔗 Aquí podrás vincular este producto con finanzas (más adelante)
                      },
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
