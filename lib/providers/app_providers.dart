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

// Navigation tab provider
class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(() => BottomNavIndexNotifier());

final productsProvider = Provider<List<Product>>((ref) => dummyProducts);

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsProvider);
  final Set<String> categories = {};
  for (final p in products) {
    categories.add(p.category);
  }
  return categories.toList();
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
    return [
      Order(
        id: 'ORD-98241',
        items: [
          CartItem(id: 'c1', product: dummyProducts[0], quantity: 1),
          CartItem(id: 'c2', product: dummyProducts[31], quantity: 1),
        ],
        totalAmount: 31998.0,
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
      Order(
        id: 'ORD-97430',
        items: [
          CartItem(id: 'c3', product: dummyProducts[8], quantity: 2),
        ],
        totalAmount: 6998.0,
        date: DateTime.now().subtract(const Duration(days: 8)),
        status: 'Shipped',
        paymentMethod: 'JazzCash',
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

  void addOrder(List<CartItem> items, double totalAmount, {Address? address, String paymentMethod = 'Cash on Delivery'}) {
    final newOrder = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      items: List.from(items),
      totalAmount: totalAmount,
      date: DateTime.now(),
      status: 'Confirmed',
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
    if (data != null && data is List && data.isNotEmpty) {
      state = data.map((e) => Address.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = const [
        Address(
          id: 'addr_default',
          name: 'Umair',
          street: 'House 14-B, Street 5, Sector F-7/2',
          city: 'Islamabad',
          state: 'ICT',
          zipCode: '44000',
          country: 'Pakistan',
          isDefault: true,
        ),
      ];
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

  void setDefaultAddress(String id) {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
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
    var current = state.where((q) => q.toLowerCase() != query.toLowerCase()).toList();
    current.insert(0, query.trim());
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

// Search State
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

// Selected Category State
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void update(String? category) => state = category;
}
final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String?>(() => SelectedCategoryNotifier());

// Search Results (Searches entire catalog)
final searchResultsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return [];

  return products.where((p) {
    return p.name.toLowerCase().contains(query) || 
           p.description.toLowerCase().contains(query) ||
           p.brand.toLowerCase().contains(query) ||
           p.category.toLowerCase().contains(query);
  }).toList();
});

// Filtered Products (For category browsing)
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (category == null || category.isEmpty || category == 'All') {
    return products;
  }
  return products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
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

// Compare Provider (supports up to 3 products)
class CompareNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  bool toggleProduct(Product product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
      return false;
    } else {
      if (state.length >= 3) {
        return false;
      }
      state = [...state, product];
      return true;
    }
  }

  void removeProduct(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  bool isInCompare(String id) {
    return state.any((p) => p.id == id);
  }

  void clear() {
    state = [];
  }
}

final compareProvider = NotifierProvider<CompareNotifier, List<Product>>(() => CompareNotifier());

// User Profile Model & Provider
class UserProfile {
  final String name;
  final String email;
  final String phone;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
  });

  UserProfile copyWith({String? name, String? email, String? phone}) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final storage = ref.read(storageServiceProvider);
    final name = storage.getString('user_name') ?? 'Umair';
    final email = storage.getString('user_email') ?? 'umair@example.com';
    final phone = storage.getString('user_phone') ?? '+92 300 1234567';
    return UserProfile(name: name, email: email, phone: phone);
  }

  void updateProfile({required String name, required String email, required String phone}) {
    state = UserProfile(name: name, email: email, phone: phone);
    final storage = ref.read(storageServiceProvider);
    storage.saveString('user_name', name);
    storage.saveString('user_email', email);
    storage.saveString('user_phone', phone);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() => UserProfileNotifier());

