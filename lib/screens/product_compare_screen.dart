import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/custom_image.dart';

class ProductCompareScreen extends ConsumerWidget {
  final Product initialProduct;

  const ProductCompareScreen({super.key, required this.initialProduct});

  void _showAddProductModal(BuildContext context, WidgetRef ref) {
    final allProducts = ref.read(productsProvider);
    final compareList = ref.read(compareProvider);
    final candidates = allProducts
        .where((p) => p.category == initialProduct.category && !compareList.any((cp) => cp.id == p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add to Compare (${initialProduct.category})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                      child: Text('No more items in this category to compare.'),
                    )
                  : ListView.separated(
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = candidates[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: CustomNetworkImage(imageUrl: product.image),
                            ),
                          ),
                          title: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          subtitle: Text(
                            CurrencyFormat.format(product.price),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              ref.read(compareProvider.notifier).toggleProduct(product);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(64, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Add', style: TextStyle(fontSize: 12)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final compareList = ref.watch(compareProvider);

    // Ensure initialProduct is in the list
    final List<Product> activeProducts = compareList.isEmpty ? [initialProduct] : compareList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Comparison'),
        actions: [
          if (activeProducts.length > 1)
            TextButton(
              onPressed: () => ref.read(compareProvider.notifier).clear(),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top guidance message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Comparing side-by-side specifications for ${initialProduct.category}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Comparison Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...activeProducts.map((product) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Image + Remove button
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 130,
                                  child: CustomNetworkImage(
                                    imageUrl: product.image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (activeProducts.length > 1)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color: Colors.black54,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () {
                                        ref.read(compareProvider.notifier).removeProduct(product.id);
                                      },
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Brand & Name
                          Text(
                            product.brand.toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            CurrencyFormat.format(product.price),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          if (product.oldPrice != null && product.oldPrice! > product.price)
                            Text(
                              CurrencyFormat.format(product.oldPrice!),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          const Divider(height: 20),

                          // Spec Rows
                          _buildSpecItem('Rating', '★ ${product.rating} (${product.reviewCount})'),
                          _buildSpecItem('Stock', product.availableStock > 0 ? '${product.availableStock} in stock' : 'Out of stock'),
                          _buildSpecItem('Warranty', '1 Year Official'),
                          _buildSpecItem('Delivery', '2-4 Business Days'),
                          _buildSpecItem('Payment', 'Cash on Delivery (COD)'),
                          const SizedBox(height: 14),

                          // Add to Cart CTA
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref.read(cartProvider.notifier).addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${product.name} to cart'),
                                    duration: const Duration(milliseconds: 1400),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 14),
                              label: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add another product button (if < 3 products)
                  if (activeProducts.length < 3)
                    GestureDetector(
                      onTap: () => _showAddProductModal(context, ref),
                      child: Container(
                        width: 160,
                        height: 380,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_rounded, size: 28, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add Product\nto Compare',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Up to 3 items',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
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

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}
