enum CouponDiscountType {
  percentage,
  fixedAmount,
  freeShipping,
}

class Coupon {
  final String code;
  final CouponDiscountType discountType;
  final double discountAmount;
  final double minOrderAmount;
  final double? maxDiscount;
  final DateTime? expiryDate;
  final bool isActive;
  final String description;

  const Coupon({
    required this.code,
    this.discountType = CouponDiscountType.percentage,
    required this.discountAmount,
    this.minOrderAmount = 0.0,
    this.maxDiscount,
    this.expiryDate,
    this.isActive = true,
    this.description = '',
    // Backward compatibility
    bool? isPercentage,
    double? discount,
  }) : _legacyIsPercentage = isPercentage,
       _legacyDiscount = discount;

  final bool? _legacyIsPercentage;
  final double? _legacyDiscount;

  // Backward compatibility getters
  bool get isPercentage => _legacyIsPercentage ?? (discountType == CouponDiscountType.percentage);
  double get discount => _legacyDiscount ?? discountAmount;

  /// Calculate coupon savings for a given order subtotal and delivery fee
  double calculateSavings(double subtotal, double deliveryFee) {
    if (!isActive) return 0.0;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return 0.0;
    if (subtotal < minOrderAmount) return 0.0;

    switch (discountType) {
      case CouponDiscountType.percentage:
        final raw = subtotal * (discountAmount / 100.0);
        if (maxDiscount != null && raw > maxDiscount!) {
          return maxDiscount!;
        }
        return raw;
      case CouponDiscountType.fixedAmount:
        return discountAmount.clamp(0.0, subtotal);
      case CouponDiscountType.freeShipping:
        return deliveryFee;
    }
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'discountType': discountType.name,
    'discountAmount': discountAmount,
    'minOrderAmount': minOrderAmount,
    'maxDiscount': maxDiscount,
    'expiryDate': expiryDate?.toIso8601String(),
    'isActive': isActive,
    'description': description,
    'isPercentage': isPercentage,
    'discount': discount,
  };

  factory Coupon.fromMap(Map<String, dynamic> map) {
    CouponDiscountType type = CouponDiscountType.percentage;
    if (map['discountType'] != null) {
      type = CouponDiscountType.values.firstWhere(
        (e) => e.name == map['discountType'],
        orElse: () => CouponDiscountType.percentage,
      );
    } else if (map['isPercentage'] == false) {
      type = CouponDiscountType.fixedAmount;
    }

    return Coupon(
      code: map['code'] ?? '',
      discountType: type,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? (map['discount'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate']) : null,
      isActive: map['isActive'] ?? true,
      description: map['description'] ?? '',
    );
  }
}

// Coupons tailored for Pakistani shoppers (Zero-cost local simulation ready for future server verification)
const List<Coupon> dummyCoupons = [
  Coupon(
    code: 'WELCOME10',
    discountType: CouponDiscountType.percentage,
    discountAmount: 10,
    minOrderAmount: 1000,
    maxDiscount: 1500,
    description: '10% off on your first order (up to Rs. 1,500)',
    isActive: true,
  ),
  Coupon(
    code: 'SAVE500',
    discountType: CouponDiscountType.fixedAmount,
    discountAmount: 500,
    minOrderAmount: 3000,
    description: 'Flat Rs. 500 off on orders above Rs. 3,000',
    isActive: true,
  ),
  Coupon(
    code: 'FREESHIP',
    discountType: CouponDiscountType.freeShipping,
    discountAmount: 0,
    minOrderAmount: 1500,
    description: 'Free courier delivery across Pakistan on orders above Rs. 1,500',
    isActive: true,
  ),
  Coupon(
    code: 'AZADI20',
    discountType: CouponDiscountType.percentage,
    discountAmount: 20,
    minOrderAmount: 4000,
    maxDiscount: 2500,
    description: 'Special Azadi 20% discount (up to Rs. 2,500) on orders above Rs. 4,000',
    isActive: true,
  ),
  Coupon(
    code: 'SAVE10',
    discountType: CouponDiscountType.percentage,
    discountAmount: 10,
    minOrderAmount: 1500,
    description: '10% off for returning shoppers',
    isActive: true,
  ),
  Coupon(
    code: 'PKR500',
    discountType: CouponDiscountType.fixedAmount,
    discountAmount: 500,
    minOrderAmount: 3000,
    description: 'Rs. 500 discount voucher',
    isActive: true,
  ),
];
