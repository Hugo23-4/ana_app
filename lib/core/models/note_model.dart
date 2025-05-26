import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String content;
  final Timestamp createdAt;
  final String? imageUrl;
  final String type; // "text" o "draw"

  NoteModel({
    required this.id,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    required this.type,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'],
      type: data['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'type': type,
    };
  }
}
