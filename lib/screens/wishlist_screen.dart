import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist (${wishlist.length})'),
        actions: [
          if (wishlist.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Move all to cart',
              onPressed: () {
                for (final product in wishlist) {
                  ref.read(cartProvider.notifier).addItem(product);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All wishlist items added to cart'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
      body: wishlist.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 72,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Wishlist is Empty',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore our collection and tap the heart icon on any product to save your favorite items!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(bottomNavIndexProvider.notifier).setIndex(0);
                      },
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explore Products'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                return ProductCard(product: wishlist[index]);
              },
            ),
    );
  }
}
