import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import 'calendar_year_view.dart';

class CalendarScreen extends StatefulWidget {
  final DateTime? initialFocusedDay;
  const CalendarScreen({super.key, this.initialFocusedDay});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventRepository _eventRepo = EventRepository();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<EventModel>> _eventsMap = {};
  List<EventModel> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    _eventRepo.getEvents().listen((allEvents) {
      final Map<DateTime, List<EventModel>> map = {};
      for (final event in allEvents) {
        final eventDate = DateTime.utc(event.date.year, event.date.month, event.date.day);
        map.putIfAbsent(eventDate, () => []);
        map[eventDate]!.add(event);
      }
      setState(() {
        _eventsMap = map;
        _selectedEvents = _getEventsForDay(_selectedDay);
      });
    });
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _eventsMap[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
  }

  void _showEventDialog({EventModel? event}) {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descController = TextEditingController(text: event?.description ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Editar evento' : 'Nuevo evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Título')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              if (title.isEmpty) return;

              if (isEditing) {
                await _eventRepo.updateEvent(event!.copyWith(title: title, description: desc));
              } else {
                await _eventRepo.addEvent(title, desc, _selectedDay);
              }

              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(EventModel event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar evento?'),
        content: Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _eventRepo.deleteEvent(event.id);
              Navigator.pop(context);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
      _selectedEvents = _getEventsForDay(DateTime.now());
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
    });
  }

  void _goToYearView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CalendarYearView()),
    );
  }

  void _showBottomMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.event),
              title: Text('➕ Crear evento'),
              onTap: () {
                Navigator.pop(context);
                _showEventDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.task),
              title: Text('📝 Crear tarea'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tareas');
              },
            ),
            ListTile(
              leading: Icon(Icons.note_add),
              title: Text('🗒️ Crear nota'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notas');
              },
            ),
            ListTile(
              leading: Icon(Icons.brush),
              title: Text('🎨 Nota dibujada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/nota-dibujada');
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_active),
              title: Text('🔔 Crear recordatorio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/crear-recordatorio');
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('📋 Ver recordatorios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ver-recordatorios');
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('✏️ Editar contenido'),
              onTap: () {
                Navigator.pop(context);
                // Aquí puedes implementar navegación futura
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat.yMMMM('es_ES').format(_focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.today), tooltip: 'Hoy', onPressed: _goToToday),
          IconButton(icon: Icon(Icons.grid_view), tooltip: 'Vista anual', onPressed: _goToYearView),
          PopupMenuButton<CalendarFormat>(
            icon: Icon(Icons.calendar_view_month),
            onSelected: (format) => setState(() => _calendarFormat = format),
            itemBuilder: (context) => [
              PopupMenuItem(value: CalendarFormat.month, child: Text('Mes')),
              PopupMenuItem(value: CalendarFormat.week, child: Text('Semana')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Text(currentMonth, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
          TableCalendar<EventModel>(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('No hay eventos para este día'))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _selectedEvents.length,
              itemBuilder: (_, index) {
                final event = _selectedEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.description),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEventDialog(event: event);
                        } else if (value == 'delete') {
                          _confirmDelete(event);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomMenu,
        child: const Icon(Icons.add),
        tooltip: '➕ Menú de acciones',
      ),
    );
  }
}
