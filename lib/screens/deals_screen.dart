import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/product_image.dart';
import '../widgets/quick_add_modal.dart';
import 'product_details_screen.dart';

class DealsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final int initialTabIndex;

  const DealsScreen({
    super.key,
    this.initialCategory,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration(hours: 7, minutes: 42, seconds: 15);

  String? _selectedCategory;
  String _sortBy = 'discount'; // 'discount', 'popular', 'price_low', 'newest'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _selectedCategory = widget.initialCategory;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _timeLeft = const Duration(hours: 24);
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatCountdown() {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  List<Product> _filterAndSortProducts(List<Product> allProducts, int tabIndex) {
    // Tab 0: Flash Deals (isDeal == true)
    // Tab 1: Today's Deals (discountPercentage >= 20)
    // Tab 2: Big Discounts (discountPercentage >= 35)
    // Tab 3: Clearance (availableStock <= 15 and has discount)
    var list = allProducts.where((p) {
      switch (tabIndex) {
        case 0:
          return p.isDeal || p.discountPercentage >= 25;
        case 1:
          return p.discountPercentage >= 15;
        case 2:
          return p.discountPercentage >= 30;
        case 3:
          return p.availableStock <= 20 && p.discountPercentage > 0;
        default:
          return p.discountPercentage > 0;
      }
    }).toList();

    // Category filter
    if (_selectedCategory != null) {
      list = list.where((p) => p.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'discount':
        list.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      case 'popular':
        list.sort((a, b) => (b.reviewCount * b.rating).compareTo(a.reviewCount * a.rating));
        break;
      case 'price_low':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'newest':
        list.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allProducts = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exclusive Deals & Offers'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFFEF4444),
          indicatorWeight: 3,
          labelColor: const Color(0xFFEF4444),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(text: '⚡ Flash Deals'),
            Tab(text: '🔥 Today\'s Deals'),
            Tab(text: '🎉 Big Discounts (30%+)'),
            Tab(text: '🏷️ Clearance'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ==================== 1. COUNTDOWN TICKER BANNER ====================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                    : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Limited Time Promotional Event',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF991B1B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatCountdown(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================== 2. CATEGORY CHIPS & SORT BAR ====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Categories'),
                          selected: _selectedCategory == null,
                          onSelected: (_) => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        for (final cat in categories) ...[
                          ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = selected ? cat : null);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Dropdown
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  items: const [
                    DropdownMenuItem(value: 'discount', child: Text('Max Discount')),
                    DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                    DropdownMenuItem(value: 'price_low', child: Text('Price: Low')),
                    DropdownMenuItem(value: 'newest', child: Text('Newest Drops')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 12),

          // ==================== 3. DEALS TAB VIEW ====================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) {
                final deals = _filterAndSortProducts(allProducts, index);
                if (deals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No deals found for this filter',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try selecting "All Categories" or check back later for fresh discounts!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _selectedCategory = null),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset Category Filter'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.64,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: deals.length,
                  itemBuilder: (context, i) {
                    final product = deals[i];
                    return _DealProductCard(product: product);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealProductCard extends ConsumerWidget {
  final Product product;

  const _DealProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wishlist = ref.watch(wishlistProvider);
    final inWishlist = wishlist.any((p) => p.id == product.id);

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
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Badges
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ProductImage(
                        imageUrl: product.image,
                        category: product.category,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Discount Badge
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist Heart Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          ref.read(wishlistProvider.notifier).toggleWishlist(product);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            inWishlist ? Icons.favorite : Icons.favorite_border,
                            color: inWishlist ? const Color(0xFFEF4444) : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 3),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Row(
                    children: [
                      Text(
                        CurrencyFormat.format(product.price),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      if (product.oldPrice != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            CurrencyFormat.format(product.oldPrice!),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stock claim bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (1.0 - (product.availableStock / 40)).clamp(0.2, 0.95),
                      minHeight: 4,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: product.isOutOfStock
                          ? null
                          : () {
                              if (product.hasVariants) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (ctx) => QuickAddModal(product: product),
                                );
                              } else {
                                ref.read(cartProvider.notifier).addItem(product);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${product.name} to cart!'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.add_shopping_cart, size: 14),
                      label: Text(
                        product.isOutOfStock ? 'Sold Out' : 'Quick Add',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
