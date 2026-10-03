import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;
  final String? selectedStorage;
  final String? selectedVariant;
  final double unitPrice;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedColor,
    this.selectedSize,
    this.selectedStorage,
    this.selectedVariant,
    double? unitPrice,
  }) : unitPrice = unitPrice ?? product.price;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
    String? selectedStorage,
    String? selectedVariant,
    double? unitPrice,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedStorage: selectedStorage ?? this.selectedStorage,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  double get subtotal => unitPrice * quantity;

  String get variantDescription {
    final parts = <String>[];
    if (selectedColor != null && selectedColor!.trim().isNotEmpty) {
      parts.add('Color: $selectedColor');
    }
    if (selectedSize != null && selectedSize!.trim().isNotEmpty) {
      parts.add('Size: $selectedSize');
    }
    if (selectedStorage != null && selectedStorage!.trim().isNotEmpty) {
      parts.add('Storage: $selectedStorage');
    }
    if (selectedVariant != null && selectedVariant!.trim().isNotEmpty) {
      parts.add('Variant: $selectedVariant');
    }
    return parts.join(' • ');
  }

  bool matchesVariant({
    String? color,
    String? size,
    String? storage,
    String? variant,
  }) {
    return (selectedColor ?? '') == (color ?? '') &&
        (selectedSize ?? '') == (size ?? '') &&
        (selectedStorage ?? '') == (storage ?? '') &&
        (selectedVariant ?? '') == (variant ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'productId': product.id,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'selectedStorage': selectedStorage,
      'selectedVariant': selectedVariant,
      'unitPrice': unitPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      product: product,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
      selectedStorage: map['selectedStorage'] as String?,
      selectedVariant: map['selectedVariant'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? product.price,
    );
  }
}
