import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskRepository _taskRepo = TaskRepository();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  void _showTaskDialog({TaskModel? task}) {
    final isEditing = task != null;
    if (isEditing) {
      _titleController.text = task.title;
      _descController.text = task.description;
    } else {
      _titleController.clear();
      _descController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Editar tarea' : 'Nueva tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
            onPressed: () async {
              final title = _titleController.text.trim();
              final desc = _descController.text.trim();
              if (title.isEmpty) return;

              if (isEditing) {
                await _taskRepo.updateTask(TaskModel(
                  id: task!.id,
                  title: title,
                  description: desc,
                  completed: task.completed,
                  createdAt: task.createdAt,
                ));
              } else {
                await _taskRepo.addTask(title, desc);
              }

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar tarea?'),
        content: Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _taskRepo.deleteTask(task.id);
              Navigator.pop(context);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskRepo.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(child: Text('No hay tareas. Añade una ➕'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final task = tasks[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      task.completed ? Icons.check_circle : Icons.circle_outlined,
                      color: task.completed ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      final updated = TaskModel(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        completed: !task.completed,
                        createdAt: task.createdAt,
                      );
                      _taskRepo.updateTask(updated);
                    },
                  ),
                  title: Text(task.title,
                      style: TextStyle(
                          decoration: task.completed ? TextDecoration.lineThrough : null)),
                  subtitle: Text(task.description),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showTaskDialog(task: task);
                      } else if (value == 'delete') {
                        _confirmDelete(task);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
