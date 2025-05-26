import 'package:flutter/material.dart';
import '../../../core/models/note_model.dart';
import '../../../data/repositories/note_repository.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteRepository _noteRepo = NoteRepository();
  final TextEditingController _controller = TextEditingController();

  void _addNoteDialog() {
    _controller.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nueva nota'),
        content: TextField(
          controller: _controller,
          maxLines: 5,
          decoration: InputDecoration(hintText: 'Escribe tu nota...'),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Guardar'),
            onPressed: () async {
              final content = _controller.text.trim();
              if (content.isNotEmpty) {
                await _noteRepo.addNote(content);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar nota?'),
        content: Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _noteRepo.deleteNote(id);
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
      body: StreamBuilder<List<NoteModel>>(
        stream: _noteRepo.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(child: Text('No hay notas. Añade una 📝'));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (_, index) {
              final note = notes[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                contentPadding: EdgeInsets.all(12),
                title: note.type == 'draw'
                  ? Image.network(note.imageUrl ?? '', fit: BoxFit.cover)
                  : Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    note.createdAt.toDate().toLocal().toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _confirmDelete(note.id),
                      ),
                    ),
                  );
                  
            },
          );
        },
      ),
    );
  }
  floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    FloatingActionButton(
      heroTag: 'textNote',
      onPressed: _addNoteDialog,
      child: Icon(Icons.note_add),
      tooltip: 'Nota de texto',
    ),
    SizedBox(height: 12),
    FloatingActionButton(
      heroTag: 'drawNote',
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const DrawNoteScreen(),
        ));
      },
      child: Icon(Icons.brush),
      tooltip: 'Dibujar nota',
    ),
  ],
),
};
