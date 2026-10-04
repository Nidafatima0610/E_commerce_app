import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/coupon.dart';
import '../models/address.dart';
import '../models/delivery_method.dart';
import '../models/payment_method.dart';
import '../models/notification_item.dart';
import '../models/return_request.dart';
import '../core/currency_format.dart';
import '../core/storage_service.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/wishlist_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/review_repository.dart';
import '../models/product_review.dart';
import '../models/product_question.dart';
import '../core/recommendation_service.dart';

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

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalReviewRepository(prefs);
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

// Catalog slices for Home Screen
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
    return storage.getString('selected_city') ?? 'Bahawalpur';
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

// Delivery Method Provider
class SelectedDeliveryMethodNotifier extends Notifier<DeliveryMethod> {
  @override
  DeliveryMethod build() => defaultDeliveryMethods.first;
  void selectMethod(DeliveryMethod method) => state = method;
}

final selectedDeliveryMethodProvider = NotifierProvider<SelectedDeliveryMethodNotifier, DeliveryMethod>(() => SelectedDeliveryMethodNotifier());

// Payment Method Provider
class SelectedPaymentMethodNotifier extends Notifier<PaymentMethodOption> {
  @override
  PaymentMethodOption build() => availablePaymentOptions.first;
  void selectMethod(PaymentMethodOption method) => state = method;
}

final selectedPaymentMethodProvider = NotifierProvider<SelectedPaymentMethodNotifier, PaymentMethodOption>(() => SelectedPaymentMethodNotifier());

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
    final effectivePrice = unitPrice ?? product.getPriceForVariants(storage: selectedStorage, size: selectedSize);
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

  double calculateDiscount(Coupon? coupon, {double deliveryFee = 150.0}) {
    if (coupon == null) return 0;
    return coupon.calculateSavings(subtotal, deliveryFee);
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
    final repo = ref.read(orderRepositoryProvider);
    final products = ref.read(productsProvider);
    return repo.getOrders(products);
  }

  void _persist() {
    ref.read(orderRepositoryProvider).saveOrders(state);
  }

  Order createOrder({
    required List<CartItem> items,
    required double totalAmount,
    required double subtotal,
    required double discount,
    required double deliveryFee,
    required Address address,
    required String deliveryMethod,
    required String paymentMethod,
    required String estimatedDelivery,
    String? notes,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final count = state.length + 1;
    final orderId = 'ORD-$dateStr-${count.toString().padLeft(3, '0')}';

    final newOrder = Order(
      id: orderId,
      items: List.from(items),
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      date: now,
      status: 'Confirmed',
      deliveryAddress: address,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      paymentStatus: 'Pending (Cash on Delivery)',
      estimatedDelivery: estimatedDelivery,
      notes: notes,
      customerId: 'usr_101',
    );

    state = [newOrder, ...state];
    _persist();

    // Trigger in-app notification
    ref.read(inAppNotificationsProvider.notifier).addNotification(
      title: 'Order Confirmed! 🎉',
      message: 'Your order $orderId for ${CurrencyFormat.format(totalAmount)} has been placed via Cash on Delivery.',
      type: NotificationType.orderPlaced,
      orderId: orderId,
    );

    return newOrder;
  }

  // Backward compatible addOrder
  void addOrder(
    List<CartItem> items,
    double totalAmount, {
    Address? address,
    String paymentMethod = 'Cash on Delivery',
  }) {
    final addresses = ref.read(addressesProvider);
    final defaultAddr = address ?? addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull ?? defaultPakistaniAddresses.first;
    createOrder(
      items: items,
      totalAmount: totalAmount,
      subtotal: totalAmount,
      discount: 0,
      deliveryFee: 150,
      address: defaultAddr,
      deliveryMethod: 'Standard Delivery (2–4 days)',
      paymentMethod: paymentMethod,
      estimatedDelivery: '2–4 business days',
    );
  }

  bool cancelOrder(String orderId) {
    final idx = state.indexWhere((o) => o.id == orderId);
    if (idx < 0) return false;
    final order = state[idx];
    if (!order.canCancel) return false;

    final updated = List<Order>.from(state);
    updated[idx] = order.copyWith(
      status: 'Cancelled',
      paymentStatus: 'Void (Order Cancelled)',
    );
    state = updated;
    _persist();

    ref.read(inAppNotificationsProvider.notifier).addNotification(
      title: 'Order Cancelled',
      message: 'Order $orderId has been successfully cancelled.',
      type: NotificationType.system,
      orderId: orderId,
    );
    return true;
  }

  /// Reorder items from a past order, verifying stock and preserving variants
  ({int readdedCount, int skippedCount}) reorderItems(Order order) {
    int readded = 0;
    int skipped = 0;
    final cartNotifier = ref.read(cartProvider.notifier);

    for (final item in order.items) {
      if (item.product.isOutOfStock) {
        skipped++;
        continue;
      }
      cartNotifier.addItem(
        item.product,
        quantity: item.quantity.clamp(1, item.product.availableStock),
        selectedColor: item.selectedColor,
        selectedSize: item.selectedSize,
        selectedStorage: item.selectedStorage,
        selectedVariant: item.selectedVariant,
        unitPrice: item.unitPrice,
      );
      readded++;
    }

    return (readdedCount: readded, skippedCount: skipped);
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
    if (address.isDefault || state.isEmpty) {
      state = state.map((a) => a.copyWith(isDefault: false)).toList();
      state = [...state, address.copyWith(isDefault: true)];
    } else {
      state = [...state, address];
    }
    _save();
  }

  void updateAddress(Address address) {
    if (address.isDefault) {
      state = state.map((a) => a.id == address.id ? address : a.copyWith(isDefault: false)).toList();
    } else {
      final isCurrentlyDefault = state.where((a) => a.id == address.id && a.isDefault).isNotEmpty;
      if (isCurrentlyDefault && state.length > 1) {
        final otherId = state.firstWhere((a) => a.id != address.id).id;
        state = state.map((a) {
          if (a.id == address.id) return address.copyWith(isDefault: false);
          if (a.id == otherId) return a.copyWith(isDefault: true);
          return a;
        }).toList();
      } else {
        state = state.map((a) => a.id == address.id ? address : a).toList();
      }
    }
    _save();
  }

  void removeAddress(String id) {
    final removedWasDefault = state.where((a) => a.id == id && a.isDefault).isNotEmpty;
    state = state.where((a) => a.id != id).toList();
    if (removedWasDefault && state.isNotEmpty) {
      state = [
        state.first.copyWith(isDefault: true),
        ...state.sublist(1),
      ];
    }
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

// Search Results
final searchResultsProvider = Provider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.searchProducts(query);
});

// Filtered Products
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
  final String avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl = '',
  });

  UserProfile copyWith({String? name, String? email, String? phone, String? avatarUrl}) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final storage = ref.read(storageServiceProvider);
    final name = storage.getString('user_name') ?? 'Umair';
    final email = storage.getString('user_email') ?? 'umair@example.com';
    final phone = storage.getString('user_phone') ?? '+92 301 7894561';
    final avatar = storage.getString('user_avatar') ?? '';
    return UserProfile(name: name, email: email, phone: phone, avatarUrl: avatar);
  }

  void updateProfile({required String name, required String email, required String phone, String? avatarUrl}) {
    state = UserProfile(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
    final storage = ref.read(storageServiceProvider);
    storage.saveString('user_name', name);
    storage.saveString('user_email', email);
    storage.saveString('user_phone', phone);
    if (avatarUrl != null) {
      storage.saveString('user_avatar', avatarUrl);
    }
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() => UserProfileNotifier());

// ==================== IN-APP NOTIFICATIONS PROVIDER ====================

class InAppNotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    _load();
    return [];
  }

  void _load() {
    final storage = ref.read(storageServiceProvider);
    final data = storage.getJson('in_app_notifications_v1');
    if (data != null && data is List && data.isNotEmpty) {
      try {
        state = data.map((e) => NotificationItem.fromMap(Map<String, dynamic>.from(e))).toList();
        return;
      } catch (_) {}
    }
    // Default welcome promotions
    state = [
      NotificationItem(
        id: 'notif_promo_1',
        title: 'Welcome to E-Store Pakistan! 🇵🇰',
        message: 'Use coupon code WELCOME10 for 10% off your purchase.',
        type: NotificationType.promotion,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_promo_2',
        title: 'Nationwide Free Delivery Weekend 🚚',
        message: 'Apply code FREESHIP on any cart value above Rs. 1,500.',
        type: NotificationType.promotion,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
    ];
    _save();
  }

  void _save() {
    ref.read(storageServiceProvider).saveJson('in_app_notifications_v1', state.map((n) => n.toMap()).toList());
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
  }) {
    final newNotif = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      orderId: orderId,
    );
    state = [newNotif, ...state];
    _save();
    ref.read(notificationCountProvider.notifier).addNotification();
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    _save();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _save();
    ref.read(notificationCountProvider.notifier).markAllAsRead();
  }

  void clearAll() {
    state = [];
    _save();
    ref.read(notificationCountProvider.notifier).markAllAsRead();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final inAppNotificationsProvider = NotifierProvider<InAppNotificationsNotifier, List<NotificationItem>>(() => InAppNotificationsNotifier());

// ==================== RETURN REQUESTS PROVIDER ====================

class ReturnRequestsNotifier extends Notifier<List<ReturnRequest>> {
  @override
  List<ReturnRequest> build() {
    _load();
    return [];
  }

  void _load() {
    final storage = ref.read(storageServiceProvider);
    final data = storage.getJson('return_requests_v1');
    if (data != null && data is List && data.isNotEmpty) {
      try {
        state = data.map((e) => ReturnRequest.fromMap(Map<String, dynamic>.from(e))).toList();
        return;
      } catch (_) {}
    }
    state = [];
  }

  void _save() {
    ref.read(storageServiceProvider).saveJson('return_requests_v1', state.map((r) => r.toMap()).toList());
  }

  void submitRequest({
    required String orderId,
    required String itemId,
    required String productName,
    required String reason,
    String? comments,
  }) {
    final newReq = ReturnRequest(
      returnRequestId: 'RET-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      orderId: orderId,
      itemId: itemId,
      productName: productName,
      reason: reason,
      status: 'Submitted',
      createdAt: DateTime.now(),
      comments: comments,
    );
    state = [newReq, ...state];
    _save();
  }
}

final returnRequestsProvider = NotifierProvider<ReturnRequestsNotifier, List<ReturnRequest>>(() => ReturnRequestsNotifier());

// ==================== PRODUCT REVIEWS & RATINGS NOTIFIER ====================

class ReviewsNotifier extends Notifier<List<ProductReview>> {
  @override
  List<ProductReview> build() {
    final repo = ref.read(reviewRepositoryProvider);
    return repo.getAllReviews();
  }

  void addReview({
    required String productId,
    required double rating,
    required String comment,
    required String userName,
    String userCity = 'Pakistan',
    bool verifiedPurchase = false,
  }) {
    final newReview = ProductReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      userName: userName,
      userCity: userCity,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      verifiedPurchase: verifiedPurchase,
      helpfulCount: 0,
    );
    ref.read(reviewRepositoryProvider).addReview(newReview);
    state = [newReview, ...state];
  }
}

final reviewsProvider = NotifierProvider<ReviewsNotifier, List<ProductReview>>(() => ReviewsNotifier());

final productReviewsProvider = Provider.family<List<ProductReview>, String>((ref, productId) {
  final allReviews = ref.watch(reviewsProvider);
  return allReviews.where((r) => r.productId == productId).toList();
});

final ratingBreakdownProvider = Provider.family<RatingBreakdown, Product>((ref, product) {
  final reviews = ref.watch(productReviewsProvider(product.id));
  return RatingBreakdown.fromReviews(reviews, product.rating);
});

final isProductPurchasedByUserProvider = Provider.family<bool, String>((ref, productId) {
  final orders = ref.watch(ordersProvider);
  for (final order in orders) {
    if (order.items.any((item) => item.product.id == productId)) {
      return true;
    }
  }
  return false;
});

// ==================== PRODUCT QUESTIONS NOTIFIER ====================

class QuestionsNotifier extends Notifier<List<ProductQuestion>> {
  @override
  List<ProductQuestion> build() {
    final repo = ref.read(reviewRepositoryProvider);
    final allProducts = ref.read(productsProvider);
    final allQuestions = <ProductQuestion>[];
    for (final p in allProducts) {
      allQuestions.addAll(repo.getQuestionsForProduct(p.id));
    }
    return allQuestions;
  }

  void askQuestion({
    required String productId,
    required String question,
    required String askedBy,
  }) {
    final newQuestion = ProductQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      question: question,
      askedBy: askedBy,
      answeredBy: 'Verified Merchant',
      createdAt: DateTime.now(),
      answer: 'Thank you for asking! A merchant representative will verify and answer your query shortly.',
      answeredAt: DateTime.now(),
    );
    ref.read(reviewRepositoryProvider).addQuestion(newQuestion);
    state = [newQuestion, ...state];
  }
}

final questionsProvider = NotifierProvider<QuestionsNotifier, List<ProductQuestion>>(() => QuestionsNotifier());

final productQuestionsProvider = Provider.family<List<ProductQuestion>, String>((ref, productId) {
  final all = ref.watch(questionsProvider);
  return all.where((q) => q.productId == productId).toList();
});

// ==================== SMART RECOMMENDATIONS PROVIDERS ====================

final personalizedHomeSectionsProvider = Provider<List<RecommendationSection>>((ref) {
  final catalog = ref.watch(productsProvider);
  final recentlyViewed = ref.watch(recentlyViewedProvider);
  final wishlist = ref.watch(wishlistProvider);
  final orders = ref.watch(ordersProvider);

  return SmartRecommendationService.generateHomeRecommendations(
    catalog: catalog,
    recentlyViewed: recentlyViewed,
    wishlist: wishlist,
    orders: orders,
  );
});

final cartAccessoriesProvider = Provider<List<Product>>((ref) {
  final catalog = ref.watch(productsProvider);
  final cartItems = ref.watch(cartProvider);

  return SmartRecommendationService.getCartRecommendations(
    catalog: catalog,
    cartItems: cartItems,
  );
});

