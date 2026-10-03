import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

abstract class WishlistRepository {
  Future<List<Product>> loadWishlist(List<Product> catalog);
  Future<void> saveWishlist(List<Product> wishlist);
}

class LocalWishlistRepository implements WishlistRepository {
  final SharedPreferences _prefs;

  LocalWishlistRepository(this._prefs);

  @override
  Future<List<Product>> loadWishlist(List<Product> catalog) async {
    final String? wishlistData = _prefs.getString('wishlist');
    if (wishlistData == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(wishlistData);
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
  Future<void> saveWishlist(List<Product> wishlist) async {
    final String encoded = jsonEncode(wishlist.map((p) => {'id': p.id}).toList());
    await _prefs.setString('wishlist', encoded);
  }
}
