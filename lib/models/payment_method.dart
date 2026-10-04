enum PaymentType {
  cashOnDelivery,
  card,
  mobileWallet,
  bankTransfer,
}

class PaymentMethodOption {
  final String id;
  final String title;
  final String subtitle;
  final PaymentType type;
  final bool isAvailable;
  final String iconName;
  final bool isPopular;
  final String? badgeText;

  const PaymentMethodOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.isAvailable,
    required this.iconName,
    this.isPopular = false,
    this.badgeText,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'type': type.name,
    'isAvailable': isAvailable,
    'iconName': iconName,
    'isPopular': isPopular,
    'badgeText': badgeText,
  };

  factory PaymentMethodOption.fromMap(Map<String, dynamic> map) {
    return PaymentMethodOption(
      id: map['id'] ?? 'cod',
      title: map['title'] ?? 'Cash on Delivery',
      subtitle: map['subtitle'] ?? 'Pay cash when your order arrives',
      type: PaymentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentType.cashOnDelivery,
      ),
      isAvailable: map['isAvailable'] ?? true,
      iconName: map['iconName'] ?? 'cash',
      isPopular: map['isPopular'] ?? false,
      badgeText: map['badgeText'],
    );
  }
}

// Configurable Payment Options (Zero-Cost Architecture: Cash on Delivery active)
const List<PaymentMethodOption> availablePaymentOptions = [
  PaymentMethodOption(
    id: 'Cash on Delivery',
    title: 'Cash on Delivery (COD)',
    subtitle: 'Pay cash upon doorstep delivery • Zero transaction fee',
    type: PaymentType.cashOnDelivery,
    isAvailable: true,
    iconName: 'cash',
    isPopular: true,
    badgeText: 'RECOMMENDED',
  ),
  PaymentMethodOption(
    id: 'Debit / Credit Card',
    title: 'Credit / Debit Card',
    subtitle: 'Visa, Mastercard & PayPak (Future Gateway Integration)',
    type: PaymentType.card,
    isAvailable: false,
    iconName: 'card',
    isPopular: false,
    badgeText: 'COMING SOON',
  ),
  PaymentMethodOption(
    id: 'JazzCash / EasyPaisa',
    title: 'JazzCash / EasyPaisa Wallet',
    subtitle: 'Direct mobile wallet transfer (Future API Integration)',
    type: PaymentType.mobileWallet,
    isAvailable: false,
    iconName: 'wallet',
    isPopular: false,
    badgeText: 'COMING SOON',
  ),
  PaymentMethodOption(
    id: 'Direct Bank Transfer',
    title: 'Raast / Bank Transfer (IBFT)',
    subtitle: 'Instant State Bank of Pakistan Raast ID transfer',
    type: PaymentType.bankTransfer,
    isAvailable: false,
    iconName: 'bank',
    isPopular: false,
    badgeText: 'COMING SOON',
  ),
];
