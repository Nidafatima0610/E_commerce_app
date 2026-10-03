import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/address.dart';
import '../models/product.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders(List<Product> catalog);
  Future<void> saveOrders(List<Order> orders);
}

class LocalOrderRepository implements OrderRepository {
  final SharedPreferences _prefs;

  LocalOrderRepository(this._prefs);

  @override
  Future<List<Order>> getOrders(List<Product> catalog) async {
    final String? orderData = _prefs.getString('orders_v2');
    if (orderData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(orderData);
        return decoded.map((o) {
          final itemsList = (o['items'] as List).map((i) {
            final p = catalog.firstWhere((prod) => prod.id == i['productId'], orElse: () => catalog.first);
            return CartItem(
              id: i['id'] ?? '',
              product: p,
              quantity: (i['quantity'] as num?)?.toInt() ?? 1,
            );
          }).toList();

          return Order(
            id: o['id'],
            items: itemsList,
            totalAmount: (o['totalAmount'] as num).toDouble(),
            date: DateTime.parse(o['date']),
            status: o['status'] ?? 'Confirmed',
            paymentMethod: o['paymentMethod'] ?? 'Cash on Delivery',
            deliveryAddress: o['address'] != null ? Address.fromJson(Map<String, dynamic>.from(o['address'])) : null,
          );
        }).toList();
      } catch (_) {}
    }

    // Default mock orders if none saved
    if (catalog.isNotEmpty) {
      return [
        Order(
          id: 'ORD-98241',
          items: [
            CartItem(id: 'c1', product: catalog[0], quantity: 1),
            if (catalog.length > 5) CartItem(id: 'c2', product: catalog[5], quantity: 1),
          ],
          totalAmount: catalog[0].price + (catalog.length > 5 ? catalog[5].price : 0),
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: 'Delivered',
          paymentMethod: 'Cash on Delivery',
          deliveryAddress: const Address(
            id: 'addr_default',
            name: 'Umair',
            street: 'House 14-B, Street 5, Sector F-7/2',
            city: 'Islamabad',
            state: 'ICT',
            zipCode: '44000',
            country: 'Pakistan',
            isDefault: true,
          ),
        ),
      ];
    }
    return [];
  }

  @override
  Future<void> saveOrders(List<Order> orders) async {
    final encoded = jsonEncode(orders.map((o) => {
      'id': o.id,
      'totalAmount': o.totalAmount,
      'date': o.date.toIso8601String(),
      'status': o.status,
      'paymentMethod': o.paymentMethod,
      'address': o.deliveryAddress?.toJson(),
      'items': o.items.map((i) => {
        'id': i.id,
        'quantity': i.quantity,
        'productId': i.product.id,
      }).toList(),
    }).toList());
    await _prefs.setString('orders_v2', encoded);
  }
}
