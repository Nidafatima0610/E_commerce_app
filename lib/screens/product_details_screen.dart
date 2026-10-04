import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/product_image.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'product_compare_screen.dart';
import 'reviews_screen.dart';
import 'product_list_screen.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  late final PageController _pageController;
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedStorage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.product.colors.isNotEmpty) {
      _selectedColor = widget.product.colors.first;
    }
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
    if (widget.product.storageOptions.isNotEmpty) {
      _selectedStorage = widget.product.storageOptions.first;
    }
    Future.microtask(() {
      ref.read(recentlyViewedProvider.notifier).addProduct(widget.product);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  bool _validateVariants() {
    if (widget.product.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size before proceeding'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    if (widget.product.storageOptions.isNotEmpty && _selectedStorage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a storage option before proceeding'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  void _handleAddToCart() {
    if (!_validateVariants()) return;

    final unitPrice = widget.product.getPriceForVariants(
      storage: _selectedStorage,
      size: _selectedSize,
    );

    ref.read(cartProvider.notifier).addItem(
      widget.product,
      quantity: _quantity,
      selectedColor: _selectedColor,
      selectedSize: _selectedSize,
      selectedStorage: _selectedStorage,
      unitPrice: unitPrice,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity x ${widget.product.name} to cart'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            ref.read(bottomNavIndexProvider.notifier).setIndex(2);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _handleBuyNow() {
    if (!_validateVariants()) return;

    final unitPrice = widget.product.getPriceForVariants(
      storage: _selectedStorage,
      size: _selectedSize,
    );

    final checkoutItem = CartItem(
      id: 'buynow_${DateTime.now().millisecondsSinceEpoch}',
      product: widget.product,
      quantity: _quantity,
      selectedColor: _selectedColor,
      selectedSize: _selectedSize,
      selectedStorage: _selectedStorage,
      unitPrice: unitPrice,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(directCheckoutItems: [checkoutItem]),
      ),
    );
  }

  void _openFullscreenViewer(BuildContext context, int initialIndex) {
    final images = widget.product.allImages;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          int currentIndex = initialIndex;
          final viewerController = PageController(initialPage: initialIndex);
          return StatefulBuilder(
            builder: (context, setViewerState) {
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(
                    '${currentIndex + 1} / ${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                body: PageView.builder(
                  controller: viewerController,
                  itemCount: images.length,
                  onPageChanged: (page) => setViewerState(() => currentIndex = page),
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: ProductImage(
                          imageUrl: images[index],
                          category: widget.product.category,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final shareText = '${widget.product.name} - ${CurrencyFormat.format(widget.product.price)}\n${widget.product.description}\nProduct Link: https://ecommerce.pk/product/${widget.product.id}';

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
                title: const Text('Copy Product Link & Details', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('https://ecommerce.pk/product/${widget.product.id}'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Details for "${widget.product.name}" copied to clipboard!'),
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
                title: const Text('Share to WhatsApp / Messaging', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Copy formatted recommendation to paste into WhatsApp'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share text copied! Ready to paste in WhatsApp or messaging app.'),
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

  void _openStoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.product.sellerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verified Merchant on Pakistan E-Commerce Platform',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '• Merchant Rating: ★ ${widget.product.sellerRating} / 5.0 (99% Positive)\n'
              '• Fast Dispatch: Ships within 24 hours via TCS & Leopards\n'
              '• Returns: 7-Day Doorstep Replacement Guarantee\n'
              '• Authentic: 100% genuine brand stock verified by platform',
              style: const TextStyle(fontSize: 12.5, height: 1.5, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(
                    title: widget.product.sellerName,
                    initialCategory: widget.product.category,
                  ),
                ),
              );
            },
            child: const Text('View Store Products'),
          ),
        ],
      ),
    );
  }

  void _openAskQuestionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Ask a Question'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have a question about "${widget.product.name}"? The verified seller will respond to your inquiry.',
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Is PTA duty paid? What is the warranty claim procedure?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final userProfile = ref.read(userProfileProvider);
                ref.read(questionsProvider.notifier).askQuestion(
                  productId: widget.product.id,
                  question: text,
                  askedBy: userProfile.name.isNotEmpty ? userProfile.name : 'Customer',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your question has been submitted to the merchant!'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit Question'),
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
    final recentlyViewed = ref.watch(recentlyViewedProvider);

    // Dynamic unit price considering variants
    final double currentPrice = widget.product.getPriceForVariants(
      storage: _selectedStorage,
      size: _selectedSize,
    );
    final double subtotalPrice = currentPrice * _quantity;

    // Related products using smart repository algorithm
    final relatedProducts = ref.watch(productRepositoryProvider).getRelatedProducts(widget.product, limit: 6);
    final productReviews = ref.watch(productReviewsProvider(widget.product.id));
    final breakdown = ref.watch(ratingBreakdownProvider(widget.product));
    final productQuestions = ref.watch(productQuestionsProvider(widget.product.id));
    final isPurchased = ref.watch(isProductPurchasedByUserProvider(widget.product.id));

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
            tooltip: inWishlist ? 'Remove from wishlist' : 'Save to wishlist',
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
            tooltip: 'Share Product',
            onPressed: () => _showShareSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. IMAGE GALLERY WITH SWIPE & THUMBNAILS ====================
            Container(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() => _selectedImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _openFullscreenViewer(context, index),
                              child: ProductImage(
                                imageUrl: images[index],
                                category: widget.product.category,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                        // Page indicator & zoom hint
                        Positioned(
                          bottom: 12,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _openFullscreenViewer(context, _selectedImageIndex),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_selectedImageIndex + 1}/${images.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Thumbnails row with interactive selection
                  if (images.length > 1)
                    Container(
                      height: 56,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      alignment: Alignment.center,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: images.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedImageIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedImageIndex = index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                  width: 2.2,
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
                        },
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
                  // Brand & Stock Status Row
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
                              widget.product.availableStock > 0 ? Icons.check_circle_outline : Icons.error_outline,
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

                  // Rating + Reviews (Tappable to ReviewsScreen)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsScreen(product: widget.product),
                        ),
                      );
                    },
                    child: Wrap(
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
                                '${breakdown.averageRating}',
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
                          '${breakdown.totalCount > 0 ? breakdown.totalCount : widget.product.reviewCount} verified reviews across Pakistan • View All ›',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price & Discount in Pakistani Rupees
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        CurrencyFormat.format(currentPrice),
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

                  // ==================== 3. STORAGE SELECTION (If applicable) ====================
                  if (widget.product.storageOptions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Storage Option',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_selectedStorage != null)
                          Text(
                            _selectedStorage!,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: widget.product.storageOptions.map((storage) {
                        final isSelected = _selectedStorage == storage;
                        return ChoiceChip(
                          label: Text(storage),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedStorage = storage);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ==================== 4. COLOR SELECTION (Only if product has colors) ====================
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
                              width: 30,
                              height: 30,
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

                  // ==================== 5. SIZE SELECTION (Only if product has sizes) ====================
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

                  // ==================== 6. QUANTITY SELECTOR ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Subtotal: ${CurrencyFormat.format(subtotalPrice)}',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: _quantity < widget.product.availableStock
                                  ? () => setState(() => _quantity++)
                                  : () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cannot add more. Only ${widget.product.availableStock} in stock.'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // ==================== 7. DESCRIPTION ====================
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

                  // ==================== 8. SPECIFICATIONS ====================
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

                  // ==================== 9. TRUST BADGES & GUARANTEES ====================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('100% Authentic & Original Guarantee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Directly sourced from verified Pakistani distributors', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.replay_rounded, color: Color(0xFF3B82F6), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('7 Days Hassle-Free Return & Exchange', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Doorstep return pickup available across Pakistan', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_rounded, color: Color(0xFFF59E0B), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.product.deliveryInfo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Cash on Delivery available nationwide via TCS', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.security_rounded, color: Color(0xFF8B5CF6), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('1 Year Official Brand Warranty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Valid at authorized repair centers across Pakistan', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================== 10. SELLER & STORE CARD ====================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: Icon(Icons.storefront_rounded, color: theme.colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.product.sellerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'VERIFIED',
                                          style: TextStyle(color: Color(0xFF047857), fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '★ ${widget.product.sellerRating} Merchant Rating • 99% Positive Response',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openStoreDialog(context),
                                icon: const Icon(Icons.info_outline_rounded, size: 16),
                                label: const Text('Store Info', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductListScreen(
                                        title: widget.product.sellerName,
                                        initialCategory: widget.product.category,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                label: const Text('View Products', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== 11. CUSTOMER REVIEWS & RATINGS PREVIEW ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Customer Reviews',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReviewsScreen(product: widget.product),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  if (isPurchased) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You purchased this product! Your reviews will receive a Verified Purchase badge.',
                              style: TextStyle(color: Color(0xFF047857), fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  if (productReviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.rate_review_outlined, size: 36, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('No reviews yet for this product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Be the first customer in Pakistan to leave a review!', style: TextStyle(color: Colors.grey[600], fontSize: 11.5)),
                        ],
                      ),
                    )
                  else ...[
                    for (final rev in productReviews.take(2)) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Text(rev.userName[0], style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                          ),
                                          if (rev.verifiedPurchase) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified, size: 12, color: Color(0xFF10B981)),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        rev.userCity,
                                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                    Text('${rev.rating.toInt()}★', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rev.comment,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),

                  // ==================== 12. PRODUCT QUESTIONS & ANSWERS (Q&A) ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Questions & Answers (${productQuestions.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openAskQuestionDialog(context),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Ask Question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (productQuestions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Text('No questions asked yet. Tap "Ask Question" to inquiry directly with the merchant.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  else ...[
                    for (final q in productQuestions.take(3)) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Q: ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    q.question,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                            if (q.isAnswered) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('A: ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 13)),
                                  Expanded(
                                    child: Text(
                                      q.answer!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[300] : Colors.grey[750],
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Answered by ${q.answeredBy}',
                                style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // ==================== 10. RELATED PRODUCTS ====================
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

                  // ==================== 11. RECENTLY VIEWED ====================
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
                  onPressed: widget.product.isOutOfStock ? null : _handleAddToCart,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(widget.product.isOutOfStock ? 'Out of Stock' : 'Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.product.isOutOfStock ? null : _handleBuyNow,
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: Text(widget.product.isOutOfStock ? 'Unavailable' : 'Buy Now'),
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
