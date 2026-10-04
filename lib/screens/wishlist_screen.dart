import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/quick_add_modal.dart';
import '../core/currency_format.dart';
import 'product_details_screen.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _isGridView = true;
  String _sortBy = 'Recently Added';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final wishlist = ref.watch(wishlistProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = ['All', ...wishlist.map((p) => p.category).toSet()];
    var displayedWishlist = List<Product>.from(wishlist);
    if (_selectedCategory != 'All') {
      displayedWishlist = displayedWishlist
          .where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }
    switch (_sortBy) {
      case 'Price Low → High':
        displayedWishlist.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High → Low':
        displayedWishlist.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Highest Rated':
        displayedWishlist.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Recently Added':
      default:
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist (${wishlist.length})'),
        actions: [
          if (wishlist.isNotEmpty) ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
              tooltip: _isGridView ? 'List View' : 'Grid View',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Move all to cart',
              onPressed: () {
                for (final product in wishlist) {
                  if (!product.hasVariants) {
                    ref.read(cartProvider.notifier).addItem(product);
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wishlist items added to cart'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear wishlist',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Wishlist'),
                    content: const Text('Are you sure you want to remove all saved items?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          for (final p in List.from(wishlist)) {
                            ref.read(wishlistProvider.notifier).removeFromWishlist(p.id);
                          }
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
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
                      'No saved items yet. Explore products across 9 categories and tap the heart icon to save your favorites!',
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
          : Column(
              children: [
                // Filter & Sort Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedCategory = cat);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort_rounded, size: 20),
                        tooltip: 'Sort Wishlist',
                        initialValue: _sortBy,
                        onSelected: (val) => setState(() => _sortBy = val),
                        itemBuilder: (context) => [
                          'Recently Added',
                          'Price Low → High',
                          'Price High → Low',
                          'Highest Rated',
                        ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                      ),
                    ],
                  ),
                ),

                // Wishlist Items or Category Empty State
                Expanded(
                  child: displayedWishlist.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_alt_off_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No saved items in "$_selectedCategory"',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => setState(() => _selectedCategory = 'All'),
                                  child: const Text('Show All Items'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _isGridView
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: displayedWishlist.length,
                              itemBuilder: (context, index) {
                                return ProductCard(product: displayedWishlist[index]);
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedWishlist.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final product = displayedWishlist[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailsScreen(product: product),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 80,
                                            height: 80,
                                            child: ProductImage(
                                              imageUrl: product.image,
                                              category: product.category,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.brand,
                                                style: TextStyle(
                                                  color: theme.colorScheme.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                product.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    CurrencyFormat.format(product.price),
                                                    style: TextStyle(
                                                      color: theme.colorScheme.primary,
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (product.oldPrice != null && product.oldPrice! > product.price) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      CurrencyFormat.format(product.oldPrice!),
                                                      style: const TextStyle(
                                                        decoration: TextDecoration.lineThrough,
                                                        color: Colors.grey,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: product.isOutOfStock
                                                        ? null
                                                        : () {
                                                            if (product.hasVariants) {
                                                              QuickAddModal.show(context, product);
                                                            } else {
                                                              ref.read(cartProvider.notifier).addItem(product);
                                                              ref.read(wishlistProvider.notifier).removeFromWishlist(product.id);
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Moved ${product.name} to cart'),
                                                                  behavior: SnackBarBehavior.floating,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                    icon: const Icon(Icons.add_shopping_cart, size: 14),
                                                    label: const Text('Move to Cart', style: TextStyle(fontSize: 11.5)),
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    icon: const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 20),
                                                    onPressed: () {
                                                      ref.read(wishlistProvider.notifier).removeFromWishlist(product.id);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
