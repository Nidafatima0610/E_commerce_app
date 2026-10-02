import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('\${order.items.length} items • \$\${order.totalAmount.toStringAsFixed(2)}'),
                    trailing: Chip(
                      label: Text(order.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    children: [
                      const Divider(),
                      if (order.deliveryAddress != null)
                        ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.grey),
                          title: Text(order.deliveryAddress!.street),
                          subtitle: Text('\${order.deliveryAddress!.city}, \${order.deliveryAddress!.state}'),
                        ),
                      ListTile(
                        leading: const Icon(Icons.payment, color: Colors.grey),
                        title: Text('Paid via \${order.paymentMethod}'),
                        subtitle: Text(order.date.toString().substring(0, 16)),
                      ),
                      const Divider(),
                      ...order.items.map((item) => ListTile(
                        leading: Image.network(item.product.image, width: 40, height: 40, fit: BoxFit.cover),
                        title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('\${item.quantity}x \$\${item.product.price}'),
                      )),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
