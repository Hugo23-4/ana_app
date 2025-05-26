/// Extensiones útiles para trabajar con listas.
/// Esta extensión permite obtener los últimos elementos de una lista de forma segura.
extension TakeLastExtension<E> on List<E> {
  /// Retorna los últimos [count] elementos de la lista.
  /// Si la lista tiene menos elementos que [count], retorna todos.
  List<E> takeLast(int count) {
    if (length <= count) return List<E>.from(this);
    return sublist(length - count);
  }
}
