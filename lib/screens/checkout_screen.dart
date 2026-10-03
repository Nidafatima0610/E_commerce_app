import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/custom_image.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPayment = 'Cash on Delivery';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'Cash on Delivery',
      'title': 'Cash on Delivery (COD)',
      'subtitle': 'Pay cash upon arrival • Most popular across Pakistan',
      'icon': Icons.payments_outlined,
      'isPopular': true,
    },
    {
      'id': 'JazzCash / EasyPaisa',
      'title': 'JazzCash / EasyPaisa',
      'subtitle': 'Mobile wallet transfer • Zero extra fee',
      'icon': Icons.account_balance_wallet_rounded,
      'isPopular': false,
    },
    {
      'id': 'Debit / Credit Card',
      'title': 'Debit / Credit Card',
      'subtitle': 'Visa, Mastercard, PayPak accepted',
      'icon': Icons.credit_card_rounded,
      'isPopular': false,
    },
    {
      'id': 'Bank Transfer (IBFT)',
      'title': 'Bank Transfer (IBFT / Raast)',
      'subtitle': 'Direct bank deposit confirmation',
      'icon': Icons.account_balance_rounded,
      'isPopular': false,
    },
  ];

  void _showAddAddressDialog(BuildContext context) {
    final user = ref.read(userProfileProvider);
    final nameCtrl = TextEditingController(text: user.name);
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Islamabad');
    final stateCtrl = TextEditingController(text: 'ICT');
    final zipCtrl = TextEditingController(text: '44000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              Text(
                'Add Shipping Address in Pakistan',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'House / Flat #, Street, Area / Sector',
                  hintText: 'e.g. House 24-B, Street 10, Sector F-8/1',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'City (e.g. Lahore, Karachi)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: stateCtrl,
                      decoration: const InputDecoration(labelText: 'Province / Territory'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: zipCtrl,
                decoration: const InputDecoration(labelText: 'Postal Code'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (streetCtrl.text.trim().isEmpty || cityCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all address fields')),
                      );
                      return;
                    }
                    final newAddr = Address(
                      id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text.trim(),
                      street: streetCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      zipCode: zipCtrl.text.trim(),
                      country: 'Pakistan',
                      isDefault: true,
                    );
                    ref.read(addressesProvider.notifier).addAddress(newAddr);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Delivery Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;
    final coupon = ref.watch(appliedCouponProvider);
    final discount = ref.watch(cartProvider.notifier).calculateDiscount(coupon);
    final shipping = subtotal >= 3000 || subtotal == 0 ? 0.0 : 250.0;
    final total = (subtotal - discount + shipping).clamp(0.0, double.infinity);

    final addresses = ref.watch(addressesProvider);
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. DELIVERY ADDRESS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery Address',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _showAddAddressDialog(context),
                  child: Text(defaultAddress == null ? 'Add Address' : 'Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: defaultAddress == null
                  ? const Text('No delivery address provided. Tap "Add Address" to enter your details.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              defaultAddress.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DELIVERY LOCATION',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          defaultAddress.street,
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${defaultAddress.city}, ${defaultAddress.state} ${defaultAddress.zipCode}, ${defaultAddress.country}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // ==================== 2. ORDER ITEMS ====================
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Order Items (${cartItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cartItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Container(
                    width: 240,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: CustomNetworkImage(imageUrl: item.product.image),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity}x • ${CurrencyFormat.format(item.product.price)}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormat.format(item.subtotal),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ==================== 3. PAYMENT METHOD ====================
            Row(
              children: [
                Icon(Icons.payment_outlined, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: _paymentMethods.map((method) {
                final isSelected = _selectedPayment == method['id'];
                final isPopular = method['isPopular'] as bool? ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPayment = method['id'] as String),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Icon(
                            method['icon'] as IconData,
                            color: isSelected ? theme.colorScheme.primary : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      method['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (isPopular) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'POPULAR',
                                          style: TextStyle(
                                            color: Color(0xFF047857),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  method['subtitle'] as String,
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ==================== 4. PRICE SUMMARY ====================
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
                    'Price Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryRow('Subtotal', CurrencyFormat.format(subtotal), theme),
                  if (discount > 0)
                    _buildSummaryRow(
                      'Coupon Discount',
                      '-${CurrencyFormat.format(discount)}',
                      theme,
                      color: const Color(0xFF10B981),
                    ),
                  _buildSummaryRow(
                    'Delivery Fee',
                    shipping == 0 ? 'FREE' : CurrencyFormat.format(shipping),
                    theme,
                    color: shipping == 0 ? const Color(0xFF10B981) : null,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payable',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormat.format(total),
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
            const SizedBox(height: 32),

            // ==================== 5. PLACE ORDER BUTTON ====================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (defaultAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add a delivery address to complete your order'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (cartItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your cart is empty'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final newOrderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  ref.read(ordersProvider.notifier).addOrder(
                    cartItems,
                    total,
                    address: defaultAddress,
                    paymentMethod: _selectedPayment,
                  );
                  ref.read(cartProvider.notifier).clearCart();
                  ref.read(appliedCouponProvider.notifier).update(null);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Order Placed Successfully!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Order ID: $newOrderId\nTotal: ${CurrencyFormat.format(total)}\nPayment: $_selectedPayment\nEst. Delivery: 2-4 business days via TCS Courier',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                                );
                              },
                              child: const Text('View Order Details'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              ref.read(bottomNavIndexProvider.notifier).setIndex(0);
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('Continue Shopping'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text('Place Order • ${CurrencyFormat.format(total)}'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
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
