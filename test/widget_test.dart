import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerceapp/main.dart';
import 'package:e_commerceapp/providers/app_providers.dart';
import 'package:e_commerceapp/screens/home_screen.dart';
import 'package:e_commerceapp/screens/categories_screen.dart';
import 'package:e_commerceapp/screens/cart_screen.dart';
import 'package:e_commerceapp/screens/wishlist_screen.dart';
import 'package:e_commerceapp/screens/profile_screen.dart';
import 'package:e_commerceapp/screens/search_screen.dart';
import 'package:e_commerceapp/screens/product_details_screen.dart';
import 'package:e_commerceapp/models/dummy_data.dart';

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
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
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

  Widget createTestWidget({required Widget child, Size screenSize = const Size(360, 640)}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(testPrefs),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: child,
        ),
      ),
    );
  }

  group('Small Screen Android Responsiveness Tests (360x640)', () {
    testWidgets('HomeScreen renders with zero overflow on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const HomeScreen(), screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Popular Products'), findsOneWidget);
      expect(find.text('Flash Deals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoriesScreen renders with zero overflow on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const CategoriesScreen(), screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Categories & Products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CartScreen empty state renders with zero overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const CartScreen(), screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WishlistScreen empty state renders with zero overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const WishlistScreen(), screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Your Wishlist is Empty'), findsOneWidget);
      expect(find.text('Explore Products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen renders with zero overflow on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const ProfileScreen(), screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Umair'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SearchScreen renders with zero overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const SearchScreen(), screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Headphones'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductDetailsScreen renders with zero overflow on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        child: ProductDetailsScreen(product: dummyProducts.first),
        screenSize: const Size(360, 640),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(dummyProducts.first.name), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Full Application Navigation Flow', () {
    testWidgets('MyApp boots and switches tabs cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(testPrefs),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Home Screen visible
      expect(find.text('Popular Products'), findsOneWidget);

      // Tap Categories Tab
      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Categories & Products'), findsOneWidget);

      // Tap Cart Tab
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Your Cart is Empty'), findsOneWidget);

      // Tap Wishlist Tab
      await tester.tap(find.byIcon(Icons.favorite_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Your Wishlist is Empty'), findsOneWidget);

      // Tap Profile Tab
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Umair'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('Normal and Large Screen Android Responsiveness Tests', () {
    testWidgets('Normal Android Phone (390x844) renders with zero overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const HomeScreen(), screenSize: const Size(390, 844)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Popular Products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Large Android Phone (412x915) renders with zero overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const HomeScreen(), screenSize: const Size(412, 915)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Popular Products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

