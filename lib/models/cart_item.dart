import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  
  const CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get subtotal => product.price * quantity;
}
