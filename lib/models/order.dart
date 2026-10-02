import 'cart_item.dart';
import 'address.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String status;
  final Address? deliveryAddress;
  final String paymentMethod;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    this.status = 'Processing',
    this.deliveryAddress,
    this.paymentMethod = 'Credit Card',
  });
}
