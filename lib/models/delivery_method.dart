class DeliveryMethod {
  final String id;
  final String title;
  final String estimatedDays;
  final double fee;
  final String description;
  final bool isDefault;

  const DeliveryMethod({
    required this.id,
    required this.title,
    required this.estimatedDays,
    required this.fee,
    required this.description,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'estimatedDays': estimatedDays,
    'fee': fee,
    'description': description,
    'isDefault': isDefault,
  };

  factory DeliveryMethod.fromMap(Map<String, dynamic> map) {
    return DeliveryMethod(
      id: map['id'] ?? 'standard',
      title: map['title'] ?? 'Standard Delivery',
      estimatedDays: map['estimatedDays'] ?? '2–4 business days',
      fee: (map['fee'] as num?)?.toDouble() ?? 150.0,
      description: map['description'] ?? 'Reliable nationwide courier shipping',
      isDefault: (map['isDefault'] as bool?) ?? false,
    );
  }
}

// Configurable Delivery Methods for Pakistan
const List<DeliveryMethod> defaultDeliveryMethods = [
  DeliveryMethod(
    id: 'standard',
    title: 'Standard Delivery',
    estimatedDays: '2–4 days',
    fee: 150.0,
    description: 'Tracked ground delivery via TCS / Leopard Courier across Pakistan',
    isDefault: true,
  ),
  DeliveryMethod(
    id: 'express',
    title: 'Express Delivery',
    estimatedDays: '1–2 days',
    fee: 300.0,
    description: 'Priority overnight air express to major cities (Lahore, Karachi, Islamabad, Bahawalpur)',
    isDefault: false,
  ),
];
