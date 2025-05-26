import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<EventModel>> getEvents() {
    return _db
        .collection('events')
        .where('userId', isEqualTo: userId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Future<void> addEvent(String title, String description, DateTime date) async {
    await _db.collection('events').add({
      'userId': userId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  Future<void> updateEvent(EventModel event) async {
    await _db.collection('events').doc(event.id).update({
      'title': event.title,
      'description': event.description,
      'date': Timestamp.fromDate(event.date),
    });
  }
}
