import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';
import '../core/currency_format.dart';
import 'search_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _sortOption = 'default';
  double _maxPrice = 500000.0;
  bool _onlyInStock = false;
  String? _selectedBrand;

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

  double _minRating = 0.0;
  double _minDiscount = 0.0;
  bool _onlyNewArrivals = false;

  void _resetFilters() {
    setState(() {
      _maxPrice = 500000.0;
      _onlyInStock = false;
      _selectedBrand = null;
      _minRating = 0.0;
      _minDiscount = 0.0;
      _onlyNewArrivals = false;
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_maxPrice < 500000.0) count++;
    if (_onlyInStock) count++;
    if (_selectedBrand != null) count++;
    if (_minRating > 0) count++;
    if (_minDiscount > 0) count++;
    if (_onlyNewArrivals) count++;
    return count;
  }

  List<Product> _filterAndSortProducts(List<Product> products) {
    var filtered = products.where((p) {
      if (p.price > _maxPrice) return false;
      if (_onlyInStock && p.availableStock <= 0) return false;
      if (_selectedBrand != null && p.brand.toLowerCase() != _selectedBrand!.toLowerCase()) return false;
      if (p.rating < _minRating) return false;
      if (p.discountPercentage < _minDiscount) return false;
      if (_onlyNewArrivals && !p.isNewArrival) return false;
      return true;
    }).toList();

    switch (_sortOption) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
        filtered.sort((a, b) => (b.reviewCount * b.rating).compareTo(a.reviewCount * a.rating));
        break;
      case 'discount':
        filtered.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      case 'newest':
        filtered.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
        break;
      default:
        break;
    }
    return filtered;
  }

  String _getSortOptionShortLabel(String option) {
    switch (option) {
      case 'popular':
        return 'Popular';
      case 'price_low':
        return 'Price: Low';
      case 'price_high':
        return 'Price: High';
      case 'rating':
        return 'Rating';
      case 'discount':
        return 'Discount';
      case 'newest':
        return 'Newest';
      default:
        return 'Sort';
    }
  }

  void _showFilterModal(BuildContext context, List<Product> baseProducts) {
    final brands = <String>{};
    for (final p in baseProducts) {
      if (p.brand.isNotEmpty && p.brand != 'General') brands.add(p.brand);
    }
    final sortedBrands = brands.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Category Products',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _resetFilters();
                            });
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Price Slider
                    Text(
                      'Max Price: ${CurrencyFormat.format(_maxPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Slider(
                      value: _maxPrice,
                      min: 1000.0,
                      max: 500000.0,
                      divisions: 50,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() => _maxPrice = val);
                        setState(() => _maxPrice = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // In Stock Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('In-Stock Products Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      value: _onlyInStock,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() => _onlyInStock = val);
                        setState(() => _onlyInStock = val);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('New Arrivals Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      value: _onlyNewArrivals,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() => _onlyNewArrivals = val);
                        setState(() => _onlyNewArrivals = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Customer Rating Filter
                    const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any'),
                          selected: _minRating == 0.0,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _minRating = 0.0);
                              setState(() => _minRating = 0.0);
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('4.5★ & up'),
                          selected: _minRating == 4.5,
                          onSelected: (selected) {
                            final val = selected ? 4.5 : 0.0;
                            setModalState(() => _minRating = val);
                            setState(() => _minRating = val);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('4.0★ & up'),
                          selected: _minRating == 4.0,
                          onSelected: (selected) {
                            final val = selected ? 4.0 : 0.0;
                            setModalState(() => _minRating = val);
                            setState(() => _minRating = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Discount Filter
                    const Text('Discount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Discounts'),
                          selected: _minDiscount == 0.0,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _minDiscount = 0.0);
                              setState(() => _minDiscount = 0.0);
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('10%+ Off'),
                          selected: _minDiscount == 10.0,
                          onSelected: (selected) {
                            final val = selected ? 10.0 : 0.0;
                            setModalState(() => _minDiscount = val);
                            setState(() => _minDiscount = val);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('20%+ Off'),
                          selected: _minDiscount == 20.0,
                          onSelected: (selected) {
                            final val = selected ? 20.0 : 0.0;
                            setModalState(() => _minDiscount = val);
                            setState(() => _minDiscount = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Brands
                    if (sortedBrands.isNotEmpty) ...[
                      const Text('Filter by Brand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sortedBrands.map((b) {
                          final isSelected = _selectedBrand == b;
                          return ChoiceChip(
                            label: Text(b),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() => _selectedBrand = selected ? b : null);
                              setState(() => _selectedBrand = selected ? b : null);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);
    final categoryItems = ref.watch(categoryItemsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);
    final allProducts = ref.watch(productsProvider);
    final rawProducts = ref.watch(filteredProductsProvider);
    final products = _filterAndSortProducts(rawProducts);

    final allCategories = ['All', ...categories];

    // Find category metadata
    final matchedCategoryItem = selectedCategory == null || selectedCategory == 'All'
        ? null
        : categoryItems.where((c) => c.name.toLowerCase() == selectedCategory.toLowerCase()).firstOrNull;

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

    final activeFilters = _activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search catalog',
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
                    _resetFilters();
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

          // Category Subtitle/Description (if present)
          if (matchedCategoryItem != null && matchedCategoryItem.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  matchedCategoryItem.description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Subheader: count, sort, and filter button
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter Button
                    OutlinedButton.icon(
                      onPressed: () => _showFilterModal(context, rawProducts),
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: Text(
                        activeFilters > 0 ? 'Filter ($activeFilters)' : 'Filter',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort Button
                    PopupMenuButton<String>(
                      initialValue: _sortOption,
                      tooltip: 'Sort options',
                      onSelected: (value) => setState(() => _sortOption = value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _getSortOptionShortLabel(_sortOption),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'default', child: Text('Default', style: TextStyle(fontSize: 12.5))),
                        PopupMenuItem(value: 'popular', child: Text('Most Popular', style: TextStyle(fontSize: 12.5))),
                        PopupMenuItem(value: 'price_low', child: Text('Price: Low to High', style: TextStyle(fontSize: 12.5))),
                        PopupMenuItem(value: 'price_high', child: Text('Price: High to Low', style: TextStyle(fontSize: 12.5))),
                        PopupMenuItem(value: 'rating', child: Text('Highest Rated', style: TextStyle(fontSize: 12.5))),
                        PopupMenuItem(value: 'discount', child: Text('Biggest Discount', style: TextStyle(fontSize: 12.5))),
                        PopupMenuItem(value: 'newest', child: Text('Newest First', style: TextStyle(fontSize: 12.5))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Product Grid (Browsing all products in category without limit)
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
                            'No Products Found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activeFilters > 0
                                ? 'No products match your current filters in this category.'
                                : 'Explore other categories or view all products.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _resetFilters();
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
