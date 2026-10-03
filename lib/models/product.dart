import '../core/currency_format.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String image;
  final String category;
  final String subcategory;
  final String brand;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final int availableStock;
  final bool isFeatured;
  final bool isBestseller;
  final bool isNewArrival;
  final bool isDeal;
  final List<String> colors;
  final List<String> sizes;
  final List<String> tags;
  final Map<String, String> specifications;
  final String deliveryInfo;
  final String sellerName;
  final double sellerRating;
  final String? sellerId;
  final String? categoryId;
  final String? subcategoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.image,
    required this.category,
    this.subcategory = '',
    this.brand = 'General',
    this.images = const [],
    required this.rating,
    required this.reviewCount,
    required this.availableStock,
    this.isFeatured = false,
    this.isBestseller = false,
    this.isNewArrival = false,
    this.isDeal = false,
    this.colors = const [],
    this.sizes = const [],
    this.tags = const [],
    this.specifications = const {},
    this.deliveryInfo = 'Estimated delivery: 2–4 business days across Pakistan',
    this.sellerName = 'Verified Official Merchant',
    this.sellerRating = 4.8,
    this.sellerId,
    this.categoryId,
    this.subcategoryId,
    this.createdAt,
    this.updatedAt,
  });

  int get stockQuantity => availableStock;

  List<String> get allImages => images.isNotEmpty ? images : [image];

  // Calculate discount percentage
  int get discountPercentage {
    if (oldPrice == null || oldPrice! <= price) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  // Stock status text
  String get stockStatus {
    if (availableStock <= 0) return 'Out of Stock';
    if (availableStock <= 15) return 'Low Stock ($availableStock left)';
    return 'In Stock ($availableStock)';
  }

  bool get isLowStock => availableStock > 0 && availableStock <= 15;
  bool get isOutOfStock => availableStock <= 0;

  // Formatted PKR price
  String get formattedPrice => CurrencyFormat.format(price);
  String? get formattedOldPrice => oldPrice != null ? CurrencyFormat.format(oldPrice!) : null;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? oldPrice,
    String? image,
    String? category,
    String? subcategory,
    String? brand,
    List<String>? images,
    double? rating,
    int? reviewCount,
    int? availableStock,
    bool? isFeatured,
    bool? isBestseller,
    bool? isNewArrival,
    bool? isDeal,
    List<String>? colors,
    List<String>? sizes,
    List<String>? tags,
    Map<String, String>? specifications,
    String? deliveryInfo,
    String? sellerName,
    double? sellerRating,
    String? sellerId,
    String? categoryId,
    String? subcategoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      image: image ?? this.image,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      brand: brand ?? this.brand,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      availableStock: availableStock ?? this.availableStock,
      isFeatured: isFeatured ?? this.isFeatured,
      isBestseller: isBestseller ?? this.isBestseller,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isDeal: isDeal ?? this.isDeal,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      tags: tags ?? this.tags,
      specifications: specifications ?? this.specifications,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      sellerName: sellerName ?? this.sellerName,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerId: sellerId ?? this.sellerId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'image': image,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'availableStock': availableStock,
      'isFeatured': isFeatured,
      'isBestseller': isBestseller,
      'isNewArrival': isNewArrival,
      'isDeal': isDeal,
      'colors': colors,
      'sizes': sizes,
      'tags': tags,
      'specifications': specifications,
      'deliveryInfo': deliveryInfo,
      'sellerName': sellerName,
      'sellerRating': sellerRating,
      'sellerId': sellerId,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (map['oldPrice'] as num?)?.toDouble(),
      image: map['image'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      brand: map['brand'] ?? 'General',
      images: List<String>.from(map['images'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      availableStock: (map['availableStock'] as num?)?.toInt() ?? 10,
      isFeatured: map['isFeatured'] ?? false,
      isBestseller: map['isBestseller'] ?? false,
      isNewArrival: map['isNewArrival'] ?? false,
      isDeal: map['isDeal'] ?? false,
      colors: List<String>.from(map['colors'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      specifications: Map<String, String>.from(map['specifications'] ?? {}),
      deliveryInfo: map['deliveryInfo'] ?? 'Estimated delivery: 2–4 business days across Pakistan',
      sellerName: map['sellerName'] ?? 'Verified Official Merchant',
      sellerRating: (map['sellerRating'] as num?)?.toDouble() ?? 4.8,
      sellerId: map['sellerId'],
      categoryId: map['categoryId'],
      subcategoryId: map['subcategoryId'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }
}
