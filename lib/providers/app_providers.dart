import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/coupon.dart';
import '../models/address.dart';
import '../core/storage_service.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/wishlist_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';

// ==================== REPOSITORY PROVIDERS ====================

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return LocalProductRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return LocalCategoryRepository();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final storageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCartRepository(prefs);
});

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalWishlistRepository(prefs);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalOrderRepository(prefs);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LocalUserRepository(storage);
});

// ==================== CORE PRODUCT & CATEGORY PROVIDERS ====================

final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getAllProducts();
});

final categoriesProvider = Provider<List<String>>((ref) {
  return ref.watch(productRepositoryProvider).getAllCategories();
});

final categoryItemsProvider = Provider<List<CategoryItem>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

// Specialized product catalog slices for Home Screen
final featuredProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getFeaturedProducts();
});

final dealProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getDeals();
});

final bestsellerProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getBestSellers();
});

final newArrivalProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getNewArrivals();
});

final dealsOfTheDayProvider = Provider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getDealsOfTheDay();
});

final recommendedProductsProvider = Provider<List<Product>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final viewed = ref.watch(recentlyViewedProvider);
  return ref.watch(productRepositoryProvider).getRecommendedProducts(
    preferredCategory: category,
    viewedIds: viewed.map((p) => p.id).toList(),
    limit: 12,
  );
});

// ==================== NAVIGATION & STATE PROVIDERS ====================

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(() => BottomNavIndexNotifier());

// Delivery City Selection (Pakistani Context)
class DeliveryCityNotifier extends Notifier<String> {
  @override
  String build() {
    final storage = ref.read(storageServiceProvider);
    return storage.getString('selected_city') ?? 'Gulberg, Lahore';
  }

  void setCity(String city) {
    state = city;
    ref.read(storageServiceProvider).saveString('selected_city', city);
  }
}

final deliveryCityProvider = NotifierProvider<DeliveryCityNotifier, String>(() => DeliveryCityNotifier());

// Notification Badge Provider
class NotificationCountNotifier extends Notifier<int> {
  @override
  int build() => 2; // Initial welcome promotions
  void markAllAsRead() => state = 0;
  void addNotification() => state++;
}

final notificationCountProvider = NotifierProvider<NotificationCountNotifier, int>(() => NotificationCountNotifier());

// Applied Coupon Provider
class AppliedCouponNotifier extends Notifier<Coupon?> {
  @override
  Coupon? build() => null;
  void update(Coupon? coupon) => state = coupon;
}

final appliedCouponProvider = NotifierProvider<AppliedCouponNotifier, Coupon?>(() => AppliedCouponNotifier());

// ==================== CART & SAVE FOR LATER PROVIDERS ====================

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    _loadCart();
    return [];
  }

  void _loadCart() async {
    final repo = ref.read(cartRepositoryProvider);
    final products = ref.read(productsProvider);
    state = await repo.loadCart(products);
  }

  void _saveCart() {
    final repo = ref.read(cartRepositoryProvider);
    repo.saveCart(state);
  }

  void addItem(
    Product product, {
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
    String? selectedStorage,
    String? selectedVariant,
    double? unitPrice,
  }) {
    final effectivePrice = unitPrice ?? product.price;
    final existingIndex = state.indexWhere((item) =>
        item.product.id == product.id &&
        (item.selectedColor ?? '') == (selectedColor ?? '') &&
        (item.selectedSize ?? '') == (selectedSize ?? '') &&
        (item.selectedStorage ?? '') == (selectedStorage ?? '') &&
        (item.selectedVariant ?? '') == (selectedVariant ?? ''));

    if (existingIndex >= 0) {
      final updatedCart = List<CartItem>.from(state);
      final current = updatedCart[existingIndex];
      final newQty = (current.quantity + quantity).clamp(1, product.availableStock);
      updatedCart[existingIndex] = current.copyWith(
        quantity: newQty,
        unitPrice: effectivePrice,
      );
      state = updatedCart;
    } else {
      final newQty = quantity.clamp(1, product.availableStock);
      state = [
        ...state,
        CartItem(
          id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
          product: product,
          quantity: newQty,
          selectedColor: selectedColor,
          selectedSize: selectedSize,
          selectedStorage: selectedStorage,
          selectedVariant: selectedVariant,
          unitPrice: effectivePrice,
        ),
      ];
    }
    _saveCart();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveCart();
  }

  bool updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return true;
    }
    final itemIndex = state.indexWhere((item) => item.id == id);
    if (itemIndex >= 0) {
      final item = state[itemIndex];
      if (quantity > item.product.availableStock) {
        return false;
      }
      final updated = List<CartItem>.from(state);
      updated[itemIndex] = item.copyWith(quantity: quantity);
      state = updated;
      _saveCart();
      return true;
    }
    return false;
  }

  void clearCart() {
    state = [];
    _saveCart();
  }

  double get subtotal => state.fold(0.0, (total, item) => total + item.subtotal);
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

// Save For Later Provider
class SavedForLaterNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    _loadSaved();
    return [];
  }

  void _loadSaved() async {
    final repo = ref.read(cartRepositoryProvider);
    final products = ref.read(productsProvider);
    state = await repo.loadSavedForLater(products);
  }

  void _persist() {
    final repo = ref.read(cartRepositoryProvider);
    repo.saveSavedForLater(state);
  }

  void saveForLater(CartItem cartItem) {
    if (!state.any((item) => item.id == cartItem.id || (item.product.id == cartItem.product.id && item.variantDescription == cartItem.variantDescription))) {
      state = [...state, cartItem];
      _persist();
    }
    ref.read(cartProvider.notifier).removeItem(cartItem.id);
  }

  void moveToCart(CartItem item) {
    state = state.where((i) => i.id != item.id).toList();
    _persist();
    ref.read(cartProvider.notifier).addItem(
      item.product,
      quantity: item.quantity,
      selectedColor: item.selectedColor,
      selectedSize: item.selectedSize,
      selectedStorage: item.selectedStorage,
      selectedVariant: item.selectedVariant,
      unitPrice: item.unitPrice,
    );
  }

  void removeSaved(String itemId) {
    state = state.where((item) => item.id != itemId && item.product.id != itemId).toList();
    _persist();
  }
}

final savedForLaterProvider = NotifierProvider<SavedForLaterNotifier, List<CartItem>>(() {
  return SavedForLaterNotifier();
});

// ==================== RECENTLY VIEWED PROVIDER ====================

class RecentlyViewedNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _loadRecentlyViewed();
    return [];
  }

  void _loadRecentlyViewed() {
    final storage = ref.read(storageServiceProvider);
    final products = ref.read(productsProvider);
    final data = storage.getJson('recently_viewed');
    if (data != null && data is List && products.isNotEmpty) {
      state = data
          .map((id) => products.where((p) => p.id == id).firstOrNull)
          .whereType<Product>()
          .toList();
    }
  }

  void addProduct(Product product) {
    final storage = ref.read(storageServiceProvider);
    var current = state.where((p) => p.id != product.id).toList();
    current.insert(0, product);
    if (current.length > 15) current = current.sublist(0, 15);
    state = current;
    storage.saveJson('recently_viewed', state.map((p) => p.id).toList());
  }

  void removeProduct(String id) {
    state = state.where((p) => p.id != id).toList();
    ref.read(storageServiceProvider).saveJson('recently_viewed', state.map((p) => p.id).toList());
  }

  void clear() {
    state = [];
    ref.read(storageServiceProvider).saveJson('recently_viewed', []);
  }
}

final recentlyViewedProvider = NotifierProvider<RecentlyViewedNotifier, List<Product>>(() {
  return RecentlyViewedNotifier();
});

// ==================== WISHLIST PROVIDER ====================

class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _loadWishlist();
    return [];
  }

  void _loadWishlist() async {
    final repo = ref.read(wishlistRepositoryProvider);
    final products = ref.read(productsProvider);
    state = await repo.loadWishlist(products);
  }

  void _saveWishlist() {
    final repo = ref.read(wishlistRepositoryProvider);
    repo.saveWishlist(state);
  }

  void toggleWishlist(Product product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
    _saveWishlist();
  }

  void removeFromWishlist(String productId) {
    state = state.where((p) => p.id != productId).toList();
    _saveWishlist();
  }

  bool isInWishlist(String productId) {
    return state.any((p) => p.id == productId);
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(() {
  return WishlistNotifier();
});

// ==================== ORDERS PROVIDER ====================

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    _loadOrders();
    return [];
  }

  void _loadOrders() async {
    final repo = ref.read(orderRepositoryProvider);
    final products = ref.read(productsProvider);
    state = await repo.getOrders(products);
  }

  void addOrder(
    List<CartItem> items,
    double totalAmount, {
    Address? address,
    String paymentMethod = 'Cash on Delivery',
  }) {
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
    ref.read(orderRepositoryProvider).saveOrders(state);
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(() {
  return OrdersNotifier();
});

// ==================== ADDRESSES PROVIDER ====================

class AddressesNotifier extends Notifier<List<Address>> {
  @override
  List<Address> build() {
    return ref.read(userRepositoryProvider).getAddresses();
  }

  void _save() {
    ref.read(userRepositoryProvider).saveAddresses(state);
  }

  void addAddress(Address address) {
    if (address.isDefault) {
      state = state.map((a) => a.copyWith(isDefault: false)).toList();
    }
    state = [...state, address];
    if (state.length == 1) {
      state = [state.first.copyWith(isDefault: true)];
    }
    _save();
  }

  void removeAddress(String id) {
    state = state.where((a) => a.id != id).toList();
    _save();
  }

  void setDefaultAddress(String id) {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    _save();
  }
}

final addressesProvider = NotifierProvider<AddressesNotifier, List<Address>>(() {
  return AddressesNotifier();
});

// ==================== SEARCH & FILTER PROVIDERS ====================

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

  void removeSearch(String query) {
    state = state.where((q) => q.toLowerCase() != query.toLowerCase()).toList();
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

class SelectedSubcategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void update(String? subcat) => state = subcat;
}

final selectedSubcategoryProvider = NotifierProvider<SelectedSubcategoryNotifier, String?>(() => SelectedSubcategoryNotifier());

// Search Results (Deep tokenized search across all product attributes)
final searchResultsProvider = Provider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.searchProducts(query);
});

// Filtered Products (For category & subcategory browsing)
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final subcategory = ref.watch(selectedSubcategoryProvider);

  if (category == null || category.isEmpty || category == 'All') {
    return repo.getAllProducts();
  }

  if (subcategory != null && subcategory.isNotEmpty && subcategory != 'All') {
    return repo.getBySubcategory(category, subcategory);
  }

  return repo.getByCategory(category);
});

// ==================== THEME MODE PROVIDER ====================

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

// ==================== PRODUCT COMPARISON PROVIDER ====================

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

// ==================== USER PROFILE PROVIDER ====================

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
