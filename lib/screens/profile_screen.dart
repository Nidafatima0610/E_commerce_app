import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/product_image.dart';
import 'order_history_screen.dart';
import 'saved_addresses_screen.dart';
import 'notifications_screen.dart';
import 'product_details_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProfileProvider);
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    // Available clean avatars
    final avatarOptions = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&q=80',
    ];
    String selectedAvatar = user.avatarUrl.isNotEmpty ? user.avatarUrl : avatarOptions.first;

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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile Information',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Avatar selection row
                  const Text('Select Avatar Profile Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: avatarOptions.map((avatar) {
                      final isSelected = selectedAvatar == avatar;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedAvatar = avatar),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(avatar),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      if (!val.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Phone number is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        ref.read(userProfileProvider.notifier).updateProfile(
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              avatarUrl: selectedAvatar,
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile details updated successfully!'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Save Profile Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRecentlyViewedModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final viewed = ref.watch(recentlyViewedProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recently Viewed (${viewed.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (viewed.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          ref.read(recentlyViewedProvider.notifier).clear();
                        },
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: viewed.isEmpty
                      ? const Center(child: Text('No recently viewed products yet.'))
                      : ListView.separated(
                          itemCount: viewed.length,
                          separatorBuilder: (context, index) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final p = viewed[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: ProductImage(
                                    imageUrl: p.image,
                                    category: p.category,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(p.formattedPrice, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: p)),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: p)),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSavedForLaterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final saved = ref.watch(savedForLaterProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved for Later (${saved.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: saved.isEmpty
                      ? const Center(child: Text('No saved items. Use "Save for Later" in Cart.'))
                      : ListView.separated(
                          itemCount: saved.length,
                          separatorBuilder: (context, index) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = saved[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: ProductImage(
                                    imageUrl: item.product.image,
                                    category: item.product.category,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                CurrencyFormat.format(item.unitPrice),
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  ref.read(savedForLaterProvider.notifier).moveToCart(item);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Moved ${item.product.name} to Cart')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                child: const Text('To Cart', style: TextStyle(fontSize: 12)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: true,
                  onChanged: (val) {},
                  title: const Text('Order Tracking & Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Real-time delivery milestones via SMS / push notifications', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: true,
                  onChanged: (val) {},
                  title: const Text('Flash Deals & Discounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Early bird notifications for mega Pakistani sales & vouchers', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: false,
                  onChanged: (val) {},
                  title: const Text('WhatsApp Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Receive digital receipts directly on your WhatsApp number', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification preferences saved!'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: const Text('Save Preferences'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpCenterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Help Center & FAQs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: Color(0xFF10B981), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Support Helpline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('UAN: (021) 111-222-333 • 9 AM - 9 PM PKT', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Browse by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  // Orders
                  ExpansionTile(
                    leading: Icon(Icons.shopping_bag_outlined),
                    title: Text('Orders: How do I place & track an order?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Select any item, choose color/size, and tap "Add to Cart" or "Buy Now". During checkout, verify your address and select Cash on Delivery. Once placed, tap "Track Order" or visit Order History to view live milestones.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.cancel_outlined),
                    title: Text('Orders: How do I cancel an order?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'You can cancel orders that are in "Pending" or "Confirmed" status directly from Order Details. Once an order is Shipped or Out for Delivery, cancellation is locked.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  // Payments
                  ExpansionTile(
                    leading: Icon(Icons.payments_outlined),
                    title: Text('Payments: What payment methods are available?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'We offer nationwide Cash on Delivery (COD) across all cities and towns in Pakistan with zero advance deposit. Credit Card and Mobile Wallet gateways are marked Coming Soon.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  // Delivery
                  ExpansionTile(
                    leading: Icon(Icons.local_shipping_outlined),
                    title: Text('Delivery: What are your shipping timelines?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Standard courier shipping takes 2 to 4 business days. Express Delivery takes 1 to 2 business days to major hubs like Lahore, Karachi, Islamabad, and Bahawalpur.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  // Returns
                  ExpansionTile(
                    leading: Icon(Icons.assignment_return_outlined),
                    title: Text('Returns: What is your return & exchange policy?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'We offer a 7-day hassle-free doorstep replacement policy for damaged or incorrect items. Tap "Return / Exchange" on any Delivered order in Order Details to log a pickup request.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  // Products
                  ExpansionTile(
                    leading: Icon(Icons.verified_outlined),
                    title: Text('Products: Are all items authentic and guaranteed?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Yes, all electronic devices, watches, and fashion apparel in our catalog are 100% genuine and backed by official warranty.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  // Account
                  ExpansionTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Account: How can I change my delivery address?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Go to Profile → Saved Shipping Addresses. You can add new addresses, edit existing details, or set any address as your default for one-tap checkout.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contact Customer Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.phone_in_talk_outlined, color: Color(0xFF10B981)),
              title: const Text('Helpline (Toll Free)'),
              subtitle: const Text('0800-12345 (9 AM - 9 PM PKT)'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Helpline number: 0800-12345 (Mon–Sat 9AM–9PM)'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB)),
              title: const Text('WhatsApp Support'),
              subtitle: const Text('+92 300 1234567 • Instant response'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('WhatsApp support channel: +92 300 1234567'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Color(0xFF8B5CF6)),
              title: const Text('Email Inquiries'),
              subtitle: const Text('support@estore.pk'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support email: support@estore.pk'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReturnsInfoModal(BuildContext context, WidgetRef ref) {
    final returnRequests = ref.watch(returnRequestsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Returns & Refunds Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🛡️ 7-Day Hassle-Free Doorstep Replacement\nIf your item is damaged or incorrect, submit a request from Order Details. Our courier will pick it up from your address at zero extra charge.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'My Return Requests (${returnRequests.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: returnRequests.isEmpty
                  ? const Center(
                      child: Text(
                        'No return requests logged.\nTo request a return, open any Delivered order in My Orders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: returnRequests.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final r = returnRequests[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(r.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Reason: ${r.reason}\nOrder: ${r.orderId}', style: const TextStyle(fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.status,
                              style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('About E-Store PK'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'E-Store Pakistan v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                'Premier e-commerce mobile application built for Pakistani shoppers. Designed for high performance, smooth animations, and complete offline purchase persistence.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
              ),
              SizedBox(height: 14),
              Text(
                'Key Capabilities:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text('• Complete purchase journey (Cart → Checkout → Orders)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('• 100% Zero-Cost Local Architecture (No paid APIs)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('• Pakistani address & currency context (PKR / Bahawalpur)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('• Local promo codes, reordering & cancellation', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('• Future-ready Firestore / REST API schema', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Data Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Local Device Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              SizedBox(height: 4),
              Text(
                'All user profile details, saved addresses, and order histories are stored securely on your local device. No private user telemetry is sold or transmitted to external advertisers.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
              ),
              SizedBox(height: 10),
              Text('2. Payment Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              SizedBox(height: 4),
              Text(
                'Cash on Delivery transactions require zero digital banking credentials. Doorstep physical verification ensures total consumer security.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
              ),
              SizedBox(height: 10),
              Text('3. Data Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              SizedBox(height: 4),
              Text(
                'You retain full control to edit or clear your saved shipping addresses, cart items, and order logs at any time from this profile tab.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Orders & Deliveries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              SizedBox(height: 4),
              Text(
                'Delivery timelines are estimates based on standard TCS / Leopard couriers in Pakistan. Weather and operational factors may occasionally affect schedules.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
              ),
              SizedBox(height: 10),
              Text('2. Fair Promotional Use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              SizedBox(height: 4),
              Text(
                'Coupons such as WELCOME10, SAVE500, and FREESHIP are subject to minimum cart order amounts and single-use guidelines.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAppSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('App Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            const ListTile(
              leading: Icon(Icons.currency_exchange_rounded),
              title: Text('Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Pakistani Rupee (PKR / Rs.)', style: TextStyle(fontSize: 12)),
              trailing: Icon(Icons.check, color: Color(0xFF10B981)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.language_rounded),
              title: Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('English (Pakistan) • Urdu localization ready', style: TextStyle(fontSize: 12)),
              trailing: Icon(Icons.check, color: Color(0xFF10B981)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orders = ref.watch(ordersProvider);
    final wishlist = ref.watch(wishlistProvider);
    final addresses = ref.watch(addressesProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final user = ref.watch(userProfileProvider);
    final notifs = ref.watch(inAppNotificationsProvider);
    final unreadNotifs = notifs.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadNotifs > 0,
              label: Text(unreadNotifs.toString()),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notification Center',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Preferences',
            onPressed: () => _showAppSettingsModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // ==================== 1. PROFILE HEADER CARD ====================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
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
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                              child: user.avatarUrl.isEmpty
                                  ? Icon(Icons.person, color: theme.colorScheme.primary, size: 34)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showEditProfileModal(context, ref),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.phone,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _showEditProfileModal(context, ref),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatColumn('Orders', '${orders.length}', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          );
                        }),
                      ),
                      Container(height: 24, width: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      Expanded(
                        child: _buildStatColumn('Wishlist', '${wishlist.length}', () {
                          ref.read(bottomNavIndexProvider.notifier).setIndex(3);
                        }),
                      ),
                      Container(height: 24, width: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      Expanded(
                        child: _buildStatColumn('Addresses', '${addresses.length}', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==================== 2. SHOPPING SECTION ====================
            _buildSectionHeader('SHOPPING', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Orders History',
                  subtitle: '${orders.length} order(s) placed',
                  badge: orders.isNotEmpty ? '${orders.length}' : null,
                  theme: theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Wishlist',
                  subtitle: '${wishlist.length} item(s) saved',
                  badge: wishlist.isNotEmpty ? '${wishlist.length}' : null,
                  theme: theme,
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).setIndex(3);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.history_rounded,
                  title: 'Recently Viewed',
                  subtitle: 'View products you recently checked out',
                  theme: theme,
                  onTap: () => _showRecentlyViewedModal(context, ref),
                ),
                _buildSettingsTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved for Later',
                  subtitle: 'Items put aside from your shopping cart',
                  theme: theme,
                  onTap: () => _showSavedForLaterModal(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== 3. DELIVERY SECTION ====================
            _buildSectionHeader('DELIVERY', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: '${addresses.length} address(es) configured in Pakistan',
                  theme: theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== 4. SETTINGS SECTION ====================
            _buildSectionHeader('SETTINGS', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'Preferences',
                  subtitle: 'Pakistani Rupee (PKR), English language',
                  theme: theme,
                  onTap: () => _showAppSettingsModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Order tracking milestones & promotional alerts',
                  theme: theme,
                  onTap: () => _showNotificationSettingsModal(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dark Mode',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              isDarkMode ? 'Dark theme active' : 'Light theme active',
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== 5. SUPPORT SECTION ====================
            _buildSectionHeader('SUPPORT', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  subtitle: 'Orders, payments, delivery, & product guides',
                  theme: theme,
                  onTap: () => _showHelpCenterModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.contact_support_outlined,
                  title: 'Contact Support',
                  subtitle: 'Helpline, WhatsApp & email channels',
                  theme: theme,
                  onTap: () => _showContactModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.question_answer_outlined,
                  title: 'Frequently Asked Questions (FAQ)',
                  subtitle: 'Common questions answered with accordion steps',
                  theme: theme,
                  onTap: () => _showHelpCenterModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.assignment_return_outlined,
                  title: 'Returns & Exchanges Policy',
                  subtitle: '7-Day hassle-free return policy & logged requests',
                  theme: theme,
                  onTap: () => _showReturnsInfoModal(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== 6. ABOUT SECTION ====================
            _buildSectionHeader('ABOUT', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About App',
                  subtitle: 'App overview, version & architecture capabilities',
                  theme: theme,
                  onTap: () => _showAboutAppModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How user addresses and purchase logs are kept secure',
                  theme: theme,
                  onTap: () => _showPrivacyPolicyModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'Delivery timelines, COD terms & voucher rules',
                  theme: theme,
                  onTap: () => _showTermsModal(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Version info footer
            Text(
              'App Version 1.0.0+1 • Zero-Cost Local E-Commerce Experience',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
