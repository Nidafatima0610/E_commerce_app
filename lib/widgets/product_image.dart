import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String category;
  final IconData? fallbackIcon;
  final bool enableZoomOnTap;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.category = 'General',
    this.fallbackIcon,
    this.enableZoomOnTap = false,
  });

  IconData _getCategoryFallbackIcon(String cat) {
    if (fallbackIcon != null) return fallbackIcon!;
    switch (cat.toLowerCase()) {
      case 'electronics':
        return Icons.headphones_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'shoes':
        return Icons.snowshoeing_outlined;
      case 'watches':
        return Icons.watch_outlined;
      case 'bags':
      case 'bags & accessories':
        return Icons.backpack_outlined;
      case 'home & living':
        return Icons.kitchen_outlined;
      case 'beauty':
      case 'beauty & care':
        return Icons.spa_outlined;
      case 'sports':
      case 'sports & fitness':
        return Icons.fitness_center_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = _getCategoryFallbackIcon(category);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: (height != null && height! < 70) ? 22 : 36,
            color: primary.withValues(alpha: 0.4),
          ),
          Positioned(
            bottom: 6,
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomDialog(BuildContext context) {
    if (imageUrl.trim().isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildFallback(context),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      return _buildFallback(context);
    }

    Widget content = Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback(context);
      },
    );

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    if (enableZoomOnTap) {
      return GestureDetector(
        onTap: () => _showZoomDialog(context),
        child: content,
      );
    }

    return content;
  }
}
