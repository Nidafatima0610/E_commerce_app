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
    final candidates = _products.where((p) => !viewedSet.contains(p.id)).toList();

    final complementaryMap = {
      'Electronics': ['Mobiles', 'Watches'],
      'Mobiles': ['Electronics', 'Watches', 'Bags & Accessories'],
      'Fashion': ['Shoes', 'Watches', 'Bags & Accessories'],
      'Shoes': ['Sports & Fitness', 'Fashion'],
      'Watches': ['Fashion', 'Electronics', 'Bags & Accessories'],
      'Bags & Accessories': ['Travel Gear', 'Fashion', 'Mobiles'],
      'Beauty & Care': ['Fashion', 'Home & Living'],
      'Home & Living': ['Electronics', 'Beauty & Care'],
      'Sports & Fitness': ['Shoes', 'Watches', 'Electronics'],
    };

    if (preferredCategory != null && preferredCategory.isNotEmpty && preferredCategory != 'All') {
      final compList = complementaryMap[preferredCategory] ?? [];
      final scored = candidates.map((p) {
        double score = p.rating * 10;
        if (p.category.toLowerCase() == preferredCategory.toLowerCase()) {
          score += 50;
        } else if (compList.contains(p.category)) {
          score += 25;
        }
        if (p.isBestseller) score += 15;
        if (p.isDeal) score += 10;
        return MapEntry(p, score);
      }).toList();

      scored.sort((a, b) => b.value.compareTo(a.value));
      return scored.map((e) => e.key).take(limit).toList();
    }

    final list = List<Product>.from(candidates.isNotEmpty ? candidates : _products);
    list.sort((a, b) => ((b.rating * b.reviewCount) + (b.isBestseller ? 500 : 0)).compareTo((a.rating * a.reviewCount) + (a.isBestseller ? 500 : 0)));
    return list.take(limit).toList();
  }

  @override
  List<Product> getRelatedProducts(Product product, {int limit = 6}) {
    final candidates = _products.where((p) => p.id != product.id).toList();

    final scored = candidates.map((p) {
      int score = 0;
      if (p.subcategory.isNotEmpty && p.subcategory.toLowerCase() == product.subcategory.toLowerCase()) {
        score += 8;
      }
      if (p.category.toLowerCase() == product.category.toLowerCase()) {
        score += 5;
      }
      if (p.brand.isNotEmpty && p.brand != 'General' && p.brand.toLowerCase() == product.brand.toLowerCase()) {
        score += 4;
      }
      final sharedTags = p.tags.toSet().intersection(product.tags.toSet());
      score += sharedTags.length * 2;
      return MapEntry(p, score);
    }).where((e) => e.value > 0).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    final result = scored.map((e) => e.key).take(limit).toList();
    if (result.isNotEmpty) return result;

    return candidates.where((p) => p.category == product.category).take(limit).toList();
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
