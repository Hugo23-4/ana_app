// lib/core/models/shopping_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItemModel {
  final String id;
  final String name;
  final String category;
  final bool isBought;
  final bool isRecurring;
  final DateTime createdAt;
  final String userId;

  ShoppingItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isBought,
    required this.isRecurring,
    required this.createdAt,
    required this.userId,
  });

  factory ShoppingItemModel.fromMap(String id, Map<String, dynamic> data) {
    return ShoppingItemModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      isBought: data['isBought'] ?? false,
      isRecurring: data['isRecurring'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'isBought': isBought,
      'isRecurring': isRecurring,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  ShoppingItemModel copyWith({
    String? name,
    String? category,
    bool? isBought,
    bool? isRecurring,
  }) {
    return ShoppingItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      isBought: isBought ?? this.isBought,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt,
      userId: userId,
    );
  }
}
