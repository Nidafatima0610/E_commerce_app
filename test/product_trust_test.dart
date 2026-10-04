import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerceapp/models/product.dart';
import 'package:e_commerceapp/models/product_review.dart';
import 'package:e_commerceapp/models/product_question.dart';
import 'package:e_commerceapp/models/cart_item.dart';
import 'package:e_commerceapp/repositories/review_repository.dart';
import 'package:e_commerceapp/core/recommendation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RatingBreakdown & Review Computation Tests', () {
    test('Calculates breakdown percentages accurately', () {
      final reviews = [
        ProductReview(
          id: '1',
          productId: 'prod_1',
          userId: 'u1',
          userName: 'User 1',
          rating: 5.0,
          comment: 'Outstanding quality!',
          createdAt: DateTime.now(),
          verifiedPurchase: true,
        ),
        ProductReview(
          id: '2',
          productId: 'prod_1',
          userId: 'u2',
          userName: 'User 2',
          rating: 5.0,
          comment: 'Very pleased with purchase',
          createdAt: DateTime.now(),
          verifiedPurchase: true,
        ),
        ProductReview(
          id: '3',
          productId: 'prod_1',
          userId: 'u3',
          userName: 'User 3',
          rating: 4.0,
          comment: 'Good overall',
          createdAt: DateTime.now(),
          verifiedPurchase: false,
        ),
        ProductReview(
          id: '4',
          productId: 'prod_1',
          userId: 'u4',
          userName: 'User 4',
          rating: 1.0,
          comment: 'Arrived defective',
          createdAt: DateTime.now(),
          verifiedPurchase: false,
        ),
      ];

      final breakdown = RatingBreakdown.fromReviews(reviews, 3.8);

      expect(breakdown.totalCount, equals(4));
      expect(breakdown.fiveStarCount, equals(2));
      expect(breakdown.fourStarCount, equals(1));
      expect(breakdown.threeStarCount, equals(0));
      expect(breakdown.twoStarCount, equals(0));
      expect(breakdown.oneStarCount, equals(1));

      // 5 star ratio is 2/4 = 0.5
      expect(breakdown.fiveStarRatio, equals(0.5));
      // 4 star ratio is 1/4 = 0.25
      expect(breakdown.fourStarRatio, equals(0.25));
      // 1 star ratio is 1/4 = 0.25
      expect(breakdown.oneStarRatio, equals(0.25));

      // Average: (5*2 + 4*1 + 1*1) / 4 = 15 / 4 = 3.75 -> rounded to 3.8
      expect(breakdown.averageRating, equals(3.8));
    });

    test('Handles empty reviews gracefully with fallback defaults', () {
      final breakdown = RatingBreakdown.fromReviews([], 4.5);
      expect(breakdown.totalCount, equals(0));
      expect(breakdown.averageRating, equals(4.5));
      expect(breakdown.fiveStarRatio, equals(0.0));
    });
  });

  group('LocalReviewRepository Tests', () {
    test('Persists added review and reloads accurately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalReviewRepository(prefs);

      final initialCount = repo.getAllReviews().length;

      final newReview = ProductReview(
        id: 'rev_custom_test',
        productId: 'prod_test_99',
        userId: 'user_test',
        userName: 'Umair Tariq',
        rating: 5.0,
        comment: 'Super fast delivery in Lahore and completely genuine sealed box.',
        createdAt: DateTime.now(),
        verifiedPurchase: true,
      );

      repo.addReview(newReview);

      expect(repo.getAllReviews().length, equals(initialCount + 1));
      final forProduct = repo.getReviewsForProduct('prod_test_99');
      expect(forProduct.length, equals(1));
      expect(forProduct.first.userName, equals('Umair Tariq'));
      expect(forProduct.first.verifiedPurchase, isTrue);
    });

    test('Persists added Q&A question', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalReviewRepository(prefs);

      final newQuestion = ProductQuestion(
        id: 'q_custom_test',
        productId: 'prod_test_99',
        question: 'Does this come with official Pakistani warranty card?',
        askedBy: 'Ahmed Raza',
        createdAt: DateTime.now(),
      );

      repo.addQuestion(newQuestion);

      final forProduct = repo.getQuestionsForProduct('prod_test_99');
      expect(forProduct.length, equals(1));
      expect(forProduct.first.question, contains('warranty card'));
      expect(forProduct.first.askedBy, equals('Ahmed Raza'));
    });
  });

  group('SmartRecommendationService Tests', () {
    final catalog = [
      Product(
        id: 'p1',
        name: 'Sony WH-1000XM5 Headphones',
        description: 'Noise cancelling headphones',
        price: 94999.0,
        category: 'Electronics',
        image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
        rating: 4.8,
        reviewCount: 320,
        brand: 'Sony',
        availableStock: 15,
      ),
      Product(
        id: 'p2',
        name: 'Apple AirPods Pro 2',
        description: 'Active noise cancellation earbuds',
        price: 68999.0,
        category: 'Electronics',
        image: 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434',
        rating: 4.9,
        reviewCount: 450,
        brand: 'Apple',
        availableStock: 20,
      ),
      Product(
        id: 'p3',
        name: 'Khaadi Embroidered Kurta',
        description: 'Pure cotton kurta',
        price: 7490.0,
        category: 'Fashion',
        image: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35',
        rating: 4.6,
        reviewCount: 110,
        brand: 'Khaadi',
        availableStock: 30,
      ),
      Product(
        id: 'p4',
        name: 'Anker PowerBank 20000mAh',
        description: 'Fast charging powerbank',
        price: 8999.0,
        category: 'Electronics',
        image: 'https://images.unsplash.com/photo-1609592424364-fef9b8b32cf7',
        rating: 4.7,
        reviewCount: 95,
        brand: 'Anker',
        availableStock: 25,
      ),
    ];

    test('Generates "Because You Viewed Electronics" when user viewed electronics', () {
      final sections = SmartRecommendationService.generateHomeRecommendations(
        catalog: catalog,
        recentlyViewed: [catalog[0]], // Viewed Sony headphones
        wishlist: [],
        orders: [],
      );

      expect(sections.isNotEmpty, isTrue);
      final becauseViewed = sections.firstWhere((s) => s.title.contains('Because You Viewed'));
      expect(becauseViewed.title, contains('Electronics'));
      // Should recommend AirPods and PowerBank (not Sony WH-1000XM5 since it was already viewed)
      expect(becauseViewed.products.any((p) => p.id == 'p2'), isTrue);
      expect(becauseViewed.products.any((p) => p.id == 'p1'), isFalse);
    });

    test('Generates Cart accessory recommendations based on categories in cart', () {
      final cartItems = [
        CartItem(
          id: 'item_1',
          product: catalog[0], // Sony headphones (Electronics)
          quantity: 1,
        ),
      ];

      final accessories = SmartRecommendationService.getCartRecommendations(
        catalog: catalog,
        cartItems: cartItems,
      );

      // Should recommend Electronics accessories from catalog not currently in cart
      expect(accessories.isNotEmpty, isTrue);
      expect(accessories.every((p) => p.category.toLowerCase() == 'electronics'), isTrue);
      expect(accessories.any((p) => p.id == catalog[0].id), isFalse);
    });
  });

  group('Free Delivery Dynamic Progress Calculation Tests', () {
    test('Calculates remaining amount and progress bar ratio accurately', () {
      const deliveryThreshold = 2999.0;
      double subtotal = 1999.0;

      double remaining = (deliveryThreshold - subtotal).clamp(0.0, deliveryThreshold);
      double progress = (subtotal / deliveryThreshold).clamp(0.0, 1.0);

      expect(remaining, equals(1000.0));
      expect(progress, closeTo(0.666, 0.01));

      // After adding Rs. 1500 item (subtotal = 3499.0)
      subtotal = 3499.0;
      remaining = (deliveryThreshold - subtotal).clamp(0.0, deliveryThreshold);
      progress = (subtotal / deliveryThreshold).clamp(0.0, 1.0);

      expect(remaining, equals(0.0));
      expect(progress, equals(1.0));
    });
  });
}
