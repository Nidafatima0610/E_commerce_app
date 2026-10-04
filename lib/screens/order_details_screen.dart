import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/product_image.dart';
import 'product_details_screen.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'shipped':
      case 'out for delivery':
        return const Color(0xFF8B5CF6);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
  }

  void _confirmCancellation(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel order #${order.id}?'),
            const SizedBox(height: 10),
            const Text(
              'Since Cash on Delivery was selected, no money was charged. Your items will be safely restocked.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final success = ref.read(ordersProvider.notifier).cancelOrder(order.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order #${order.id} has been cancelled.'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _handleReorder(BuildContext context, Order order) {
    final result = ref.read(ordersProvider.notifier).reorderItems(order);

    if (result.readdedCount == 0 && result.skippedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, all items in this order are currently out of stock.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String message = '${result.readdedCount} item(s) added back to your cart.';
    if (result.skippedCount > 0) {
      message += ' (${result.skippedCount} out-of-stock item(s) were skipped)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Switch to Cart tab
    ref.read(bottomNavIndexProvider.notifier).setIndex(2);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showReturnDialog(BuildContext context, Order order) {
    String selectedReason = 'Damaged on delivery';
    final commentsCtrl = TextEditingController();
    final reasons = [
      'Damaged on delivery',
      'Defective / Not functioning',
      'Incorrect item or variant delivered',
      'Does not match product description',
      'Changed mind (7-Day replacement guarantee)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request Return / Exchange',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${order.id} • 7-Day Hassle-Free Guarantee',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Select Reason for Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Additional Notes / Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue or specify the variant you wish to swap with...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final item = order.items.first;
                      ref.read(returnRequestsProvider.notifier).submitRequest(
                        orderId: order.id,
                        itemId: item.id,
                        productName: item.product.name,
                        reason: selectedReason,
                        comments: commentsCtrl.text.trim().isNotEmpty ? commentsCtrl.text.trim() : null,
                      );
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (alertCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF10B981)),
                              SizedBox(width: 8),
                              Text('Request Submitted'),
                            ],
                          ),
                          content: const Text(
                            'Your return/exchange request has been logged. Our logistics team will contact you within 24 hours to arrange doorstep pickup across Pakistan.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(alertCtx), child: const Text('OK')),
                          ],
                        ),
                      );
                    },
                    child: const Text('Submit Return Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final orders = ref.watch(ordersProvider);
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Order not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Orders'),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(order.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. STATUS & TIMELINE CARD ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Estimated Delivery',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.estimatedDelivery,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Placed on ${_formatDate(order.date)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 24),

                  // ==================== VISUAL TIMELINE ====================
                  _buildTimeline(order.status, theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== 2. ITEMS IN ORDER ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items in Order (${order.items.length})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(product: item.product),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: ProductImage(
                                  imageUrl: item.product.image,
                                  category: item.product.category,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  if (item.variantDescription.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.variantDescription,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} × ${CurrencyFormat.format(item.unitPrice)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormat.format(item.subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== 3. DELIVERY ADDRESS ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery Address & Method',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (order.deliveryAddress != null) ...[
                    Text(
                      order.deliveryAddress!.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress!.phone,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress!.formattedAddress,
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ] else ...[
                    const Text('Standard Pakistani Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            order.deliveryMethod,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== 4. PAYMENT METHOD & STATUS ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment_outlined, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment Information',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Method', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          order.paymentMethod,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Status', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (order.isDelivered ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.paymentStatus,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: order.isDelivered ? const Color(0xFF047857) : const Color(0xFFB45309),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== 5. PRICE DETAILS ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Breakdown',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow('Items Subtotal', CurrencyFormat.format(order.subtotal), theme),
                  if (order.discount > 0)
                    _buildPriceRow(
                      'Promotional Discount',
                      '-${CurrencyFormat.format(order.discount)}',
                      theme,
                      color: const Color(0xFF10B981),
                    ),
                  _buildPriceRow(
                    'Delivery Fee',
                    order.deliveryFee == 0 ? 'FREE' : CurrencyFormat.format(order.deliveryFee),
                    theme,
                    color: order.deliveryFee == 0 ? const Color(0xFF10B981) : null,
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Payable',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormat.format(order.totalAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // ==================== BOTTOM ACTION BAR ====================
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (order.canCancel)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmCancellation(context, order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel Order'),
                  ),
                )
              else if (order.isDelivered)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReturnDialog(context, order),
                    icon: const Icon(Icons.assignment_return_outlined, size: 16),
                    label: const Text('Return / Exchange'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              if (order.canCancel || order.isDelivered) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleReorder(context, order),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Reorder Items'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus, ThemeData theme) {
    if (currentStatus.toLowerCase() == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Cancelled',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C), fontSize: 13.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'This order was cancelled before dispatch. You can reorder any available items whenever you wish.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final steps = ['Placed', 'Confirmed', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'];
    int currentStepIndex = 1;
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        currentStepIndex = 0;
        break;
      case 'confirmed':
        currentStepIndex = 1;
        break;
      case 'processing':
        currentStepIndex = 2;
        break;
      case 'shipped':
        currentStepIndex = 3;
        break;
      case 'out for delivery':
        currentStepIndex = 4;
        break;
      case 'delivered':
        currentStepIndex = 5;
        break;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isCompleted = index <= currentStepIndex;
            final isCurrent = index == currentStepIndex;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? theme.colorScheme.primary : Colors.grey.shade300,
                      border: isCurrent
                          ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 3)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < currentStepIndex ? theme.colorScheme.primary : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) {
            final isCurrent = steps.indexOf(s) == currentStepIndex;
            return Expanded(
              child: Text(
                s,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, ThemeData theme, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
