import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import '../providers/app_providers.dart';

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    CartScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final cartItems = ref.watch(cartProvider);
    final totalCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).setIndex(index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: totalCount > 0,
              label: Text(totalCount.toString()),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: totalCount > 0,
              label: Text(totalCount.toString()),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: wishlist.isNotEmpty,
              label: Text(wishlist.length.toString()),
              child: const Icon(Icons.favorite_outline_rounded),
            ),
            activeIcon: Badge(
              isLabelVisible: wishlist.isNotEmpty,
              label: Text(wishlist.length.toString()),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Wishlist',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
