import '../core/currency_format.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String image;
  final String category;
  final String brand;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final int availableStock;
  final bool isFeatured;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.image,
    required this.category,
    this.brand = 'General',
    this.images = const [],
    required this.rating,
    required this.reviewCount,
    required this.availableStock,
    this.isFeatured = false,
  });

  List<String> get allImages => images.isNotEmpty ? images : [image];

  // Calculate discount percentage
  int get discountPercentage {
    if (oldPrice == null || oldPrice! <= price) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  // Formatted PKR price
  String get formattedPrice => CurrencyFormat.format(price);
  String? get formattedOldPrice => oldPrice != null ? CurrencyFormat.format(oldPrice!) : null;
}
