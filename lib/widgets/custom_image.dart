import 'package:flutter/material.dart';
import 'product_image.dart';

/// Backward-compatible wrapper delegating to the unified [ProductImage] component.
class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final String category;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.shopping_bag_outlined,
    this.category = 'General',
  });

  @override
  Widget build(BuildContext context) {
    return ProductImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      fallbackIcon: fallbackIcon,
      category: category,
    );
  }
}
