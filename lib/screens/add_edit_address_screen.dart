import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../providers/app_providers.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? existingAddress;

  const AddEditAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _houseController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _landmarkController;

  String _selectedProvince = 'Punjab';
  bool _isDefault = false;

  final List<String> _pakistaniProvinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Azad Kashmir',
    'Gilgit-Baltistan',
  ];

  final List<String> _popularCities = [
    'Bahawalpur',
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala',
  ];

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    final user = ref.read(userProfileProvider);

    _nameController = TextEditingController(text: addr?.name ?? user.name);
    _phoneController = TextEditingController(text: addr?.phone ?? user.phone);
    _houseController = TextEditingController(text: addr?.houseFlat ?? '');
    _streetController = TextEditingController(text: addr?.streetArea ?? (addr != null ? addr.street : ''));
    _cityController = TextEditingController(text: addr?.city ?? 'Bahawalpur');
    _postalCodeController = TextEditingController(text: addr?.postalCode ?? (addr?.zipCode ?? '63100'));
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _selectedProvince = addr?.province ?? (addr?.state ?? 'Punjab');
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.existingAddress?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}';
    final newAddress = Address(
      id: id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      houseFlat: _houseController.text.trim(),
      streetArea: _streetController.text.trim(),
      city: _cityController.text.trim(),
      province: _selectedProvince,
      postalCode: _postalCodeController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      country: 'Pakistan',
      isDefault: _isDefault,
    );

    if (widget.existingAddress != null) {
      ref.read(addressesProvider.notifier).updateAddress(newAddress);
    } else {
      ref.read(addressesProvider.notifier).addAddress(newAddress);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingAddress != null
              ? 'Address updated successfully!'
              : 'New shipping address added!',
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, newAddress);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Delivery Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Deliveries across Pakistan via TCS & Leopard Couriers. Please provide accurate house and street details.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Full Name
              _buildFieldLabel('Full Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Muhammad Umair',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Full Name is required';
                  if (val.trim().length < 2) return 'Please enter a valid full name';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              _buildFieldLabel('Phone Number', isRequired: true),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g. +92 301 7894561 or 0300 1234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                  final clean = val.replaceAll(RegExp(r'[\s\-\+]'), '');
                  if (clean.length < 10) return 'Please enter a valid 11-digit mobile number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // House / Flat / Building
              _buildFieldLabel('House / Flat / Building', isRequired: true),
              TextFormField(
                controller: _houseController,
                decoration: const InputDecoration(
                  hintText: 'e.g. House # 42-A, Floor 2, Victoria Heights',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'House/Building details are required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Street / Area / Sector
              _buildFieldLabel('Street / Area / Sector', isRequired: true),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Street 4, Model Town A / Sector F-7',
                  prefixIcon: Icon(Icons.signpost_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Street and area details are required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City
              _buildFieldLabel('City', isRequired: true),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'e.g. Bahawalpur, Lahore, Karachi',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    tooltip: 'Select popular city',
                    onSelected: (city) {
                      _cityController.text = city;
                    },
                    itemBuilder: (ctx) => _popularCities
                        .map((c) => PopupMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'City is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Province & Postal Code Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Province', isRequired: true),
                        DropdownButtonFormField<String>(
                          initialValue: _pakistaniProvinces.contains(_selectedProvince)
                              ? _selectedProvince
                              : _pakistaniProvinces.first,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.map_outlined),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          ),
                          items: _pakistaniProvinces
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedProvince = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Postal Code', isRequired: false),
                        TextFormField(
                          controller: _postalCodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '63100',
                            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Optional Landmark
              _buildFieldLabel('Optional Landmark (Nearby famous place)', isRequired: false),
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Near Victoria Hospital / Opposite Bank Alfalah',
                  prefixIcon: Icon(Icons.near_me_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Set as default address switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SwitchListTile(
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as Default Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Use this address as primary for faster checkout', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveAddress,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(isEditing ? 'Update Address' : 'Save Delivery Address'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (isRequired) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
