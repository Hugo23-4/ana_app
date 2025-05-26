import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;

  ReminderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }
}
