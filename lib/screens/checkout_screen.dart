import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/delivery_method.dart';
import '../models/payment_method.dart';
import '../models/coupon.dart';
import '../providers/app_providers.dart';
import '../core/currency_format.dart';
import '../widgets/product_image.dart';
import 'add_edit_address_screen.dart';
import 'saved_addresses_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem>? directCheckoutItems;

  const CheckoutScreen({super.key, this.directCheckoutItems});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _couponError;
  bool _isPlacingOrder = false;

  Address? _selectedAddress;
  late DeliveryMethod _selectedDeliveryMethod;
  late PaymentMethodOption _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _selectedDeliveryMethod = ref.read(selectedDeliveryMethodProvider);
    _selectedPaymentMethod = ref.read(selectedPaymentMethodProvider);
  }

  @override
  void dispose() {
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyCoupon(double subtotal, double deliveryFee) {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final foundCoupon = dummyCoupons.where((c) => c.code == code).firstOrNull;
    if (foundCoupon != null) {
      if (subtotal < foundCoupon.minOrderAmount) {
        setState(() {
          _couponError = 'Min. order value of ${CurrencyFormat.format(foundCoupon.minOrderAmount)} required';
        });
      } else {
        ref.read(appliedCouponProvider.notifier).update(foundCoupon);
        setState(() {
          _couponError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon "$code" applied! Saved ${CurrencyFormat.format(foundCoupon.calculateSavings(subtotal, deliveryFee))}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      setState(() {
        _couponError = 'Invalid code. Try "WELCOME10", "SAVE500", or "FREESHIP"';
      });
    }
  }

  Future<void> _chooseAddress(List<Address> addresses) async {
    final chosen = await Navigator.push<Address>(
      context,
      MaterialPageRoute(
        builder: (context) => SavedAddressesScreen(
          isSelectionMode: true,
          selectedAddressId: _selectedAddress?.id ?? addresses.where((a) => a.isDefault).firstOrNull?.id,
        ),
      ),
    );

    if (chosen != null) {
      setState(() {
        _selectedAddress = chosen;
      });
    }
  }

  Future<void> _addNewAddress() async {
    final newAddress = await Navigator.push<Address>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditAddressScreen(),
      ),
    );

    if (newAddress != null) {
      setState(() {
        _selectedAddress = newAddress;
      });
    }
  }

  Future<void> _handlePlaceOrder({
    required List<CartItem> items,
    required Address address,
    required double subtotal,
    required double discount,
    required double deliveryFee,
    required double total,
    required bool isDirect,
  }) async {
    // 1. Validation
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your checkout cart is empty. Add products to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final item in items) {
      if (item.product.isOutOfStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.product.name}" is out of stock. Please remove it from your cart.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (item.quantity > item.product.availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.product.name}" only has ${item.product.availableStock} in stock. Please reduce quantity.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);

    // Short realistic order placement simulation (zero-cost local processing)
    await Future.delayed(const Duration(milliseconds: 650));

    final newOrder = ref.read(ordersProvider.notifier).createOrder(
      items: items,
      totalAmount: total,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      address: address,
      deliveryMethod: '${_selectedDeliveryMethod.title} (${_selectedDeliveryMethod.estimatedDays})',
      paymentMethod: _selectedPaymentMethod.title,
      estimatedDelivery: _selectedDeliveryMethod.id == 'express' ? '1–2 business days' : '2–4 business days',
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (!isDirect) {
      ref.read(cartProvider.notifier).clearCart();
      ref.read(appliedCouponProvider.notifier).update(null);
    }

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    // Navigate to Order Success Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSuccessScreen(order: newOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isDirect = widget.directCheckoutItems != null && widget.directCheckoutItems!.isNotEmpty;
    final checkoutItems = isDirect ? widget.directCheckoutItems! : ref.watch(cartProvider);

    final addresses = ref.watch(addressesProvider);
    final effectiveAddress = _selectedAddress ??
        addresses.where((a) => a.isDefault).firstOrNull ??
        addresses.firstOrNull;

    final subtotal = checkoutItems.fold(0.0, (sum, i) => sum + i.subtotal);
    final coupon = isDirect ? null : ref.watch(appliedCouponProvider);

    // Calculate delivery fee
    double baseDeliveryFee = _selectedDeliveryMethod.fee;
    if (subtotal >= 2999 && _selectedDeliveryMethod.id == 'standard') {
      baseDeliveryFee = 0.0;
    }
    final discount = coupon != null ? coupon.calculateSavings(subtotal, baseDeliveryFee) : 0.0;
    final finalDeliveryFee = (coupon?.discountType == CouponDiscountType.freeShipping) ? 0.0 : baseDeliveryFee;
    final total = (subtotal - discount + finalDeliveryFee).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: checkoutItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No items to checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return to Cart'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== 1. DELIVERY ADDRESS ====================
                  _buildSectionHeader('1. Delivery Address', Icons.location_on_outlined, theme),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: effectiveAddress == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 8),
                                  Text(
                                    'No delivery address added yet',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Please enter your Pakistani street and house address to proceed with checkout.',
                                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12.5),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _addNewAddress,
                                icon: const Icon(Icons.add_location_alt_outlined),
                                label: const Text('Add Delivery Address'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        effectiveAddress.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      if (effectiveAddress.isDefault) ...[
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
                                  TextButton.icon(
                                    onPressed: () => _chooseAddress(addresses),
                                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                    label: const Text('Change'),
                                  ),
                                ],
                              ),
                              Text(
                                effectiveAddress.phone,
                                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                effectiveAddress.formattedAddress,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== 2. DELIVERY METHOD ====================
                  _buildSectionHeader('2. Delivery Method', Icons.local_shipping_outlined, theme),
                  const SizedBox(height: 8),
                  Column(
                    children: defaultDeliveryMethods.map((method) {
                      final isSelected = _selectedDeliveryMethod.id == method.id;
                      final isFree = (method.id == 'standard' && (subtotal >= 2999 || coupon?.discountType == CouponDiscountType.freeShipping));

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
                          onTap: () {
                            setState(() {
                              _selectedDeliveryMethod = method;
                            });
                            ref.read(selectedDeliveryMethodProvider.notifier).selectMethod(method);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              method.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isFree ? 'FREE' : CurrencyFormat.format(method.fee),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: isFree ? const Color(0xFF10B981) : theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Estimated: ${method.estimatedDays} • ${method.description}',
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
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ==================== 3. PAYMENT METHOD ====================
                  _buildSectionHeader('3. Payment Method', Icons.payment_outlined, theme),
                  const SizedBox(height: 8),
                  Column(
                    children: availablePaymentOptions.map((option) {
                      final isSelected = _selectedPaymentMethod.id == option.id;
                      final isAvailable = option.isAvailable;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isAvailable ? theme.colorScheme.surface : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: isAvailable
                              ? () {
                                  setState(() => _selectedPaymentMethod = option);
                                  ref.read(selectedPaymentMethodProvider.notifier).selectMethod(option);
                                }
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(option.title),
                                      content: const Text(
                                        'Digital card and mobile wallet gateways are planned for future backend integration.\n\nFor now, Cash on Delivery is 100% active with nationwide zero-fee coverage.',
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                      ],
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Icon(
                                  option.type == PaymentType.cashOnDelivery
                                      ? Icons.payments_outlined
                                      : (option.type == PaymentType.card
                                          ? Icons.credit_card_rounded
                                          : (option.type == PaymentType.mobileWallet
                                              ? Icons.account_balance_wallet_outlined
                                              : Icons.account_balance_rounded)),
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isAvailable ? Colors.grey.shade600 : Colors.grey.shade400),
                                  size: 24,
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
                                              option.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isAvailable ? null : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          if (option.badgeText != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (option.isAvailable ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                option.badgeText!,
                                                style: TextStyle(
                                                  color: option.isAvailable ? const Color(0xFF047857) : const Color(0xFF475569),
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
                                        option.subtitle,
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAvailable)
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

                  // ==================== 4. ORDER ITEMS ====================
                  _buildSectionHeader('4. Order Items (${checkoutItems.length})', Icons.inventory_2_outlined, theme),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: checkoutItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = checkoutItems[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 56,
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
                                    maxLines: 1,
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
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormat.format(item.subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== 5. PROMO / COUPON FOUNDATION ====================
                  _buildSectionHeader('5. Promo Voucher & Delivery Notes', Icons.local_offer_outlined, theme),
                  const SizedBox(height: 8),
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
                        if (coupon != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Coupon ${coupon.code} active (-${CurrencyFormat.format(discount)})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 13),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    ref.read(appliedCouponProvider.notifier).update(null);
                                    _couponController.clear();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. WELCOME10, SAVE500',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _applyCoupon(subtotal, baseDeliveryFee),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                          if (_couponError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(_couponError!, style: const TextStyle(color: Colors.red, fontSize: 11.5)),
                            ),
                        ],
                        const SizedBox(height: 14),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            hintText: 'Delivery instructions (e.g. Ring bell twice, leave with guard)',
                            hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== 6. PRICE SUMMARY ====================
                  _buildSectionHeader('6. Price Summary', Icons.receipt_long_outlined, theme),
                  const SizedBox(height: 8),
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
                      children: [
                        _buildPriceRow('Items Subtotal', CurrencyFormat.format(subtotal), theme),
                        if (discount > 0)
                          _buildPriceRow(
                            'Coupon Savings (${coupon?.code ?? ""})',
                            '-${CurrencyFormat.format(discount)}',
                            theme,
                            color: const Color(0xFF10B981),
                          ),
                        _buildPriceRow(
                          'Delivery Fee (${_selectedDeliveryMethod.title})',
                          finalDeliveryFee == 0 ? 'FREE' : CurrencyFormat.format(finalDeliveryFee),
                          theme,
                          color: finalDeliveryFee == 0 ? const Color(0xFF10B981) : null,
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
                  const SizedBox(height: 30),
                ],
              ),
            ),

      // ==================== BOTTOM STICKY PLACE ORDER CTA ====================
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${checkoutItems.length} items)',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11.5),
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
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isPlacingOrder
                      ? null
                      : () {
                          if (effectiveAddress == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please add or select a delivery address in Pakistan to complete order.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _addNewAddress();
                            return;
                          }

                          _handlePlaceOrder(
                            items: checkoutItems,
                            address: effectiveAddress,
                            subtotal: subtotal,
                            discount: discount,
                            deliveryFee: finalDeliveryFee,
                            total: total,
                            isDirect: isDirect,
                          );
                        },
                  icon: _isPlacingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(_isPlacingOrder ? 'Processing...' : 'Place Order (COD)'),
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

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
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
