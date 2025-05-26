import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/models/shopping_item_model.dart';
import '../../core/models/task_model.dart';
import '../../data/repositories/shopping_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../core/models/event_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShoppingRepository _shoppingRepo = ShoppingRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final FinanceRepository _financeRepo = FinanceRepository();
  final EventRepository _eventRepo = EventRepository();

  int tasksToday = 0;
  int tasksDone = 0;
  int purchasesDone = 0;
  int purchasesPending = 0;
  double ingresos = 0;
  double gastos = 0;
  List<EventModel> todayEvents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final allTasks = await _taskRepo.getTasksOnce();
      final allItems = await _shoppingRepo.getItemsOnce();
      final allFinance = await _financeRepo.getEntriesOnce();
      final allEvents = await _eventRepo.getEventsOnce();

      final today = DateTime.now();
      final formattedToday = DateFormat('yyyy-MM-dd').format(today);

      final filteredTasks = allTasks.where((t) =>
          DateFormat('yyyy-MM-dd').format(t.dueDate) == formattedToday);
      final filteredEvents = allEvents.where((e) =>
          DateFormat('yyyy-MM-dd').format(e.date) == formattedToday);

      double ingresosTotal = 0;
      double gastosTotal = 0;

      for (var e in allFinance) {
        if (DateFormat('MMMM yyyy', 'es_ES').format(e.date) ==
            DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now())) {
          if (e.type == 'ingreso') ingresosTotal += e.amount;
          if (e.type == 'gasto') gastosTotal += e.amount;
        }
      }

      setState(() {
        tasksToday = filteredTasks.length;
        tasksDone = allTasks.where((t) => t.isCompleted).length;
        purchasesDone = allItems.where((i) => i.isBought).length;
        purchasesPending = allItems.where((i) => !i.isBought).length;
        ingresos = ingresosTotal;
        gastos = gastosTotal;
        todayEvents = filteredEvents.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar los datos")),
      );
    }
  }

  void _showBottomMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
              leading: const Icon(Icons.event),
              title: const Text('➕ Crear evento'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/calendario');
              }),
          ListTile(
              leading: const Icon(Icons.task),
              title: const Text('➕ Crear tarea'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tareas');
              }),
          ListTile(
              leading: const Icon(Icons.note),
              title: const Text('📝 Añadir nota'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notas');
              }),
          ListTile(
              leading: const Icon(Icons.brush),
              title: const Text('🎨 Nota dibujada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/nota-dibujada');
              }),
          ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('🔔 Crear recordatorio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/crear-recordatorio');
              }),
          ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('✏️ Editar contenido'),
              onTap: () {
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, IconData icon, int done, int total,
      {Color? color}) {
    final percent = total == 0 ? 0.0 : (done / total);
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color ?? Colors.indigo,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: LinearProgressIndicator(
          value: percent,
          color: color ?? Colors.indigo,
          backgroundColor: Colors.grey[300],
        ),
        trailing: Text("$done / $total"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Usuario";

    return Scaffold(
      appBar: AppBar(
        title: const Text('📌 Panel Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomMenu,
        child: const Icon(Icons.add),
        tooltip: 'Menú de acciones',
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hola, $userEmail 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (todayEvents.isNotEmpty)
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Tienes eventos hoy'),
                  subtitle: Text(todayEvents.map((e) => e.title).join(', ')),
                ),
              ),
            if (tasksToday > 0)
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.task),
                  title: const Text('Tareas para hoy'),
                  subtitle: Text('$tasksToday tarea(s) pendiente(s)'),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              '📈 Progreso general',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildProgressCard('Tareas completadas', Icons.check_circle,
                tasksDone, tasksDone + tasksToday),
            _buildProgressCard('Compras realizadas', Icons.shopping_cart,
                purchasesDone, purchasesDone + purchasesPending),
            _buildProgressCard('Balance mensual', Icons.paid,
                ingresos.round(), (ingresos + gastos).round(),
                color: Colors.teal),
            const SizedBox(height: 24),
            Text(
              '⚡ Accesos rápidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _quickAccess('📅 Calendario', Icons.calendar_today, '/calendario'),
                _quickAccess('📋 Tareas', Icons.checklist, '/tareas'),
                _quickAccess('📝 Notas', Icons.notes, '/notas'),
                _quickAccess('🛒 Compras', Icons.shopping_bag, '/compras'),
                _quickAccess('💰 Finanzas', Icons.account_balance_wallet, '/finanzas'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _quickAccess(String label, IconData icon, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.indigo[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  floatingActionButton: FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/asistente-voz'),
  child: Icon(Icons.mic),
  tooltip: 'Asistente de voz Ana',
  ),
}
