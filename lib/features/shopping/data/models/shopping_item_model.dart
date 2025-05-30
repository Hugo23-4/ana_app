import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shopping_item.dart';

class ShoppingItemModel extends ShoppingItem {
  ShoppingItemModel({
    required String id,
    required String name,
    required int quantity,
    String note = '',
    String category = 'Otros',
    bool isBought = false,
    bool isRecurring = false,
    required DateTime createdAt,
  }) : super(
          id: id,
          name: name,
          quantity: quantity,
          note: note,
          category: category,
          isBought: isBought,
          isRecurring: isRecurring,
          createdAt: createdAt,
        );

  /// Crea un [ShoppingItemModel] a partir de un [DocumentSnapshot] de Firestore.
  factory ShoppingItemModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; 
    final map = data ?? <String, dynamic>{};
    return ShoppingItemModel(
      id: doc.id,
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 1) is int ? map['quantity'] : int.tryParse(map['quantity'].toString()) ?? 1,
      note: map['note'] ?? '',
      category: map['category'] ?? 'Otros',
      isBought: map['isBought'] ?? false,
      isRecurring: map['isRecurring'] ?? false,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : (map['createdAt'] ?? DateTime.now()),
    );
  }

  /// Crea un [ShoppingItemModel] desde un [ShoppingItem] de dominio.
  factory ShoppingItemModel.fromEntity(ShoppingItem item) {
    return ShoppingItemModel(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      note: item.note,
      category: item.category,
      isBought: item.isBought,
      isRecurring: item.isRecurring,
      createdAt: item.createdAt,
    );
  }

  /// Convierte este [ShoppingItemModel] a un Map para Firebase.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'note': note,
      'category': category,
      'isBought': isBought,
      'isRecurring': isRecurring,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
