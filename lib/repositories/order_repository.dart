import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/address.dart';
import '../models/product.dart';

abstract class OrderRepository {
  List<Order> getOrders(List<Product> catalog);
  void saveOrders(List<Order> orders);
}

class LocalOrderRepository implements OrderRepository {
  final SharedPreferences _prefs;

  LocalOrderRepository(this._prefs);

  @override
  List<Order> getOrders(List<Product> catalog) {
    final String? orderData = _prefs.getString('orders_v3');
    if (orderData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(orderData);
        final List<Order> loaded = [];
        for (final o in decoded) {
          if (o is Map<String, dynamic>) {
            loaded.add(Order.fromMap(o, catalog));
          }
        }
        if (loaded.isNotEmpty) return loaded;
      } catch (_) {}
    }

    // Check legacy v2 format
    final String? legacyData = _prefs.getString('orders_v2');
    if (legacyData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(legacyData);
        final List<Order> loaded = [];
        for (final o in decoded) {
          if (o is Map<String, dynamic>) {
            loaded.add(Order.fromMap(o, catalog));
          }
        }
        if (loaded.isNotEmpty) {
          saveOrders(loaded);
          return loaded;
        }
      } catch (_) {}
    }

    // Default authentic demo orders for Pakistani users if none exist
    if (catalog.isNotEmpty) {
      final defaultAddr = defaultPakistaniAddresses.first;
      final p1 = catalog[0];
      final p2 = catalog.length > 5 ? catalog[5] : catalog.first;
      final p3 = catalog.length > 10 ? catalog[10] : catalog.first;

      final initialOrders = [
        Order(
          id: 'ORD-20261002-001',
          items: [
            CartItem(
              id: 'c_demo_1',
              product: p1,
              quantity: 1,
              unitPrice: p1.price,
              selectedColor: p1.colors.isNotEmpty ? p1.colors.first : null,
            ),
            if (p2.id != p1.id)
              CartItem(
                id: 'c_demo_2',
                product: p2,
                quantity: 1,
                unitPrice: p2.price,
                selectedSize: p2.sizes.isNotEmpty ? p2.sizes.first : null,
              ),
          ],
          subtotal: p1.price + (p2.id != p1.id ? p2.price : 0),
          discount: 500.0,
          deliveryFee: 150.0,
          totalAmount: p1.price + (p2.id != p1.id ? p2.price : 0) - 500.0 + 150.0,
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: 'Delivered',
          deliveryAddress: defaultAddr,
          deliveryMethod: 'Standard Delivery (2–4 days)',
          paymentMethod: 'Cash on Delivery',
          paymentStatus: 'Paid (Cash on Delivery Handover)',
          estimatedDelivery: 'Oct 04, 2026',
        ),
        Order(
          id: 'ORD-20261004-002',
          items: [
            CartItem(
              id: 'c_demo_3',
              product: p3,
              quantity: 1,
              unitPrice: p3.price,
            ),
          ],
          subtotal: p3.price,
          discount: 0.0,
          deliveryFee: 300.0,
          totalAmount: p3.price + 300.0,
          date: DateTime.now().subtract(const Duration(hours: 4)),
          status: 'Confirmed',
          deliveryAddress: defaultPakistaniAddresses.length > 1 ? defaultPakistaniAddresses[1] : defaultAddr,
          deliveryMethod: 'Express Delivery (1–2 days)',
          paymentMethod: 'Cash on Delivery',
          paymentStatus: 'Pending (Cash on Delivery)',
          estimatedDelivery: 'Oct 05, 2026',
        ),
      ];
      saveOrders(initialOrders);
      return initialOrders;
    }
    return [];
  }

  @override
  void saveOrders(List<Order> orders) {
    final encoded = jsonEncode(orders.map((o) => o.toMap()).toList());
    _prefs.setString('orders_v3', encoded);
  }
}
