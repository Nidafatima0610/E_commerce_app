import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';
import '../core/currency_format.dart';
import 'search_screen.dart';

enum ProductSortOption {
  featured,
  popular,
  priceLowToHigh,
  priceHighToLow,
  rating,
  newest,
  discount,
}

class ProductListScreen extends ConsumerStatefulWidget {
  final String title;
  final String? initialCategory;
  final bool onlyDeals;
  final bool onlyFeatured;
  final bool onlyBestsellers;
  final bool onlyNewArrivals;
  final bool onlyDealsOfTheDay;

  const ProductListScreen({
    super.key,
    required this.title,
    this.initialCategory,
    this.onlyDeals = false,
    this.onlyFeatured = false,
    this.onlyBestsellers = false,
    this.onlyNewArrivals = false,
    this.onlyDealsOfTheDay = false,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late String _selectedCategory;
  String? _selectedSubcategory;
  String? _selectedBrand;
  bool _onlyInStock = false;
  double _maxPriceFilter = 450000.0;
  ProductSortOption _sortOption = ProductSortOption.featured;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = widget.initialCategory ?? 'All';
      _selectedSubcategory = null;
      _selectedBrand = null;
      _onlyInStock = false;
      _maxPriceFilter = 450000.0;
      _sortOption = ProductSortOption.featured;
    });
  }

  void _showFilterModal(BuildContext context, List<Product> availableProducts) {
    final brands = <String>{};
    for (final p in availableProducts) {
      if (p.brand.isNotEmpty && p.brand != 'General') brands.add(p.brand);
    }
    final sortedBrands = brands.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Products',
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
                    const Divider(height: 16),

                    // Price Range Slider
                    Text(
                      'Max Price: ${CurrencyFormat.format(_maxPriceFilter)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Slider(
                      value: _maxPriceFilter,
                      min: 1000.0,
                      max: 450000.0,
                      divisions: 45,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() {
                          _maxPriceFilter = val;
                        });
                        setState(() {
                          _maxPriceFilter = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // In Stock Only Switch
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
                    const SizedBox(height: 12),

                    // Brands
                    if (sortedBrands.isNotEmpty) ...[
                      const Text(
                        'Filter by Brand',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sortedBrands.map((brand) {
                          final isSelected = _selectedBrand == brand;
                          return ChoiceChip(
                            label: Text(brand),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedBrand = selected ? brand : null;
                              });
                              setState(() {
                                _selectedBrand = selected ? brand : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
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

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    var list = allProducts;

    if (widget.onlyDeals) {
      list = list.where((p) => p.isDeal || p.discountPercentage > 0).toList();
    } else if (widget.onlyFeatured) {
      list = list.where((p) => p.isFeatured).toList();
    } else if (widget.onlyBestsellers) {
      list = list.where((p) => p.isBestseller || p.reviewCount >= 1000).toList();
    } else if (widget.onlyNewArrivals) {
      list = list.where((p) => p.isNewArrival).toList();
    } else if (widget.onlyDealsOfTheDay) {
      list = list.where((p) => p.discountPercentage >= 20).toList();
    }

    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    if (_selectedSubcategory != null && _selectedSubcategory != 'All') {
      list = list.where((p) => p.subcategory.toLowerCase() == _selectedSubcategory!.toLowerCase()).toList();
    }

    if (_selectedBrand != null) {
      list = list.where((p) => p.brand.toLowerCase() == _selectedBrand!.toLowerCase()).toList();
    }

    if (_onlyInStock) {
      list = list.where((p) => p.availableStock > 0).toList();
    }

    list = list.where((p) => p.price <= _maxPriceFilter).toList();

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
      case ProductSortOption.popular:
        sorted.sort((a, b) => (b.reviewCount * b.rating).compareTo(a.reviewCount * a.rating));
        break;
      case ProductSortOption.newest:
        sorted.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
        break;
      case ProductSortOption.discount:
        sorted.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
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

    // Subcategories for selected category
    List<String> subcategories = [];
    if (_selectedCategory != 'All') {
      final subcatSet = <String>{};
      for (final p in allProducts) {
        if (p.category.toLowerCase() == _selectedCategory.toLowerCase() && p.subcategory.isNotEmpty) {
          subcatSet.add(p.subcategory);
        }
      }
      subcategories = ['All', ...subcatSet];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
            onPressed: () => _showFilterModal(context, allProducts),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
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
            margin: const EdgeInsets.symmetric(vertical: 6),
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
                        _selectedSubcategory = null;
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

          // Subcategory selector chips (if category selected)
          if (subcategories.length > 1)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: subcategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final subcat = subcategories[index];
                  final isSelected = (_selectedSubcategory == null && subcat == 'All') ||
                      (_selectedSubcategory == subcat);

                  return FilterChip(
                    label: Text(subcat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubcategory = subcat == 'All' ? null : subcat;
                      });
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

          // Filter bar & Count & Sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${products.length} Products found',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<ProductSortOption>(
                    value: _sortOption,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: const [
                      DropdownMenuItem(
                        value: ProductSortOption.featured,
                        child: Text('Featured', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.popular,
                        child: Text('Most Popular', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.priceLowToHigh,
                        child: Text('Price: Low to High', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.priceHighToLow,
                        child: Text('Price: High to Low', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.rating,
                        child: Text('Highest Rated', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.newest,
                        child: Text('Newest First', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: ProductSortOption.discount,
                        child: Text('Biggest Discount', style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _sortOption = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Product Grid / Empty State
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Products Found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try changing your filters, price range, or category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Filters'),
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
