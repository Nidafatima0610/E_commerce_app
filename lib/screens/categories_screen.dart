import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Container(
            width: 100,
            color: Colors.white,
            child: ListView.builder(
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final catName = isAll ? 'All' : categories[index - 1];
                final isSelected = isAll ? selectedCategory == null : selectedCategory == catName;

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).update(isAll ? null : catName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Text(
                      catName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.primary : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Content
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No products in this category'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: filteredProducts[index], width: double.infinity);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
