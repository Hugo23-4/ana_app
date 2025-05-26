import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/reminder_model.dart';

class ReminderRepository {
  final _db = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<ReminderModel>> getReminders() {
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReminderModel.fromFirestore(doc)).toList());
  }

  Future<void> addReminder(ReminderModel reminder) async {
    await _db.collection('reminders').add(reminder.toMap(userId));
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    await _db.collection('reminders').doc(reminder.id).update({
      'title': reminder.title,
      'description': reminder.description,
      'dateTime': Timestamp.fromDate(reminder.dateTime),
    });
  }

  Future<void> deleteReminder(String id) async {
    await _db.collection('reminders').doc(id).delete();
  }
}
