import 'cart_item.dart';
import 'address.dart';
import 'product.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double totalAmount;
  final DateTime date;
  final String status;
  final Address? deliveryAddress;
  final String deliveryMethod;
  final String paymentMethod;
  final String paymentStatus;
  final String estimatedDelivery;
  final String? notes;
  final String? customerId;

  const Order({
    required this.id,
    required this.items,
    double? subtotal,
    this.discount = 0.0,
    this.deliveryFee = 150.0,
    required this.totalAmount,
    required this.date,
    this.status = 'Confirmed',
    this.deliveryAddress,
    this.deliveryMethod = 'Standard Delivery (2–4 days)',
    this.paymentMethod = 'Cash on Delivery',
    this.paymentStatus = 'Pending (Cash on Delivery)',
    this.estimatedDelivery = '2–4 business days',
    this.notes,
    this.customerId = 'usr_101',
  }) : subtotal = subtotal ?? (totalAmount - deliveryFee + discount);

  // Convenience aliases for prompt consistency
  String get orderId => id;
  DateTime get createdAt => date;
  double get total => totalAmount;
  Address? get address => deliveryAddress;

  // Status checks
  bool get canCancel => status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed';
  bool get isActive => status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled';
  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    double? discount,
    double? deliveryFee,
    double? totalAmount,
    DateTime? date,
    String? status,
    Address? deliveryAddress,
    String? deliveryMethod,
    String? paymentMethod,
    String? paymentStatus,
    String? estimatedDelivery,
    String? notes,
    String? customerId,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      notes: notes ?? this.notes,
      customerId: customerId ?? this.customerId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': id,
    'subtotal': subtotal,
    'discount': discount,
    'deliveryFee': deliveryFee,
    'totalAmount': totalAmount,
    'total': totalAmount,
    'date': date.toIso8601String(),
    'createdAt': date.toIso8601String(),
    'status': status,
    'deliveryAddress': deliveryAddress?.toMap(),
    'address': deliveryAddress?.toMap(),
    'deliveryMethod': deliveryMethod,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'estimatedDelivery': estimatedDelivery,
    'notes': notes,
    'customerId': customerId,
    'items': items.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toJson() => toMap();

  factory Order.fromMap(Map<String, dynamic> map, List<Product> catalog) {
    final rawItems = map['items'] as List? ?? [];
    final List<CartItem> parsedItems = [];

    for (final raw in rawItems) {
      if (raw is Map<String, dynamic>) {
        final prodId = raw['productId']?.toString() ?? '';
        final matchingProduct = catalog.where((p) => p.id == prodId).firstOrNull ??
            (catalog.isNotEmpty ? catalog.first : null);
        if (matchingProduct != null) {
          parsedItems.add(CartItem.fromMap(raw, matchingProduct));
        }
      }
    }

    final total = (map['totalAmount'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 0.0;
    final fee = (map['deliveryFee'] as num?)?.toDouble() ?? 150.0;
    final disc = (map['discount'] as num?)?.toDouble() ?? 0.0;
    final sub = (map['subtotal'] as num?)?.toDouble() ?? (total - fee + disc);

    Address? addr;
    if (map['deliveryAddress'] != null) {
      addr = Address.fromMap(Map<String, dynamic>.from(map['deliveryAddress']));
    } else if (map['address'] != null) {
      addr = Address.fromMap(Map<String, dynamic>.from(map['address']));
    }

    return Order(
      id: map['id']?.toString() ?? map['orderId']?.toString() ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: parsedItems,
      subtotal: sub,
      discount: disc,
      deliveryFee: fee,
      totalAmount: total,
      date: DateTime.tryParse(map['date']?.toString() ?? map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      status: map['status']?.toString() ?? 'Confirmed',
      deliveryAddress: addr,
      deliveryMethod: map['deliveryMethod']?.toString() ?? 'Standard Delivery (2–4 days)',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash on Delivery',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Pending (Cash on Delivery)',
      estimatedDelivery: map['estimatedDelivery']?.toString() ?? '2–4 business days',
      notes: map['notes']?.toString(),
      customerId: map['customerId']?.toString() ?? 'usr_101',
    );
  }
}
