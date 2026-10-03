import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';
import '../core/currency_format.dart';

enum SearchSortOption {
  relevance,
  popular,
  priceLowToHigh,
  priceHighToLow,
  highestRated,
  newest,
  biggestDiscount,
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _controller;

  // Filter & Sort State
  SearchSortOption _sortOption = SearchSortOption.relevance;
  double _maxPrice = 500000.0;
  double _minPrice = 0.0;
  double _minRating = 0.0;
  int _minDiscount = 0;
  bool _onlyInStock = false;
  String? _selectedBrand;
  String? _selectedCategory;

  final List<String> _popularSuggestions = [
    'Headphones',
    'iPhone',
    'Wireless',
    'Jordan',
    'Kurta',
    'Speaker',
    'Smart Watch',
    'Lawn',
    'Anker',
    'Sneakers',
    'Backpack',
    'Fragrance',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    ref.read(searchQueryProvider.notifier).update(val);
  }

  void _onSearchSubmitted(String val) {
    if (val.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearch(val.trim());
    }
  }

  void _selectSuggestion(String term) {
    _controller.text = term;
    ref.read(searchQueryProvider.notifier).update(term);
    ref.read(searchHistoryProvider.notifier).addSearch(term);
  }

  void _resetFilters() {
    setState(() {
      _maxPrice = 500000.0;
      _minPrice = 0.0;
      _minRating = 0.0;
      _minDiscount = 0;
      _onlyInStock = false;
      _selectedBrand = null;
      _selectedCategory = null;
      _sortOption = SearchSortOption.relevance;
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_maxPrice < 500000.0 || _minPrice > 0.0) count++;
    if (_minRating > 0.0) count++;
    if (_minDiscount > 0) count++;
    if (_onlyInStock) count++;
    if (_selectedBrand != null) count++;
    if (_selectedCategory != null) count++;
    return count;
  }

  String _getSortLabel(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return 'Relevance';
      case SearchSortOption.popular:
        return 'Popular';
      case SearchSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SearchSortOption.priceHighToLow:
        return 'Price: High to Low';
      case SearchSortOption.highestRated:
        return 'Highest Rated';
      case SearchSortOption.newest:
        return 'Newest';
      case SearchSortOption.biggestDiscount:
        return 'Biggest Discount';
    }
  }

  List<Product> _applyFiltersAndSorting(List<Product> rawResults) {
    var filtered = rawResults.where((p) {
      if (p.price < _minPrice || p.price > _maxPrice) return false;
      if (_minRating > 0.0 && p.rating < _minRating) return false;
      if (_minDiscount > 0 && p.discountPercentage < _minDiscount) return false;
      if (_onlyInStock && p.availableStock <= 0) return false;
      if (_selectedBrand != null && p.brand.toLowerCase() != _selectedBrand!.toLowerCase()) return false;
      if (_selectedCategory != null && p.category.toLowerCase() != _selectedCategory!.toLowerCase()) return false;
      return true;
    }).toList();

    switch (_sortOption) {
      case SearchSortOption.relevance:
        // Already matching token scoring from repository
        break;
      case SearchSortOption.popular:
        filtered.sort((a, b) => (b.reviewCount * b.rating).compareTo(a.reviewCount * a.rating));
        break;
      case SearchSortOption.priceLowToHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSortOption.priceHighToLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SearchSortOption.highestRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SearchSortOption.newest:
        filtered.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
        break;
      case SearchSortOption.biggestDiscount:
        filtered.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
    }

    return filtered;
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sort Products By', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(),
              for (final opt in SearchSortOption.values)
                ListTile(
                  title: Text(
                    _getSortLabel(opt),
                    style: TextStyle(
                      fontWeight: _sortOption == opt ? FontWeight.bold : FontWeight.w500,
                      color: _sortOption == opt ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: _sortOption == opt
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                  onTap: () {
                    setState(() => _sortOption = opt);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, List<Product> baseResults) {
    // Extract available brands and categories from base results
    final brands = <String>{};
    final categories = <String>{};
    for (final p in baseResults) {
      if (p.brand.isNotEmpty && p.brand != 'General') brands.add(p.brand);
      if (p.category.isNotEmpty) categories.add(p.category);
    }
    final sortedBrands = brands.toList()..sort();
    final sortedCategories = categories.toList()..sort();

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
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
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
                    const Divider(height: 20),

                    // Price Range Slider
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
                      title: const Text('In-Stock Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      value: _onlyInStock,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() => _onlyInStock = val);
                        setState(() => _onlyInStock = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Minimum Rating Filter
                    const Text('Customer Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [0.0, 4.0, 4.5, 4.8].map((r) {
                        final isSelected = _minRating == r;
                        return ChoiceChip(
                          label: Text(r == 0.0 ? 'All' : '$r★ & above'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() => _minRating = selected ? r : 0.0);
                            setState(() => _minRating = selected ? r : 0.0);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Discount Filter
                    const Text('Discount Percentage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [0, 10, 20, 30].map((d) {
                        final isSelected = _minDiscount == d;
                        return ChoiceChip(
                          label: Text(d == 0 ? 'All' : '$d%+ Off'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() => _minDiscount = selected ? d : 0);
                            setState(() => _minDiscount = selected ? d : 0);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter
                    if (sortedCategories.isNotEmpty) ...[
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sortedCategories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() => _selectedCategory = selected ? cat : null);
                              setState(() => _selectedCategory = selected ? cat : null);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Brand Filter
                    if (sortedBrands.isNotEmpty) ...[
                      const Text('Brand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
    final query = ref.watch(searchQueryProvider);
    final rawResults = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);
    final results = _applyFiltersAndSorting(rawResults);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search headphones, shoes, watch, brand...',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
      ),
      body: Column(
        children: [
          // Popular Search suggestion chips
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _popularSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _popularSuggestions[index];
                final isSelected = query.toLowerCase() == suggestion.toLowerCase();

                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _selectSuggestion(suggestion),
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Main Content: History or Results
          Expanded(
            child: query.isEmpty
                ? _buildHistoryOrSuggestions(context, history, theme)
                : _buildResults(rawResults, results, query, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrSuggestions(
    BuildContext context,
    List<String> history,
    ThemeData theme,
  ) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Explore the Marketplace',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Search across 80+ products across Pakistan or tap any keyword above.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchHistoryProvider.notifier).clearHistory();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final term = history[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey, size: 20),
                title: Text(term, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () {
                    ref.read(searchHistoryProvider.notifier).removeSearch(term);
                  },
                ),
                onTap: () => _selectSuggestion(term),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    List<Product> rawResults,
    List<Product> results,
    String query,
    ThemeData theme,
  ) {
    final activeFilters = _activeFilterCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Query Header + Sort & Filter Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${results.length} ${results.length == 1 ? "result" : "results"} for "$query"',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort Button
                  OutlinedButton.icon(
                    onPressed: () => _showSortSheet(context),
                    icon: const Icon(Icons.sort_rounded, size: 16),
                    label: Text(
                      _getSortLabel(_sortOption),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter Button with Badge
                  ElevatedButton.icon(
                    onPressed: () => _showFilterSheet(context, rawResults),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      activeFilters > 0 ? 'Filter ($activeFilters)' : 'Filter',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Active Filter Chips Bar (if any active filter)
        if (activeFilters > 0)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_selectedBrand != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('Brand: $_selectedBrand'),
                      onDeleted: () => setState(() => _selectedBrand = null),
                    ),
                  ),
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('Category: $_selectedCategory'),
                      onDeleted: () => setState(() => _selectedCategory = null),
                    ),
                  ),
                if (_onlyInStock)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: const Text('In-Stock Only'),
                      onDeleted: () => setState(() => _onlyInStock = false),
                    ),
                  ),
                if (_minRating > 0.0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('$_minRating★+'),
                      onDeleted: () => setState(() => _minRating = 0.0),
                    ),
                  ),
                if (_minDiscount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('$_minDiscount%+ Off'),
                      onDeleted: () => setState(() => _minDiscount = 0),
                    ),
                  ),
                if (_maxPrice < 500000.0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('<= ${CurrencyFormat.format(_maxPrice)}'),
                      onDeleted: () => setState(() => _maxPrice = 500000.0),
                    ),
                  ),
                ActionChip(
                  label: const Text('Clear All'),
                  onPressed: _resetFilters,
                ),
              ],
            ),
          ),
        const Divider(height: 1),

        // Product Grid or Empty
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 70, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeFilters > 0
                              ? 'No products match your current filters. Try resetting filters.'
                              : 'We could not find any matches for "$query".\nTry checking spelling or search keywords like "Sony", "Jordan", "Watch", or "Khaadi".',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (activeFilters > 0) {
                              _resetFilters();
                            } else {
                              _controller.clear();
                              _onSearchChanged('');
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(activeFilters > 0 ? 'Reset Filters' : 'Clear Search'),
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
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: results[index]);
                  },
                ),
        ),
      ],
    );
  }
}
