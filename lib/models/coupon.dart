class Coupon {
  final String code;
  final double discount;
  final bool isPercentage;
  final double minOrderAmount;

  const Coupon({
    required this.code,
    required this.discount,
    required this.isPercentage,
    this.minOrderAmount = 0.0,
  });
}

// Dummy coupons
const List<Coupon> dummyCoupons = [
  Coupon(code: 'SAVE10', discount: 10, isPercentage: true),
  Coupon(code: 'MINUS50', discount: 50, isPercentage: false, minOrderAmount: 200),
];
