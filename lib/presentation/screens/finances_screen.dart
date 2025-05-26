import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/finance_entry_model.dart';
import '../../../data/repositories/finance_repository.dart';
import 'create_or_edit_finance_entry_screen.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  final FinanceRepository _repo = FinanceRepository();

  String _selectedType = 'todos';
  String _selectedMonth = 'todos';
  List<String> _availableMonths = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💸 Finanzas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Estadísticas',
            onPressed: () {
              Navigator.pushNamed(context, '/estadisticas-financieras');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateOrEditFinanceEntryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: StreamBuilder<List<FinanceEntryModel>>(
        stream: _repo.getEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return const Center(child: Text('No hay movimientos registrados'));
          }

          // Preparar meses únicos
          _availableMonths = entries
              .map((e) => DateFormat('MMMM yyyy', 'es_ES').format(e.date))
              .toSet()
              .toList()
            ..sort();

          // Filtro por tipo
          List<FinanceEntryModel> filtered = entries.where((e) {
            if (_selectedType != 'todos' && e.type != _selectedType) return false;
            if (_selectedMonth != 'todos') {
              final mes = DateFormat('MMMM yyyy', 'es_ES').format(e.date);
              if (mes != _selectedMonth) return false;
            }
            return true;
          }).toList();

          final totalIngresos = filtered
              .where((e) => e.type == 'ingreso')
              .fold(0.0, (sum, e) => sum + e.amount);
          final totalGastos = filtered
              .where((e) => e.type == 'gasto')
              .fold(0.0, (sum, e) => sum + e.amount);
          final balance = totalIngresos - totalGastos;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedType,
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedType = value);
                        },
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'ingreso', child: Text('Ingresos')),
                          DropdownMenuItem(value: 'gasto', child: Text('Gastos')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedMonth == 'todos' && _availableMonths.isNotEmpty
                            ? _availableMonths.last
                            : _selectedMonth,
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedMonth = value);
                        },
                        items: [
                          const DropdownMenuItem(value: 'todos', child: Text('Todos los meses')),
                          ..._availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💰 Ingresos: \$${totalIngresos.toStringAsFixed(2)}'),
                    Text('💸 Gastos: \$${totalGastos.toStringAsFixed(2)}'),
                    Text('🧾 Balance: \$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        )),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final isIncome = entry.type == 'ingreso';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text('${entry.category} - \$${entry.amount.toStringAsFixed(2)}'),
                        subtitle: Text('${entry.description} • ${DateFormat('dd/MM/yyyy').format(entry.date)}'),
                        trailing: entry.isRecurring
                            ? const Icon(Icons.repeat, color: Colors.indigo)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateOrEditFinanceEntryScreen(existing: entry),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
