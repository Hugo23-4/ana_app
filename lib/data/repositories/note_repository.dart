import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/note_model.dart';

class NoteRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<NoteModel>> getNotes() {
    return _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList());
  }

  Future<void> addNote(String content) async {
    await _db.collection('notes').add({
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }
}
