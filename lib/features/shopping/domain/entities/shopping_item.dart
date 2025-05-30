class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String note;
  final String category;
  final bool isBought;
  final bool isRecurring;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.note = '',
    this.category = 'Otros',
    this.isBought = false,
    this.isRecurring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, quantity: $quantity, '
           'note: $note, category: $category, isBought: $isBought, '
           'isRecurring: $isRecurring, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingItem &&
        other.id == id &&
        other.name == name &&
        other.quantity == quantity &&
        other.note == note &&
        other.category == category &&
        other.isBought == isBought &&
        other.isRecurring == isRecurring &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        quantity.hashCode ^
        note.hashCode ^
        category.hashCode ^
        isBought.hashCode ^
        isRecurring.hashCode ^
        createdAt.hashCode;
  }
}
