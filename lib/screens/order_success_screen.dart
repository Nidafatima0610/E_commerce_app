import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../core/currency_format.dart';
import '../providers/app_providers.dart';
import 'order_details_screen.dart';

class OrderSuccessScreen extends ConsumerWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(bottomNavIndexProvider.notifier).setIndex(0);
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Animated checkmark container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 3),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Order Placed Successfully!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thank you for shopping with us! Your order has been registered and is being prepared for dispatch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Order ID Pill with Copy button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Order ID: ${order.id}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order ID copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(Icons.copy_rounded, size: 16, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Amount Payable', CurrencyFormat.format(order.totalAmount), isBold: true, highlight: true, theme: theme),
                      const Divider(height: 18),
                      _buildInfoRow('Payment Method', order.paymentMethod, theme: theme),
                      const SizedBox(height: 10),
                      _buildInfoRow('Delivery Estimate', order.estimatedDelivery, theme: theme),
                      const SizedBox(height: 10),
                      _buildInfoRow('Delivery Method', order.deliveryMethod, theme: theme),
                      const Divider(height: 18),
                      if (order.deliveryAddress != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shipping To',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.deliveryAddress!.name} (${order.deliveryAddress!.phone})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              order.deliveryAddress!.formattedAddress,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                // 1. Track Order
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(orderId: order.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline_rounded),
                    label: const Text('Track Order Status'),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. View Order Details
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(orderId: order.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View Order Receipt'),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Continue Shopping
                TextButton.icon(
                  onPressed: () {
                    ref.read(bottomNavIndexProvider.notifier).setIndex(0);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Continue Shopping'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, bool highlight = false, required ThemeData theme}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ],
    );
  }
}
