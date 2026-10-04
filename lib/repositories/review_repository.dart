import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_review.dart';
import '../models/product_question.dart';

abstract class ReviewRepository {
  List<ProductReview> getReviewsForProduct(String productId);
  List<ProductReview> getAllReviews();
  void addReview(ProductReview review);

  List<ProductQuestion> getQuestionsForProduct(String productId);
  void addQuestion(ProductQuestion question);
}

class LocalReviewRepository implements ReviewRepository {
  final SharedPreferences _prefs;
  List<ProductReview> _reviewsCache = [];
  List<ProductQuestion> _questionsCache = [];

  LocalReviewRepository(this._prefs) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    // 1. Reviews
    final rawReviews = _prefs.getString('reviews_v1');
    if (rawReviews != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawReviews);
        _reviewsCache = decoded
            .map((item) => ProductReview.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _reviewsCache = List.from(initialPakistaniReviews);
      }
    } else {
      _reviewsCache = List.from(initialPakistaniReviews);
      _saveReviews();
    }

    // 2. Questions
    final rawQuestions = _prefs.getString('questions_v1');
    if (rawQuestions != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawQuestions);
        _questionsCache = decoded
            .map((item) => ProductQuestion.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _questionsCache = List.from(initialProductQuestions);
      }
    } else {
      _questionsCache = List.from(initialProductQuestions);
      _saveQuestions();
    }
  }

  void _saveReviews() {
    final encoded = jsonEncode(_reviewsCache.map((r) => r.toMap()).toList());
    _prefs.setString('reviews_v1', encoded);
  }

  void _saveQuestions() {
    final encoded = jsonEncode(_questionsCache.map((q) => q.toMap()).toList());
    _prefs.setString('questions_v1', encoded);
  }

  @override
  List<ProductReview> getReviewsForProduct(String productId) {
    return _reviewsCache.where((r) => r.productId == productId).toList();
  }

  @override
  List<ProductReview> getAllReviews() {
    return List.unmodifiable(_reviewsCache);
  }

  @override
  void addReview(ProductReview review) {
    _reviewsCache.insert(0, review);
    _saveReviews();
  }

  @override
  List<ProductQuestion> getQuestionsForProduct(String productId) {
    return _questionsCache.where((q) => q.productId == productId).toList();
  }

  @override
  void addQuestion(ProductQuestion question) {
    _questionsCache.insert(0, question);
    _saveQuestions();
  }
}
