import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/coupon.dart';
import '../models/address.dart';
import '../core/storage_service.dart';

import '../models/dummy_data.dart';

final productsProvider = Provider<List<Product>>((ref) => dummyProducts);

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsProvider);
  return products.map((p) => p.category).toSet().toList();
});

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// Storage Service Provider
final storageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

// Applied Coupon Provider
class AppliedCouponNotifier extends Notifier<Coupon?> {
  @override
  Coupon? build() => null;
  void update(Coupon? coupon) => state = coupon;
}
final appliedCouponProvider = NotifierProvider<AppliedCouponNotifier, Coupon?>(() => AppliedCouponNotifier());

// Cart Provider
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    _loadCart();
    return [];
  }

  void _loadCart() {
    final prefs = ref.read(sharedPreferencesProvider);
    final String? cartData = prefs.getString('cart');
    if (cartData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartData);
        state = decoded.map((e) {
          final pData = e['product'];
          final product = dummyProducts.firstWhere(
            (p) => p.id == pData['id'],
            orElse: () => dummyProducts.first,
          );
          return CartItem(
            id: e['id'],
            product: product,
            quantity: e['quantity'],
          );
        }).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  void _saveCart() {
    final prefs = ref.read(sharedPreferencesProvider);
    final String encoded = jsonEncode(state.map((item) => {
      'id': item.id,
      'quantity': item.quantity,
      'product': {'id': item.product.id},
    }).toList());
    prefs.setString('cart', encoded);
  }

  void addItem(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedCart = List<CartItem>.from(state);
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + 1,
      );
      state = updatedCart;
    } else {
      state = [
        ...state,
        CartItem(id: DateTime.now().millisecondsSinceEpoch.toString(), product: product)
      ];
    }
    _saveCart();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveCart();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(quantity: quantity) else item
    ];
    _saveCart();
  }

  void clearCart() {
    state = [];
    _saveCart();
  }

  double get subtotal => state.fold(0, (total, item) => total + item.subtotal);
  int get itemCount => state.fold(0, (total, item) => total + item.quantity);

  double calculateDiscount(Coupon? coupon) {
    if (coupon == null) return 0;
    if (subtotal < coupon.minOrderAmount) return 0;
    if (coupon.isPercentage) {
      return subtotal * (coupon.discount / 100);
    }
    return coupon.discount;
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

// Recently Viewed Provider
class RecentlyViewedNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _loadRecentlyViewed();
    return [];
  }

  void _loadRecentlyViewed() {
    final storage = ref.read(storageServiceProvider);
    final data = storage.getJson('recently_viewed');
    if (data != null && data is List) {
      state = data.map((id) => dummyProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => dummyProducts.first,
      )).toList();
    }
  }

  void addProduct(Product product) {
    final storage = ref.read(storageServiceProvider);
    var current = state.where((p) => p.id != product.id).toList();
    current.insert(0, product);
    if (current.length > 10) current = current.sublist(0, 10);
    state = current;
    storage.saveJson('recently_viewed', state.map((p) => p.id).toList());
  }
  
  void clear() {
    state = [];
    ref.read(storageServiceProvider).saveJson('recently_viewed', []);
  }
}

final recentlyViewedProvider = NotifierProvider<RecentlyViewedNotifier, List<Product>>(() {
  return RecentlyViewedNotifier();
});


// Wishlist Provider
class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _loadWishlist();
    return [];
  }

  void _loadWishlist() {
    final prefs = ref.read(sharedPreferencesProvider);
    final String? wishlistData = prefs.getString('wishlist');
    if (wishlistData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(wishlistData);
        state = decoded.map((e) {
          return dummyProducts.firstWhere(
            (p) => p.id == e['id'],
            orElse: () => dummyProducts.first,
          );
        }).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  void _saveWishlist() {
    final prefs = ref.read(sharedPreferencesProvider);
    final String encoded = jsonEncode(state.map((p) => {'id': p.id}).toList());
    prefs.setString('wishlist', encoded);
  }

  void toggleWishlist(Product product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
    _saveWishlist();
  }

  bool isInWishlist(String productId) {
    return state.any((p) => p.id == productId);
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(() {
  return WishlistNotifier();
});

// Orders Provider
class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    return [];
  }

  void addOrder(List<CartItem> items, double totalAmount, {Address? address, String paymentMethod = 'Credit Card'}) {
    final newOrder = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: List.from(items),
      totalAmount: totalAmount,
      date: DateTime.now(),
      deliveryAddress: address,
      paymentMethod: paymentMethod,
    );
    state = [newOrder, ...state];
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(() {
  return OrdersNotifier();
});

// Addresses Provider
class AddressesNotifier extends Notifier<List<Address>> {
  @override
  List<Address> build() {
    _loadAddresses();
    return [];
  }

  void _loadAddresses() {
    final storage = ref.read(storageServiceProvider);
    final data = storage.getJson('addresses');
    if (data != null && data is List) {
      state = data.map((e) => Address.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  void _saveAddresses() {
    final storage = ref.read(storageServiceProvider);
    storage.saveJson('addresses', state.map((a) => a.toJson()).toList());
  }

  void addAddress(Address address) {
    if (address.isDefault) {
      state = state.map((a) => a.copyWith(isDefault: false)).toList();
    }
    state = [...state, address];
    if (state.length == 1) {
      state = [state.first.copyWith(isDefault: true)];
    }
    _saveAddresses();
  }

  void removeAddress(String id) {
    state = state.where((a) => a.id != id).toList();
    _saveAddresses();
  }
}

final addressesProvider = NotifierProvider<AddressesNotifier, List<Address>>(() {
  return AddressesNotifier();
});

// Search History Provider
class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.read(storageServiceProvider).getStringList('search_history');
  }

  void addSearch(String query) {
    if (query.trim().isEmpty) return;
    var current = state.where((q) => q != query).toList();
    current.insert(0, query);
    if (current.length > 10) current = current.sublist(0, 10);
    state = current;
    ref.read(storageServiceProvider).saveStringList('search_history', state);
  }

  void clearHistory() {
    state = [];
    ref.read(storageServiceProvider).saveStringList('search_history', []);
  }
}

final searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(() {
  return SearchHistoryNotifier();
});

// Search and Filter State
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void update(String? category) => state = category;
}
final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String?>(() => SelectedCategoryNotifier());

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return products.where((p) {
    final matchesQuery = p.name.toLowerCase().contains(query) || 
                         p.description.toLowerCase().contains(query);
    final matchesCategory = category == null || p.category == category;
    return matchesQuery && matchesCategory;
  }).toList();
});

// Theme Mode Provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final isDark = ref.read(storageServiceProvider).getBool('is_dark_mode', defaultValue: false);
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    ref.read(storageServiceProvider).saveBool('is_dark_mode', !isDark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ThemeModeNotifier());
