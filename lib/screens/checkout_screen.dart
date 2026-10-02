import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPayment = 'Credit Card';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final coupon = ref.read(appliedCouponProvider);
    final discount = ref.read(cartProvider.notifier).calculateDiscount(coupon);
    final shipping = subtotal > 0 ? 15.0 : 0.0;
    final total = subtotal - discount + shipping;
    
    final addresses = ref.watch(addressesProvider);
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shipping Address', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    // Navigate to Add Address
                  },
                  child: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (defaultAddress == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No addresses found. Please add one.'),
                ),
              )
            else
              Card(
                child: ListTile(
                  title: Text(defaultAddress.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${defaultAddress.street}\n${defaultAddress.city}, ${defaultAddress.state} ${defaultAddress.zipCode}\n${defaultAddress.country}'),
                  trailing: TextButton(onPressed: () {}, child: const Text('Change')),
                ),
              ),
            const SizedBox(height: 24),

            Text('Payment Method', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildPaymentOption('Credit Card', Icons.credit_card),
            _buildPaymentOption('PayPal', Icons.paypal),
            _buildPaymentOption('Apple Pay', Icons.apple),
            const SizedBox(height: 24),

            Text('Order Summary', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            if (discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount'),
                  Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping'),
                Text('\$${shipping.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text('\$${total.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (defaultAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add a delivery address')),
                    );
                    return;
                  }

                  final cartItems = ref.read(cartProvider);
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
                      title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                      content: const Text(
                        'Order Placed Successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      actions: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Continue Shopping'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return RadioListTile(
      value: title,
      groupValue: _selectedPayment,
      onChanged: (val) {
        if (val != null) setState(() => _selectedPayment = val);
      },
      title: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
