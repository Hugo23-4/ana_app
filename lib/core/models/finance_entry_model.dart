class FinanceEntryModel {
  final String id;
  final String userId;
  final String type; // "ingreso" o "gasto"
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final bool isRecurring;
  final String? recurrence; // "mensual", "semanal", "anual"
  final DateTime createdAt;

  FinanceEntryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.isRecurring,
    required this.recurrence,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring,
      'recurrence': recurrence,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FinanceEntryModel.fromMap(String id, Map<String, dynamic> map) {
    return FinanceEntryModel(
      id: id,
      userId: map['userId'],
      type: map['type'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      date: DateTime.parse(map['date']),
      isRecurring: map['isRecurring'] ?? false,
      recurrence: map['recurrence'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
