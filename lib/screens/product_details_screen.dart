import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/custom_image.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'product_compare_screen.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  String _selectedSize = 'M';
  Color _selectedColor = const Color(0xFF0F172A);

  final List<Color> _availableColors = [
    const Color(0xFF0F172A), // Midnight Black
    const Color(0xFF2563EB), // Royal Blue
    const Color(0xFF64748B), // Slate Grey
    const Color(0xFFEF4444), // Crimson Red
  ];

  final List<String> _availableSizes = ['S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recentlyViewedProvider.notifier).addProduct(widget.product);
    });
  }

  bool _isFashionOrShoes(String category) {
    final cat = category.toLowerCase();
    return cat == 'fashion' || cat == 'shoes';
  }

  void _showSizeGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Size & Measurement Guide',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Chest / Length', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Shoes (PK/EU)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('S (Small)')),
                        Padding(padding: EdgeInsets.all(8), child: Text('36" - 38"')),
                        Padding(padding: EdgeInsets.all(8), child: Text('39 - 40')),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('M (Medium)')),
                        Padding(padding: EdgeInsets.all(8), child: Text('39" - 41"')),
                        Padding(padding: EdgeInsets.all(8), child: Text('41 - 42')),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('L (Large)')),
                        Padding(padding: EdgeInsets.all(8), child: Text('42" - 44"')),
                        Padding(padding: EdgeInsets.all(8), child: Text('43 - 44')),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('XL (Extra Large)')),
                        Padding(padding: EdgeInsets.all(8), child: Text('45" - 48"')),
                        Padding(padding: EdgeInsets.all(8), child: Text('45 - 46')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '• Standard Pakistani fitting with comfortable stretch\n• Hassle-free 7-day size exchange available across Pakistan',
                  style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wishlist = ref.watch(wishlistProvider);
    final bool inWishlist = wishlist.any((p) => p.id == widget.product.id);
    final allProducts = ref.watch(productsProvider);
    
    // Related products (same category excluding current)
    final relatedProducts = allProducts
        .where((p) => p.category == widget.product.category && p.id != widget.product.id)
        .take(5)
        .toList();

    final images = widget.product.allImages;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.brand),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Compare Product',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductCompareScreen(initialProduct: widget.product),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              inWishlist ? Icons.favorite : Icons.favorite_border,
              color: inWishlist ? const Color(0xFFEF4444) : null,
            ),
            onPressed: () {
              ref.read(wishlistProvider.notifier).toggleWishlist(widget.product);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(inWishlist ? 'Removed from wishlist' : 'Saved to wishlist'),
                  duration: const Duration(milliseconds: 1200),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product link for "${widget.product.name}" copied!'),
                  duration: const Duration(milliseconds: 1200),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. IMAGE GALLERY ====================
            Container(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: CustomNetworkImage(
                      imageUrl: images[_selectedImageIndex],
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isSelected = index == _selectedImageIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedImageIndex = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CustomNetworkImage(imageUrl: images[index]),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

            // ==================== 2. MAIN DETAILS ====================
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand & Category & Compare shortcut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.product.brand.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Availability badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (widget.product.availableStock > 0 ? const Color(0xFF10B981) : Colors.red)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: widget.product.availableStock > 0 ? const Color(0xFF10B981) : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.availableStock > 0
                                  ? 'In Stock (${widget.product.availableStock})'
                                  : 'Out of Stock',
                              style: TextStyle(
                                color: widget.product.availableStock > 0 ? const Color(0xFF10B981) : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Product Name
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating + Reviews
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.product.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.product.reviewCount} verified ratings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price & Discount in Pakistani Rupees
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        CurrencyFormat.format(widget.product.price),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.product.oldPrice != null && widget.product.oldPrice! > widget.product.price) ...[
                        Text(
                          CurrencyFormat.format(widget.product.oldPrice!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ${widget.product.discountPercentage}%',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 32),

                  // ==================== 3. COLOR SELECTION ====================
                  Text(
                    'Color Variant',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _availableColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ==================== 4. SIZE SELECTION (if Fashion/Shoes) ====================
                  if (_isFashionOrShoes(widget.product.category)) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Size',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: () => _showSizeGuide(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.straighten_outlined, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Size Guide',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _availableSizes.map((size) {
                        final isSelected = _selectedSize == size;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSize = size),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              size,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ==================== 5. QUANTITY SELECTOR ====================
                  Text(
                    'Quantity',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            if (_quantity < widget.product.availableStock) {
                              setState(() => _quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),

                  // ==================== 6. DESCRIPTION ====================
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const Divider(height: 32),

                  // ==================== 7. SPECIFICATIONS ====================
                  Text(
                    'Product Specifications',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSpecRow(theme, 'Brand', widget.product.brand),
                  _buildSpecRow(theme, 'Category', widget.product.category),
                  _buildSpecRow(theme, 'SKU Code', '#${widget.product.id.toUpperCase()}'),
                  _buildSpecRow(theme, 'Warranty', '1 Year Official Brand Warranty'),
                  _buildSpecRow(theme, 'Delivery', 'TCS / Leopards Courier (2-4 business days)'),
                  _buildSpecRow(theme, 'Cash on Delivery', 'Available nationwide'),
                  _buildSpecRow(theme, 'Returns', '7 Days Hassle-Free Exchange / Return'),
                  const Divider(height: 32),

                  // ==================== 8. RELATED PRODUCTS ====================
                  if (relatedProducts.isNotEmpty) ...[
                    Text(
                      'You Might Also Like',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 285,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: relatedProducts[index],
                            width: 175,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // ==================== 9. FIXED BOTTOM ACTION BAR ====================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              // Total Price
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      CurrencyFormat.format(widget.product.price * _quantity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Add To Cart Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    for (int i = 0; i < _quantity; i++) {
                      ref.read(cartProvider.notifier).addItem(widget.product);
                    }
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $_quantity item(s) to cart'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'View Cart',
                          textColor: Colors.white,
                          onPressed: () {
                            ref.read(bottomNavIndexProvider.notifier).setIndex(2);
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text('Add to Cart', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Buy Now Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    for (int i = 0; i < _quantity; i++) {
                      ref.read(cartProvider.notifier).addItem(widget.product);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  child: const Text('Buy Now', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
