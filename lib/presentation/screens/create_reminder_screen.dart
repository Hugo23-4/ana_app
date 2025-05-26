import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  Duration _notifyBefore = const Duration(minutes: 0);

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _scheduleReminder() {
    final String title = _titleController.text.trim();
    final String desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título no puede estar vacío")),
      );
      return;
    }

    final DateTime notifyTime = _selectedDateTime.subtract(_notifyBefore);

    NotificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: desc,
      scheduledTime: notifyTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Recordatorio programado')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
    DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Crear recordatorio'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Fecha y hora'),
                subtitle: Text(formattedDate),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Duration>(
                decoration: const InputDecoration(labelText: 'Notificar antes de...'),
                value: _notifyBefore,
                items: const [
                  DropdownMenuItem(value: Duration(minutes: 0), child: Text('En el momento')),
                  DropdownMenuItem(value: Duration(minutes: 5), child: Text('5 minutos antes')),
                  DropdownMenuItem(value: Duration(minutes: 15), child: Text('15 minutos antes')),
                  DropdownMenuItem(value: Duration(hours: 1), child: Text('1 hora antes')),
                  DropdownMenuItem(value: Duration(days: 1), child: Text('1 día antes')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _notifyBefore = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _scheduleReminder,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Programar recordatorio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
