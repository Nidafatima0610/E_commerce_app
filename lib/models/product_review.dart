class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userCity;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool verifiedPurchase;
  final int helpfulCount;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userCity = 'Pakistan',
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.verifiedPurchase = false,
    this.helpfulCount = 0,
  });

  ProductReview copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userCity,
    double? rating,
    String? comment,
    DateTime? createdAt,
    bool? verifiedPurchase,
    int? helpfulCount,
  }) {
    return ProductReview(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userCity: userCity ?? this.userCity,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      verifiedPurchase: verifiedPurchase ?? this.verifiedPurchase,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'userCity': userCity,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'verifiedPurchase': verifiedPurchase,
    'helpfulCount': helpfulCount,
  };

  factory ProductReview.fromMap(Map<String, dynamic> map) {
    return ProductReview(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? 'usr_guest',
      userName: map['userName'] ?? 'Customer',
      userCity: map['userCity'] ?? 'Pakistan',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      verifiedPurchase: map['verifiedPurchase'] ?? false,
      helpfulCount: (map['helpfulCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class RatingBreakdown {
  final double averageRating;
  final int totalCount;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const RatingBreakdown({
    required this.averageRating,
    required this.totalCount,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  double get fiveStarRatio => totalCount > 0 ? fiveStarCount / totalCount : 0.0;
  double get fourStarRatio => totalCount > 0 ? fourStarCount / totalCount : 0.0;
  double get threeStarRatio => totalCount > 0 ? threeStarCount / totalCount : 0.0;
  double get twoStarRatio => totalCount > 0 ? twoStarCount / totalCount : 0.0;
  double get oneStarRatio => totalCount > 0 ? oneStarCount / totalCount : 0.0;

  factory RatingBreakdown.fromReviews(List<ProductReview> reviews, double fallbackRating) {
    if (reviews.isEmpty) {
      return RatingBreakdown(
        averageRating: fallbackRating,
        totalCount: 0,
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
      );
    }

    int c5 = 0, c4 = 0, c3 = 0, c2 = 0, c1 = 0;
    double sum = 0;

    for (final r in reviews) {
      sum += r.rating;
      final rounded = r.rating.round();
      if (rounded >= 5) {
        c5++;
      } else if (rounded == 4) {
        c4++;
      } else if (rounded == 3) {
        c3++;
      } else if (rounded == 2) {
        c2++;
      } else {
        c1++;
      }
    }

    return RatingBreakdown(
      averageRating: double.parse((sum / reviews.length).toStringAsFixed(1)),
      totalCount: reviews.length,
      fiveStarCount: c5,
      fourStarCount: c4,
      threeStarCount: c3,
      twoStarCount: c2,
      oneStarCount: c1,
    );
  }
}

// Initial authentic reviews in realistic Pakistani context
final List<ProductReview> initialPakistaniReviews = [
  // Product 1 reviews (Sony WH-1000XM5)
  ProductReview(
    id: 'rev_001',
    productId: 'p1',
    userId: 'usr_bilal',
    userName: 'Bilal Farooq',
    userCity: 'Lahore',
    rating: 5.0,
    comment: '100% original product with official warranty card! Active noise cancellation is unbelievable during Lahore traffic. Delivered in 2 days via TCS with bubble wrap.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    verifiedPurchase: true,
    helpfulCount: 24,
  ),
  ProductReview(
    id: 'rev_002',
    productId: 'p1',
    userId: 'usr_saba',
    userName: 'Saba Tariq',
    userCity: 'Islamabad',
    rating: 5.0,
    comment: 'Exceptional build quality and battery life. Microphone works crystal clear for remote Zoom meetings. Cash on delivery was seamless.',
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    verifiedPurchase: true,
    helpfulCount: 15,
  ),
  ProductReview(
    id: 'rev_003',
    productId: 'p1',
    userId: 'usr_ahmed',
    userName: 'Ahmed Raza',
    userCity: 'Karachi',
    rating: 4.0,
    comment: 'Great soundstage and very comfortable on the ears. Earcups get slightly warm during Karachi summer, but audio clarity is unmatched.',
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    verifiedPurchase: true,
    helpfulCount: 9,
  ),

  // Product 2 reviews (Apple MacBook Air M3)
  ProductReview(
    id: 'rev_004',
    productId: 'p2',
    userId: 'usr_hamza',
    userName: 'Hamza Malik',
    userCity: 'Bahawalpur',
    rating: 5.0,
    comment: 'Sealed pack Apple product. Battery easily lasts 16 hours on a single charge. Verified serial number on Apple website, completely genuine!',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    verifiedPurchase: true,
    helpfulCount: 31,
  ),
  ProductReview(
    id: 'rev_005',
    productId: 'p2',
    userId: 'usr_zainab',
    userName: 'Zainab Noor',
    userCity: 'Rawalpindi',
    rating: 5.0,
    comment: 'Super lightweight and blazing fast for video editing. Customer support responded within 10 minutes regarding delivery queries.',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    verifiedPurchase: true,
    helpfulCount: 18,
  ),

  // Product 3 reviews (Samsung Galaxy S24 Ultra)
  ProductReview(
    id: 'rev_006',
    productId: 'p3',
    userId: 'usr_usman',
    userName: 'Usman Ghani',
    userCity: 'Faisalabad',
    rating: 5.0,
    comment: 'Official PTA approved with valid tax receipt. The 100x zoom camera and anti-reflective titanium display are stunning.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    verifiedPurchase: true,
    helpfulCount: 42,
  ),
  ProductReview(
    id: 'rev_007',
    productId: 'p3',
    userId: 'usr_aisha',
    userName: 'Aisha Siddiqui',
    userCity: 'Multan',
    rating: 4.0,
    comment: 'Phone performance is top tier. A bit heavy in small hands, but battery easily lasts full 1.5 days.',
    createdAt: DateTime.now().subtract(const Duration(days: 16)),
    verifiedPurchase: true,
    helpfulCount: 11,
  ),

  // Product 4 reviews (Men\'s Formal Embroidered Kurta)
  ProductReview(
    id: 'rev_008',
    productId: 'p4',
    userId: 'usr_daniyal',
    userName: 'Daniyal Khan',
    userCity: 'Peshawar',
    rating: 5.0,
    comment: 'Stitching and embroidery on collar is top notch. Fabric is pure wash & wear, fits accurately according to Pakistani size chart.',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
    verifiedPurchase: true,
    helpfulCount: 19,
  ),

  // Product 5 reviews (Women\'s Luxury Embroidered 3-Piece)
  ProductReview(
    id: 'rev_009',
    productId: 'p5',
    userId: 'usr_mariam',
    userName: 'Mariam Waqas',
    userCity: 'Lahore',
    rating: 5.0,
    comment: 'Chiffon dupatta with zari embroidery is exquisite. Color matches the product photos exactly. Highly recommended for weddings and Eid!',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    verifiedPurchase: true,
    helpfulCount: 27,
  ),
  ProductReview(
    id: 'rev_010',
    productId: 'p5',
    userId: 'usr_hira',
    userName: 'Hira Shah',
    userCity: 'Gujranwala',
    rating: 4.0,
    comment: 'High quality lawn fabric. Arrived neatly packed in luxury branded box.',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    verifiedPurchase: true,
    helpfulCount: 8,
  ),
];
