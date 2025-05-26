import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/finance_entry_model.dart';

class FinanceRepository {
  final _db = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  Stream<List<FinanceEntryModel>> getEntries() {
    return _db
        .collection('finanzas')
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinanceEntryModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addEntry(FinanceEntryModel entry) async {
    await _db.collection('finanzas').add(entry.toMap());
  }

  Future<void> deleteEntry(String id) async {
    await _db.collection('finanzas').doc(id).delete();
  }

  Future<void> updateEntry(String id, FinanceEntryModel entry) async {
    await _db.collection('finanzas').doc(id).update(entry.toMap());
  }
}
