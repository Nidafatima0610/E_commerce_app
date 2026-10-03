import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';
import 'search_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _sortOption = 'default';

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.headphones_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'shoes':
        return Icons.snowshoeing_outlined;
      case 'beauty & care':
      case 'beauty':
        return Icons.spa_outlined;
      case 'home & living':
        return Icons.kitchen_outlined;
      case 'bags & accessories':
      case 'bags':
        return Icons.backpack_outlined;
      case 'watches':
        return Icons.watch_outlined;
      case 'sports & fitness':
      case 'sports':
        return Icons.fitness_center_outlined;
      default:
        return Icons.dashboard_outlined;
    }
  }

  List<Product> _sortProducts(List<Product> products) {
    final list = List<Product>.from(products);
    switch (_sortOption) {
      case 'price_low':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
        list.sort((a, b) => (b.reviewCount * b.rating).compareTo(a.reviewCount * a.rating));
        break;
      case 'discount':
        list.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      case 'newest':
        list.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
        break;
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);
    final allProducts = ref.watch(productsProvider);
    final rawProducts = ref.watch(filteredProductsProvider);
    final products = _sortProducts(rawProducts);

    final allCategories = ['All', ...categories];

    // Determine subcategories for the current selected category
    List<String> subcategories = [];
    if (selectedCategory != null && selectedCategory != 'All') {
      final subcatSet = <String>{};
      for (final p in allProducts) {
        if (p.category.toLowerCase() == selectedCategory.toLowerCase() && p.subcategory.isNotEmpty) {
          subcatSet.add(p.subcategory);
        }
      }
      if (subcatSet.isNotEmpty) {
        subcategories = ['All', ...subcatSet];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Products'),
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
          // Horizontal Category Selector with Icons
          Container(
            height: 52,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: allCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = allCategories[index];
                final isSelected = (selectedCategory == null && cat == 'All') ||
                    (selectedCategory?.toLowerCase() == cat.toLowerCase());

                final count = cat == 'All'
                    ? allProducts.length
                    : allProducts.where((p) => p.category.toLowerCase() == cat.toLowerCase()).length;

                return FilterChip(
                  avatar: Icon(
                    _getCategoryIcon(cat),
                    size: 16,
                    color: isSelected ? Colors.white : theme.colorScheme.primary,
                  ),
                  label: Text('$cat ($count)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(selectedCategoryProvider.notifier).update(cat == 'All' ? null : cat);
                    ref.read(selectedSubcategoryProvider.notifier).update(null);
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                );
              },
            ),
          ),

          // Subcategories bar (if category selected)
          if (subcategories.length > 1)
            Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: subcategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final subcat = subcategories[index];
                  final isSelected = (selectedSubcategory == null && subcat == 'All') ||
                      (selectedSubcategory?.toLowerCase() == subcat.toLowerCase());

                  return FilterChip(
                    label: Text(subcat),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedSubcategoryProvider.notifier).update(subcat == 'All' ? null : subcat);
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.grey[400] : Colors.grey[700]),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
            ),

          // Subheader: count and sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedCategory == null || selectedCategory == 'All'
                        ? 'All Products (${products.length})'
                        : selectedSubcategory != null
                            ? '$selectedSubcategory (${products.length})'
                            : '$selectedCategory (${products.length})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('Default', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'popular',
                        child: Text('Most Popular', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'price_low',
                        child: Text('Price: Low to High', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'price_high',
                        child: Text('Price: High to Low', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: Text('Highest Rated', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'discount',
                        child: Text('Biggest Discount', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Newest First', style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortOption = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Product Grid
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Products in this Category',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore other categories or view all products.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(selectedCategoryProvider.notifier).update(null);
                              ref.read(selectedSubcategoryProvider.notifier).update(null);
                            },
                            child: const Text('View All Products'),
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
}
