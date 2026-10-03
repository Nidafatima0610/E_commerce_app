import '../models/product.dart';
import '../models/dummy_data.dart';

abstract class ProductRepository {
  List<Product> getAllProducts();
  Product? getProductById(String id);
  List<Product> getFeaturedProducts();
  List<Product> getDeals();
  List<Product> getBestSellers();
  List<Product> getNewArrivals();
  List<Product> getDealsOfTheDay();
  List<Product> getRecommendedProducts({String? preferredCategory, List<String>? viewedIds, int limit = 10});
  List<Product> getRelatedProducts(Product product, {int limit = 6});
  List<Product> searchProducts(String query);
  List<Product> getByCategory(String category);
  List<Product> getBySubcategory(String category, String subcategory);
  List<String> getAllCategories();
  List<String> getSubcategoriesForCategory(String category);
}

class LocalProductRepository implements ProductRepository {
  final List<Product> _products;

  LocalProductRepository({List<Product>? products}) : _products = products ?? dummyProducts;

  @override
  List<Product> getAllProducts() {
    return List.unmodifiable(_products);
  }

  @override
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Product> getFeaturedProducts() {
    return _products.where((p) => p.isFeatured).toList();
  }

  @override
  List<Product> getDeals() {
    return _products.where((p) => p.isDeal || p.discountPercentage > 0).toList();
  }

  @override
  List<Product> getBestSellers() {
    return _products.where((p) => p.isBestseller || p.reviewCount >= 1000).toList();
  }

  @override
  List<Product> getNewArrivals() {
    return _products.where((p) => p.isNewArrival).toList();
  }

  @override
  List<Product> getDealsOfTheDay() {
    // Products with highest discounts (>= 20% off)
    return _products.where((p) => p.discountPercentage >= 20).toList();
  }

  @override
  List<Product> getRecommendedProducts({String? preferredCategory, List<String>? viewedIds, int limit = 10}) {
    final viewedSet = viewedIds?.toSet() ?? <String>{};

    if (preferredCategory != null && preferredCategory.isNotEmpty) {
      final preferred = _products
          .where((p) => p.category.toLowerCase() == preferredCategory.toLowerCase() && !viewedSet.contains(p.id))
          .toList();
      if (preferred.length >= limit) {
        return preferred.sublist(0, limit);
      }
      final remaining = _products
          .where((p) => p.category.toLowerCase() != preferredCategory.toLowerCase() && !viewedSet.contains(p.id))
          .toList();
      final combined = [...preferred, ...remaining];
      return combined.take(limit).toList();
    }

    // Default recommendation: blend of top rated and featured items
    final list = List<Product>.from(_products);
    list.sort((a, b) => (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount));
    return list.take(limit).toList();
  }

  @override
  List<Product> getRelatedProducts(Product product, {int limit = 6}) {
    return _products
        .where((p) => p.id != product.id && (p.category == product.category || p.brand == product.brand))
        .take(limit)
        .toList();
  }

  @override
  List<Product> searchProducts(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final tokens = trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return _products.where((p) {
      final name = p.name.toLowerCase();
      final brand = p.brand.toLowerCase();
      final category = p.category.toLowerCase();
      final subcategory = p.subcategory.toLowerCase();
      final description = p.description.toLowerCase();
      final tags = p.tags.map((t) => t.toLowerCase()).join(' ');

      // Check if all tokens match anywhere in searchable fields
      return tokens.every((token) =>
          name.contains(token) ||
          brand.contains(token) ||
          category.contains(token) ||
          subcategory.contains(token) ||
          description.contains(token) ||
          tags.contains(token));
    }).toList();
  }

  @override
  List<Product> getByCategory(String category) {
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return getAllProducts();
    }
    return _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  List<Product> getBySubcategory(String category, String subcategory) {
    return _products.where((p) =>
        p.category.toLowerCase() == category.toLowerCase() &&
        p.subcategory.toLowerCase() == subcategory.toLowerCase()).toList();
  }

  @override
  List<String> getAllCategories() {
    final Set<String> categories = {};
    for (final p in _products) {
      if (p.category.isNotEmpty) {
        categories.add(p.category);
      }
    }
    return categories.toList();
  }

  @override
  List<String> getSubcategoriesForCategory(String category) {
    final Set<String> subcategories = {};
    for (final p in _products) {
      if (p.category.toLowerCase() == category.toLowerCase() && p.subcategory.isNotEmpty) {
        subcategories.add(p.subcategory);
      }
    }
    return subcategories.toList();
  }
}
