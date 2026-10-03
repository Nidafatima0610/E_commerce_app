import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

abstract class CartRepository {
  Future<List<CartItem>> loadCart(List<Product> catalog);
  Future<void> saveCart(List<CartItem> items);
  Future<List<Product>> loadSavedForLater(List<Product> catalog);
  Future<void> saveSavedForLater(List<Product> items);
}

class LocalCartRepository implements CartRepository {
  final SharedPreferences _prefs;

  LocalCartRepository(this._prefs);

  @override
  Future<List<CartItem>> loadCart(List<Product> catalog) async {
    final String? cartData = _prefs.getString('cart');
    if (cartData == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(cartData);
      return decoded.map((e) {
        final pData = e['product'];
        final product = catalog.firstWhere(
          (p) => p.id == pData['id'],
          orElse: () => catalog.first,
        );
        return CartItem(
          id: e['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: (e['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    final String encoded = jsonEncode(items.map((item) => {
      'id': item.id,
      'quantity': item.quantity,
      'product': {'id': item.product.id},
    }).toList());
    await _prefs.setString('cart', encoded);
  }

  @override
  Future<List<Product>> loadSavedForLater(List<Product> catalog) async {
    final String? savedData = _prefs.getString('saved_for_later');
    if (savedData == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(savedData);
      return decoded.map((e) {
        final id = e is Map ? e['id'] : e.toString();
        return catalog.firstWhere(
          (p) => p.id == id,
          orElse: () => catalog.first,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSavedForLater(List<Product> items) async {
    final String encoded = jsonEncode(items.map((p) => {'id': p.id}).toList());
    await _prefs.setString('saved_for_later', encoded);
  }
}
