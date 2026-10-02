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
    final total = subtotal + 15.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Address', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Umair', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('123 Main Street, Appartment 4B\nNew York, NY 10001\nUnited States'),
                trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
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
                const Text('Total'),
                Text('\$\$total', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final cartItems = ref.read(cartProvider);
                  ref.read(ordersProvider.notifier).addOrder(cartItems, total);
                  ref.read(cartProvider.notifier).clearCart();
                  
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
                              // Could navigate to My Orders instead
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
