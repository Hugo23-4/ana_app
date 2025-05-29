+ // lib/features/shopping/domain/entities/shopping_item.dart
+ class ShoppingItem {
+   final String id;
+   final String name;
+   final int quantity;
+
+   ShoppingItem({
+     required this.id,
+     required this.name,
+     required this.quantity,
+   });
+ 
+   @override
+   String toString() => 'ShoppingItem(id: $id, name: $name, quantity: $quantity)';
+ 
+   @override
+   bool operator ==(Object other) =>
+       identical(this, other) ||
+       (other is ShoppingItem &&
+           other.id == id &&
+           other.name == name &&
+           other.quantity == quantity);
+
+   @override
+   int get hashCode => id.hashCode ^ name.hashCode ^ quantity.hashCode;
+ }
