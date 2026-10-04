import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../providers/app_providers.dart';
import 'add_edit_address_screen.dart';

class SavedAddressesScreen extends ConsumerWidget {
  final bool isSelectionMode;
  final String? selectedAddressId;

  const SavedAddressesScreen({
    super.key,
    this.isSelectionMode = false,
    this.selectedAddressId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Select Delivery Address' : 'Saved Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Address',
            onPressed: () async {
              final newAddr = await Navigator.push<Address>(
                context,
                MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
              );
              if (isSelectionMode && newAddr != null && context.mounted) {
                Navigator.pop(context, newAddr);
              }
            },
          ),
        ],
      ),
      body: addresses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Saved Addresses',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your delivery address in Pakistan to ensure smooth order deliveries right to your doorstep.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newAddr = await Navigator.push<Address>(
                          context,
                          MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
                        );
                        if (isSelectionMode && newAddr != null && context.mounted) {
                          Navigator.pop(context, newAddr);
                        }
                      },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add Delivery Address'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final addr = addresses[index];
                final isSelected = isSelectionMode && (selectedAddressId != null ? addr.id == selectedAddressId : addr.isDefault);

                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (addr.isDefault
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      width: isSelected || addr.isDefault ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: isSelectionMode
                        ? () => Navigator.pop(context, addr)
                        : () => _editAddress(context, addr),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            addr.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (addr.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'DEFAULT',
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
                                      addr.phone,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelectionMode)
                                Container(
                                  width: 22,
                                  height: 22,
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
                          const Divider(height: 20),
                          Text(
                            addr.formattedAddress,
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!addr.isDefault)
                                TextButton.icon(
                                  onPressed: () {
                                    ref.read(addressesProvider.notifier).setDefaultAddress(addr.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Default delivery address updated'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('Set as Default', style: TextStyle(fontSize: 12)),
                                )
                              else
                                const SizedBox.shrink(),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit Address',
                                    onPressed: () => _editAddress(context, addr),
                                  ),
                                  if (addresses.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      tooltip: 'Delete Address',
                                      onPressed: () => _confirmDelete(context, ref, addr),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () async {
              final newAddr = await Navigator.push<Address>(
                context,
                MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
              );
              if (isSelectionMode && newAddr != null && context.mounted) {
                Navigator.pop(context, newAddr);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Delivery Address'),
          ),
        ),
      ),
    );
  }

  void _editAddress(BuildContext context, Address addr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(existingAddress: addr),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Address addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to remove the address for "${addr.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(addressesProvider.notifier).removeAddress(addr.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
