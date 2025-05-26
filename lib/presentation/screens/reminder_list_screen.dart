import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/reminder_model.dart';
import '../../../data/repositories/reminder_repository.dart';
import '../../../core/services/notification_service.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  final ReminderRepository _repo = ReminderRepository();

  void _editReminder(ReminderModel reminder) {
    final titleController = TextEditingController(text: reminder.title);
    final descController = TextEditingController(text: reminder.description);
    DateTime selectedDateTime = reminder.dateTime;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar recordatorio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Título')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Fecha y hora'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime)),
              trailing: Icon(Icons.edit),
              onTap: () async {
                final DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date == null) return;
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                );
                if (time == null) return;

                setState(() {
                  selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final updated = ReminderModel(
                id: reminder.id,
                title: titleController.text,
                description: descController.text,
                dateTime: selectedDateTime,
              );
              await _repo.updateReminder(updated);

              // Reprogramar notificación
              await NotificationService.scheduleNotification(
                id: updated.id.hashCode,
                title: updated.title,
                body: updated.description,
                scheduledTime: updated.dateTime,
              );

              Navigator.pop(context);
            },
            child: Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _deleteReminder(ReminderModel reminder) async {
    await _repo.deleteReminder(reminder.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ Recordatorio eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 Recordatorios'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ReminderModel>>(
        stream: _repo.getReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty)
            return Center(child: Text('No hay recordatorios programados'));

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (_, index) {
              final reminder = reminders[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(reminder.title),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(reminder.dateTime)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editReminder(reminder);
                      if (value == 'delete') _deleteReminder(reminder);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('✏️ Editar')),
                      PopupMenuItem(value: 'delete', child: Text('🗑️ Eliminar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
