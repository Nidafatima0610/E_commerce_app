import '../models/product.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class RecommendationSection {
  final String title;
  final String subtitle;
  final List<Product> products;
  final String? category;

  const RecommendationSection({
    required this.title,
    required this.subtitle,
    required this.products,
    this.category,
  });
}

class SmartRecommendationService {
  /// Generate dynamic personalized sections for the home screen based on user behavior
  static List<RecommendationSection> generateHomeRecommendations({
    required List<Product> catalog,
    required List<Product> recentlyViewed,
    required List<Product> wishlist,
    required List<Order> orders,
  }) {
    final sections = <RecommendationSection>[];

    // 1. "Because You Viewed [Category]"
    if (recentlyViewed.isNotEmpty) {
      // Find the most frequently viewed category
      final categoryCounts = <String, int>{};
      for (final p in recentlyViewed) {
        categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
      }
      final topCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final viewedIds = recentlyViewed.map((p) => p.id).toSet();
      final categoryProducts = catalog
          .where((p) => p.category.toLowerCase() == topCategory.toLowerCase() && !viewedIds.contains(p.id))
          .toList();

      if (categoryProducts.isNotEmpty) {
        sections.add(
          RecommendationSection(
            title: 'Because You Viewed $topCategory',
            subtitle: 'Recommended matches based on your recent interest',
            products: categoryProducts.take(8).toList(),
            category: topCategory,
          ),
        );
      }
    }

    // 2. "Recommended For You" (Affinity based on Wishlist + Orders)
    final affinityCategories = <String>{};
    for (final p in wishlist) {
      affinityCategories.add(p.category.toLowerCase());
    }
    for (final o in orders) {
      for (final item in o.items) {
        affinityCategories.add(item.product.category.toLowerCase());
      }
    }

    if (affinityCategories.isNotEmpty) {
      final recommended = catalog.where((p) {
        final matchesCategory = affinityCategories.contains(p.category.toLowerCase());
        final inWishlist = wishlist.any((w) => w.id == p.id);
        return matchesCategory && !inWishlist;
      }).toList();

      if (recommended.isNotEmpty) {
        // Sort by rating & discount
        recommended.sort((a, b) => (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount));
        sections.add(
          RecommendationSection(
            title: 'Recommended For You',
            subtitle: 'Personalized based on your saved favorites and purchases',
            products: recommended.take(8).toList(),
          ),
        );
      }
    }

    return sections;
  }

  /// Get accessory recommendations for Cart based on categories currently in cart
  static List<Product> getCartRecommendations({
    required List<Product> catalog,
    required List<CartItem> cartItems,
    int limit = 6,
  }) {
    if (cartItems.isEmpty) return [];

    final cartProductIds = cartItems.map((c) => c.product.id).toSet();
    final cartCategories = cartItems.map((c) => c.product.category.toLowerCase()).toSet();

    // Recommends products in related/complementary categories or lower-priced add-ons in same category
    final candidates = catalog.where((p) {
      if (cartProductIds.contains(p.id)) return false;
      return cartCategories.contains(p.category.toLowerCase()) || p.price < 5000;
    }).toList();

    // Sort to prioritize accessories or highly rated affordable items
    candidates.sort((a, b) {
      final aIsAccessory = a.price < 6000 ? 1 : 0;
      final bIsAccessory = b.price < 6000 ? 1 : 0;
      if (aIsAccessory != bIsAccessory) return bIsAccessory.compareTo(aIsAccessory);
      return b.rating.compareTo(a.rating);
    });

    return candidates.take(limit).toList();
  }

  /// Get compatible products for comparison within same category
  static List<Product> getComparableProducts({
    required List<Product> catalog,
    required Product referenceProduct,
  }) {
    return catalog
        .where((p) =>
            p.id != referenceProduct.id &&
            p.category.toLowerCase() == referenceProduct.category.toLowerCase())
        .toList();
  }
}
