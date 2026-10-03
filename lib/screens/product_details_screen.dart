import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/product_image.dart';
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
  String? _selectedSize;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
    if (widget.product.colors.isNotEmpty) {
      _selectedColor = widget.product.colors.first;
    }
    Future.microtask(() {
      ref.read(recentlyViewedProvider.notifier).addProduct(widget.product);
    });
  }

  Color _parseColorHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF0F172A);
    }
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Share Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.copy_rounded, color: Color(0xFF10B981)),
                ),
                title: const Text('Copy Product Link', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('https://ecommerce.pk/product/${widget.product.id}'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product link for "${widget.product.name}" copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                ),
                title: const Text('Share to WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send to friends and family'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening WhatsApp to share product...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildSpecRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wishlist = ref.watch(wishlistProvider);
    final bool inWishlist = wishlist.any((p) => p.id == widget.product.id);
    final allProducts = ref.watch(productsProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);

    // Related products (same category excluding current)
    final relatedProducts = allProducts
        .where((p) => p.category == widget.product.category && p.id != widget.product.id)
        .take(6)
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
            onPressed: () => _showShareSheet(context),
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
                    aspectRatio: 1.25,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ProductImage(
                          imageUrl: images[_selectedImageIndex],
                          category: widget.product.category,
                          fit: BoxFit.contain,
                          enableZoomOnTap: true,
                        ),
                        Positioned(
                          bottom: 12,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedImageIndex + 1}/${images.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isSelected = index == _selectedImageIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedImageIndex = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: ProductImage(
                                  imageUrl: images[index],
                                  category: widget.product.category,
                                  fit: BoxFit.cover,
                                ),
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
                  // Brand, Category & Stock Status
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
                              widget.product.stockStatus,
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
                  const SizedBox(height: 10),

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

                  // ==================== 3. COLOR SELECTION (Only if product has colors) ====================
                  if (widget.product.colors.isNotEmpty) ...[
                    Text(
                      'Available Colors',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: widget.product.colors.map((colorHex) {
                        final isSelected = _selectedColor == colorHex;
                        final color = _parseColorHex(colorHex);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = colorHex),
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
                                border: Border.all(color: Colors.black12),
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
                  ],

                  // ==================== 4. SIZE SELECTION (Only if product has sizes) ====================
                  if (widget.product.sizes.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Size',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _showSizeGuide(context),
                          icon: const Icon(Icons.straighten, size: 16),
                          label: const Text('Size Guide'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: widget.product.sizes.map((size) {
                        final isSelected = _selectedSize == size;
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSize = size);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ==================== 5. QUANTITY SELECTOR ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _quantity < widget.product.availableStock
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // ==================== 6. DESCRIPTION ====================
                  Text(
                    'About this Product',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================== 7. SPECIFICATIONS ====================
                  if (widget.product.specifications.isNotEmpty) ...[
                    Text(
                      'Technical Specifications',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSpecRow(theme, 'SKU Code', '#${widget.product.id.toUpperCase()}'),
                          _buildSpecRow(theme, 'Category', '${widget.product.category} • ${widget.product.subcategory}'),
                          _buildSpecRow(theme, 'Brand', widget.product.brand),
                          for (final entry in widget.product.specifications.entries)
                            _buildSpecRow(theme, entry.key, entry.value),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ==================== 8. DELIVERY & SELLER ====================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.product.deliveryInfo,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 20, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.sellerName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '★ ${widget.product.sellerRating} Merchant Rating • 99% Positive Feedback',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '100% Genuine Guarantee • 7 Days Hassle-Free Returns',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ==================== 9. RELATED PRODUCTS ====================
                  if (relatedProducts.isNotEmpty) ...[
                    Text(
                      'Similar in ${widget.product.category}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 275,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          return ProductCard(product: relatedProducts[index], width: 175);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ==================== 10. RECENTLY VIEWED ====================
                  if (recentlyViewed.length > 1) ...[
                    Text(
                      'Recently Viewed',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 275,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentlyViewed.where((p) => p.id != widget.product.id).length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final p = recentlyViewed.where((item) => item.id != widget.product.id).toList()[index];
                          return ProductCard(product: p, width: 175);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.product.isOutOfStock
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).addItem(widget.product, quantity: _quantity);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $_quantity ${widget.product.name} to cart'),
                              duration: const Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.product.isOutOfStock
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).addItem(widget.product, quantity: _quantity);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                          );
                        },
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text('Buy Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
