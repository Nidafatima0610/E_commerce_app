import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../providers/app_providers.dart';
import 'order_details_screen.dart';
import 'deals_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
        return Icons.local_shipping_outlined;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
        return const Color(0xFF2563EB);
      case NotificationType.orderShipped:
        return const Color(0xFF8B5CF6);
      case NotificationType.orderDelivered:
        return const Color(0xFF10B981);
      case NotificationType.promotion:
        return const Color(0xFFF59E0B);
      case NotificationType.system:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _handleNotificationTap(NotificationItem notif) {
    ref.read(inAppNotificationsProvider.notifier).markAsRead(notif.id);

    // 1. Order notifications -> Order Details
    if (notif.orderId != null && notif.orderId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(orderId: notif.orderId!),
        ),
      );
      return;
    }

    // 2. Offer/Promotion notifications -> Deals Screen
    if (notif.type == NotificationType.promotion) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DealsScreen(),
        ),
      );
      return;
    }

    // 3. System / General notification -> View details dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIcon(notif.type), color: _getColor(notif.type), size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(notif.title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.message, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 12),
            Text(
              'Received ${_formatTime(notif.timestamp)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(inAppNotificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredList = notifications.where((n) {
      switch (_selectedFilter) {
        case 'Orders':
          return n.type == NotificationType.orderPlaced ||
              n.type == NotificationType.orderConfirmed ||
              n.type == NotificationType.orderShipped ||
              n.type == NotificationType.orderDelivered;
        case 'Offers':
          return n.type == NotificationType.promotion;
        case 'System':
          return n.type == NotificationType.system;
        case 'All':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications (${notifications.where((n) => !n.isRead).length} new)'),
        actions: [
          if (notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () {
                ref.read(inAppNotificationsProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(milliseconds: 1200),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Mark read'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear notifications',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Notifications'),
                    content: const Text('Are you sure you want to remove all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(inAppNotificationsProvider.notifier).clearAll();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Notifications',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'re all caught up! Order status updates and special voucher announcements will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Filter Choice Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: ['All', 'Orders', 'Offers', 'System'].map((f) {
                      final isSelected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedFilter = f);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Notifications List or Empty Filter
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_alt_off_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No $_selectedFilter notifications',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => setState(() => _selectedFilter = 'All'),
                                  child: const Text('Show All Notifications'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = filteredList[index];
                            final color = _getColor(notif.type);
                            final icon = _getIcon(notif.type);

                            return Container(
                              decoration: BoxDecoration(
                                color: notif.isRead
                                    ? theme.colorScheme.surface
                                    : theme.colorScheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: notif.isRead
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _handleNotificationTap(notif),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(icon, color: color, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: TextStyle(
                                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTime(notif.timestamp),
                                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif.message,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!notif.isRead) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
