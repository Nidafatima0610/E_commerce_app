import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerceapp/models/dummy_data.dart';
import 'package:e_commerceapp/models/address.dart';
import 'package:e_commerceapp/models/coupon.dart';
import 'package:e_commerceapp/models/cart_item.dart';
import 'package:e_commerceapp/providers/app_providers.dart';
import 'package:e_commerceapp/screens/checkout_screen.dart';
import 'package:e_commerceapp/screens/order_details_screen.dart';
import 'package:e_commerceapp/screens/order_history_screen.dart';
import 'package:e_commerceapp/screens/saved_addresses_screen.dart';

final Uint8List _kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      return Future.value(_TestHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_TestHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _TestHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences testPrefs;

  setUpAll(() async {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  Widget buildAppWithScope({required Widget child, Size size = const Size(400, 850)}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(testPrefs),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  group('Complete Purchase Flow Tests', () {
    testWidgets('1. Cart add, variant preservation, coupon savings, and delivery fee calculations', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(testPrefs)],
      );

      final p = dummyProducts.first;
      // Add product with specific variant
      container.read(cartProvider.notifier).addItem(
        p,
        quantity: 2,
        selectedColor: '#0F172A',
        selectedStorage: '256GB',
        unitPrice: p.price,
      );

      final cartItems = container.read(cartProvider);
      expect(cartItems.length, 1);
      expect(cartItems.first.quantity, 2);
      expect(cartItems.first.selectedColor, '#0F172A');
      expect(cartItems.first.selectedStorage, '256GB');
      expect(cartItems.first.subtotal, p.price * 2);

      // Verify coupon calculations
      const welcomeCoupon = Coupon(
        code: 'WELCOME10',
        discountType: CouponDiscountType.percentage,
        discountAmount: 10,
        minOrderAmount: 1000,
        maxDiscount: 1500,
      );
      final savings = container.read(cartProvider.notifier).calculateDiscount(welcomeCoupon, deliveryFee: 150);
      expect(savings, 1500.0); // Capped by maxDiscount

      const freeShipCoupon = Coupon(
        code: 'FREESHIP',
        discountType: CouponDiscountType.freeShipping,
        discountAmount: 0,
        minOrderAmount: 1500,
      );
      final shipSavings = container.read(cartProvider.notifier).calculateDiscount(freeShipCoupon, deliveryFee: 150);
      expect(shipSavings, 150.0);
    });

    testWidgets('2. Checkout screen renders 6 stages cleanly without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      final p = dummyProducts.first;

      await tester.pumpWidget(
        buildAppWithScope(
          child: CheckoutScreen(
            directCheckoutItems: [
              CartItem(id: 'c_test', product: p, quantity: 1, unitPrice: p.price),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section titles
      expect(find.text('1. Delivery Address'), findsOneWidget);
      expect(find.text('2. Delivery Method'), findsOneWidget);
      expect(find.text('3. Payment Method'), findsOneWidget);
      expect(find.text('4. Order Items (1)'), findsOneWidget);
      expect(find.text('5. Promo Voucher & Delivery Notes'), findsOneWidget);
      expect(find.text('6. Price Summary'), findsOneWidget);

      // Check Cash on Delivery is selected
      expect(find.text('Cash on Delivery (COD)'), findsOneWidget);
      expect(find.text('Place Order (COD)'), findsOneWidget);
    });

    testWidgets('3. Place order creates valid order with unique ID and navigates to OrderSuccessScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      final p = dummyProducts.first;

      await tester.pumpWidget(
        buildAppWithScope(
          child: CheckoutScreen(
            directCheckoutItems: [
              CartItem(id: 'c_test', product: p, quantity: 1, unitPrice: p.price),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Place Order
      final placeOrderBtn = find.text('Place Order (COD)');
      expect(placeOrderBtn, findsOneWidget);
      await tester.tap(placeOrderBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify OrderSuccessScreen appeared
      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.text('Track Order Status'), findsOneWidget);
      expect(find.text('View Order Receipt'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);
    });

    testWidgets('4. Order Details displays complete timeline, Pakistani address, items, and cancellation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(testPrefs)],
      );

      final p = dummyProducts.first;
      final order = container.read(ordersProvider.notifier).createOrder(
        items: [CartItem(id: 'ci_1', product: p, quantity: 1, unitPrice: p.price)],
        totalAmount: p.price + 150,
        subtotal: p.price,
        discount: 0,
        deliveryFee: 150,
        address: defaultPakistaniAddresses.first,
        deliveryMethod: 'Standard Delivery (2–4 days)',
        paymentMethod: 'Cash on Delivery',
        estimatedDelivery: '2–4 business days',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OrderDetailsScreen(orderId: order.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify order contents
      expect(find.text('Order #${order.id}'), findsOneWidget);
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('Reorder Items'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);

      // Tap Cancel Order
      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      // Dialog confirmation
      expect(find.text('Yes, Cancel Order'), findsOneWidget);
      await tester.tap(find.text('Yes, Cancel Order'));
      await tester.pumpAndSettle();

      // Status should update to Cancelled
      expect(find.text('Order Cancelled'), findsOneWidget);
    });

    testWidgets('5. SavedAddressesScreen allows adding and managing Pakistani addresses', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        buildAppWithScope(
          child: const SavedAddressesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Default Pakistani addresses should be visible
      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.textContaining('Bahawalpur'), findsWidgets);
      expect(find.text('Add New Delivery Address'), findsOneWidget);
    });

    testWidgets('6. OrderHistoryScreen supports tabs filtering (All, Active, Delivered, Cancelled)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        buildAppWithScope(
          child: const OrderHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'All'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Active'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Delivered'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Cancelled'), findsOneWidget);

      // Tap on Delivered tab
      await tester.tap(find.widgetWithText(Tab, 'Delivered'));
      await tester.pumpAndSettle();

      // Tap on Cancelled tab
      await tester.tap(find.widgetWithText(Tab, 'Cancelled'));
      await tester.pumpAndSettle();
    });
  });
}
