import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

abstract class CartRepository {
  Future<List<CartItem>> loadCart(List<Product> catalog);
  Future<void> saveCart(List<CartItem> items);
  Future<List<CartItem>> loadSavedForLater(List<Product> catalog);
  Future<void> saveSavedForLater(List<CartItem> items);
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
      final List<CartItem> items = [];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final String prodId = (e['productId'] ?? (e['product'] is Map ? e['product']['id'] : null)) ?? '';
          final matchingProduct = catalog.where((p) => p.id == prodId).firstOrNull;
          if (matchingProduct != null) {
            items.add(CartItem.fromMap(e, matchingProduct));
          }
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    final String encoded = jsonEncode(items.map((item) => item.toMap()).toList());
    await _prefs.setString('cart', encoded);
  }

  @override
  Future<List<CartItem>> loadSavedForLater(List<Product> catalog) async {
    final String? savedData = _prefs.getString('saved_for_later');
    if (savedData == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(savedData);
      final List<CartItem> items = [];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final String prodId = (e['productId'] ?? (e['product'] is Map ? e['product']['id'] : e['id'])) ?? '';
          final matchingProduct = catalog.where((p) => p.id == prodId).firstOrNull;
          if (matchingProduct != null) {
            items.add(CartItem.fromMap(e, matchingProduct));
          }
        } else if (e is String) {
          final matchingProduct = catalog.where((p) => p.id == e).firstOrNull;
          if (matchingProduct != null) {
            items.add(CartItem(
              id: 'saved_${matchingProduct.id}',
              product: matchingProduct,
              quantity: 1,
            ));
          }
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSavedForLater(List<CartItem> items) async {
    final String encoded = jsonEncode(items.map((item) => item.toMap()).toList());
    await _prefs.setString('saved_for_later', encoded);
  }
}
