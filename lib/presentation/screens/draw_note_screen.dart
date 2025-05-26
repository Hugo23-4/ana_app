import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DrawNoteScreen extends StatefulWidget {
  const DrawNoteScreen({super.key});

  @override
  State<DrawNoteScreen> createState() => _DrawNoteScreenState();
}

class _DrawNoteScreenState extends State<DrawNoteScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

Future<void> _saveDrawing() async {
  if (_controller.isNotEmpty) {
    try {
      final Uint8List? data = await _controller.toPngBytes();

      if (data != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final fileName = 'draw_${DateTime.now().millisecondsSinceEpoch}.png';

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('notes')
            .child(userId)
            .child(fileName);

        // Subir la imagen a Firebase Storage
        await storageRef.putData(data);

        // Obtener la URL pública de la imagen
        final imageUrl = await storageRef.getDownloadURL();

        // Guardar la nota en Firestore
        await FirebaseFirestore.instance.collection('notes').add({
          'userId': userId,
          'content': '',
          'imageUrl': imageUrl,
          'type': 'draw',
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dibujo guardado correctamente')),
        );

        Navigator.pop(context); // Volver a la pantalla anterior
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el dibujo: $e')),
      );
    }
  }
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() => _controller.clear();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dibujo rápido'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDrawing,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clear,
          ),
        ],
      ),
      body: Signature(
        controller: _controller,
        backgroundColor: Colors.grey[200]!,
      ),
    );
  }
}
