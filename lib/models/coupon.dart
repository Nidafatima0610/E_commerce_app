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

// Coupons tailored for Pakistani shoppers
const List<Coupon> dummyCoupons = [
  Coupon(code: 'SAVE10', discount: 10, isPercentage: true, minOrderAmount: 1500),
  Coupon(code: 'PKR500', discount: 500, isPercentage: false, minOrderAmount: 3000),
  Coupon(code: 'AZADI20', discount: 20, isPercentage: true, minOrderAmount: 5000),
];
