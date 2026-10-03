import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../providers/app_providers.dart';
import 'order_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProfileProvider);
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);

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
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number (e.g. +92 300 1234567)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(userProfileProvider.notifier).updateProfile(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressesModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final addresses = ref.watch(addressesProvider);

          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Shipping Addresses (${addresses.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: addresses.isEmpty
                      ? const Center(child: Text('No saved addresses.'))
                      : ListView.separated(
                          itemCount: addresses.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final addr = addresses[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: addr.isDefault
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: addr.isDefault ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: addr.isDefault
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            if (addr.isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'DEFAULT',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(addr.street, style: const TextStyle(fontSize: 13)),
                                        Text('${addr.city}, ${addr.state} ${addr.zipCode}, ${addr.country}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (!addr.isDefault) ...[
                                          const SizedBox(height: 6),
                                          InkWell(
                                            onTap: () {
                                              ref.read(addressesProvider.notifier).setDefaultAddress(addr.id);
                                            },
                                            child: Text(
                                              'Set as default',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (addresses.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () {
                                        ref.read(addressesProvider.notifier).removeAddress(addr.id);
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddAddressBottomSheet(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Address'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddAddressBottomSheet(BuildContext context, WidgetRef ref) {
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
                'Add Shipping Address',
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
                decoration: const InputDecoration(labelText: 'Street Address & Sector'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State/Province'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: zipCtrl, decoration: const InputDecoration(labelText: 'Postal Code')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (streetCtrl.text.trim().isEmpty) return;
                    final newAddr = Address(
                      id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text.trim(),
                      street: streetCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      zipCode: zipCtrl.text.trim(),
                      country: 'Pakistan',
                      isDefault: false,
                    );
                    ref.read(addressesProvider.notifier).addAddress(newAddr);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Address'),
                ),
              ),
            ],
          ),
        ),
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
                  subtitle: const Text('Real-time delivery milestones via SMS / push', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: true,
                  onChanged: (val) {},
                  title: const Text('Flash Deals & Discounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Early bird access to mega sales & coupons', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: false,
                  onChanged: (val) {},
                  title: const Text('WhatsApp Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Receive order receipts directly on WhatsApp', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification preferences saved!')),
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
        height: MediaQuery.of(ctx).size.height * 0.7,
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
            const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ExpansionTile(
                    title: Text('Do you offer Cash on Delivery (COD)?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Yes! We offer nationwide Cash on Delivery across all cities and towns in Pakistan with zero advance deposit.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('What are your delivery timelines?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Standard courier shipping takes 2 to 4 business days. Major cities like Lahore, Karachi, and Islamabad often receive orders within 48 hours.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('What is your return & exchange policy?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'We offer a 7-day hassle-free return and exchange guarantee. If an item is damaged or does not fit, contact our support for an immediate swap.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Are all products original and covered by warranty?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Yes, all electronic devices, watches, and beauty items in our catalog are 100% genuine and backed by official manufacturer warranties.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
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

  void _showPrivacyPolicyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Security Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Data Privacy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              SizedBox(height: 4),
              Text(
                'We respect your privacy. Personal information including delivery addresses and contact numbers are encrypted and never shared with third parties.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              SizedBox(height: 12),
              Text(
                '2. Secure Transactions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              SizedBox(height: 4),
              Text(
                'All digital transactions are processed through 256-bit SSL encrypted channels. Cash on Delivery is verified upon doorstep handover.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              SizedBox(height: 12),
              Text(
                '3. Account Control',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              SizedBox(height: 4),
              Text(
                'You can update your personal information or request data deletion anytime by contacting our support team.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ],
          ),
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
            ListTile(
              leading: const Icon(Icons.currency_exchange_rounded),
              title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Pakistani Rupee (PKR / Rs.)', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.check, color: Color(0xFF10B981)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('English (US) • Urdu Coming Soon', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.check, color: Color(0xFF10B981)),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Settings',
            onPressed: () => _showAppSettingsModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // ==================== 1. PROFILE HEADER CARD ====================
            Container(
              padding: const EdgeInsets.all(20),
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
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              foregroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80'),
                              onForegroundImageError: (_, _) {},
                              child: Icon(Icons.person, color: theme.colorScheme.primary, size: 36),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Avatar is synced with your portfolio account'),
                                    duration: Duration(milliseconds: 1500),
                                  ),
                                );
                              },
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  user.name,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: Color(0xFFB45309),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

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
                          _showAddressesModal(context, ref);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==================== 2. GROUPED SETTINGS ====================
            _buildSectionHeader('Account Details', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile Details',
                  subtitle: 'Update username, email & phone',
                  theme: theme,
                  onTap: () => _showEditProfileModal(context, ref),
                ),
                _buildSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Shipping Addresses',
                  subtitle: '${addresses.length} saved location(s)',
                  theme: theme,
                  onTap: () => _showAddressesModal(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Orders & Purchases', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Order History',
                  subtitle: '${orders.length} active or delivered order(s)',
                  theme: theme,
                  badge: orders.isNotEmpty ? '${orders.length}' : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.favorite_outline,
                  title: 'My Wishlist',
                  subtitle: '${wishlist.length} saved product(s)',
                  theme: theme,
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).setIndex(3);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Appearance & Settings', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
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
                              isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
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
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Order updates & promotional alerts',
                  theme: theme,
                  onTap: () => _showNotificationSettingsModal(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Support & Legal', theme),
            _buildSettingsCard(
              theme,
              isDark,
              [
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center & FAQ',
                  subtitle: 'Helpline, WhatsApp & return policies',
                  theme: theme,
                  onTap: () => _showHelpCenterModal(context),
                ),
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Learn how your data is protected',
                  theme: theme,
                  onTap: () => _showPrivacyPolicyModal(context),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out from this device?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out successfully')),
                            );
                          },
                          child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'App Version 1.0.0 • Pakistani E-Commerce Experience',
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
            letterSpacing: 0.3,
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
