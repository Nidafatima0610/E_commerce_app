import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';
import 'search_screen.dart';

enum ProductSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  rating,
}

class ProductListScreen extends ConsumerStatefulWidget {
  final String title;
  final String? initialCategory;
  final bool onlyDeals;
  final bool onlyFeatured;

  const ProductListScreen({
    super.key,
    required this.title,
    this.initialCategory,
    this.onlyDeals = false,
    this.onlyFeatured = false,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late String _selectedCategory;
  ProductSortOption _sortOption = ProductSortOption.featured;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    var list = allProducts;

    if (widget.onlyDeals) {
      list = list.where((p) => p.discountPercentage > 0).toList();
    } else if (widget.onlyFeatured) {
      list = list.where((p) => p.isFeatured).toList();
    }

    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Sort
    final sorted = List<Product>.from(list);
    switch (_sortOption) {
      case ProductSortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.featured:
        sorted.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allProducts = ref.watch(productsProvider);
    final categories = ['All', ...ref.watch(categoriesProvider)];
    final products = _getFilteredProducts(allProducts);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category selector chips
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory.toLowerCase() == category.toLowerCase();

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),

          // Filter bar & Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} Products found',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                PopupMenuButton<ProductSortOption>(
                  initialValue: _sortOption,
                  onSelected: (option) => setState(() => _sortOption = option),
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabel(_sortOption),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ProductSortOption.featured,
                      child: Text('Featured'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.priceLowToHigh,
                      child: Text('Price: Low to High'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.priceHighToLow,
                      child: Text('Price: High to Low'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.rating,
                      child: Text('Highest Rated'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product Grid or Empty State
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try selecting a different category or filter',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = 'All';
                              });
                            },
                            child: const Text('Show All Products'),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.featured:
        return 'Featured';
      case ProductSortOption.priceLowToHigh:
        return 'Price: Low';
      case ProductSortOption.priceHighToLow:
        return 'Price: High';
      case ProductSortOption.rating:
        return 'Top Rated';
    }
  }
}
