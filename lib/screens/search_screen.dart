import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _controller;

  final List<String> _popularSuggestions = [
    'Headphones',
    'iPhone',
    'Jordan',
    'Kurta',
    'Bose',
    'Watch',
    'Khaadi',
    'Airfryer',
    'Chanel',
    'Dumbbells',
    'Osprey',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);

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
                : _buildResults(results, query, theme),
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
                'Type a product name, brand, or specification, or select a trending keyword above.',
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

  Widget _buildResults(List<Product> results, String query, ThemeData theme) {
    if (results.isEmpty) {
      return Center(
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
                'We could not find any matches for "$query".\nTry checking spelling or search with different keywords like "Sony", "Jordan", "Watch", or "Khaadi".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _controller.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Clear Search'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${results.length} results found for "$query"',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
