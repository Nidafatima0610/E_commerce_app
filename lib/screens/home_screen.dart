import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../core/currency_format.dart';
import 'search_screen.dart';
import 'product_list_screen.dart';
import 'product_details_screen.dart';
import 'deals_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'tag': 'SUMMER MEGA SALE',
      'title': 'Up to 50% Off Top Brands',
      'subtitle': 'Explore premium headphones, sneakers & eastern wear across Pakistan',
      'buttonText': 'Shop Deals',
      'gradient': [const Color(0xFF1E3A8A), const Color(0xFF2563EB), const Color(0xFF3B82F6)],
      'badgeColor': const Color(0xFFFBBF24),
      'badgeTextColor': const Color(0xFF0F172A),
      'icon': Icons.bolt_rounded,
      'destination': 'deals',
    },
    {
      'tag': 'FLAGSHIP ELECTRONICS',
      'title': 'Next-Gen Sound & Audio Gear',
      'subtitle': 'Authentic Sony, Bose & Apple devices with official local warranties',
      'buttonText': 'Explore Tech',
      'gradient': [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
      'badgeColor': const Color(0xFF38BDF8),
      'badgeTextColor': const Color(0xFF0F172A),
      'icon': Icons.headphones_rounded,
      'destination': 'electronics',
    },
    {
      'tag': 'NEW FESTIVE DROP',
      'title': 'Khaadi, J. & Sapphire Pret',
      'subtitle': 'Pure raw silk, embroidered lawn suits & modern tailored kurtas',
      'buttonText': 'Browse Fashion',
      'gradient': [const Color(0xFF831843), const Color(0xFFBE185D), const Color(0xFFDB2777)],
      'badgeColor': const Color(0xFFFDE047),
      'badgeTextColor': const Color(0xFF831843),
      'icon': Icons.checkroom_rounded,
      'destination': 'fashion',
    },
    {
      'tag': 'EXPRESS DELIVERY',
      'title': '24-Hour Delivery in Lahore & ISB',
      'subtitle': 'Order everyday fitness equipment, sneakers & luxury timepieces today',
      'buttonText': 'Shop Best Sellers',
      'gradient': [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF059669)],
      'badgeColor': const Color(0xFF34D399),
      'badgeTextColor': const Color(0xFF064E3B),
      'icon': Icons.local_shipping_rounded,
      'destination': 'bestsellers',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % _promoBanners.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.headphones_outlined;
      case 'mobiles':
        return Icons.smartphone_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'shoes':
        return Icons.snowshoeing_outlined;
      case 'watches':
        return Icons.watch_outlined;
      case 'bags & accessories':
      case 'bags':
        return Icons.backpack_outlined;
      case 'home & living':
        return Icons.kitchen_outlined;
      case 'beauty & care':
      case 'beauty':
        return Icons.spa_outlined;
      case 'sports & fitness':
      case 'sports':
        return Icons.fitness_center_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _handleBannerTap(String destination) {
    switch (destination) {
      case 'deals':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DealsScreen(),
          ),
        );
        break;
      case 'electronics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductListScreen(
              title: 'Electronics',
              initialCategory: 'Electronics',
            ),
          ),
        );
        break;
      case 'fashion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductListScreen(
              title: 'Fashion & Apparel',
              initialCategory: 'Fashion',
            ),
          ),
        );
        break;
      case 'bestsellers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductListScreen(
              title: 'Best Sellers',
              onlyBestsellers: true,
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductListScreen(title: 'All Products'),
          ),
        );
    }
  }

  void _showCityPicker(BuildContext context, String currentCity) {
    final cities = [
      'Gulberg, Lahore',
      'DHA Phase 5, Lahore',
      'Clifton, Karachi',
      'DHA Phase 6, Karachi',
      'Sector F-7/2, Islamabad',
      'Sector F-10, Islamabad',
      'Bahria Town, Rawalpindi',
      'Civil Lines, Faisalabad',
      'University Town, Peshawar',
      'Cantt, Multan',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Choose your city for accurate shipping estimates and express courier dispatch.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = city == currentCity;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(deliveryCityProvider.notifier).setCity(city);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Delivery address set to $city'),
                            duration: const Duration(milliseconds: 1400),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onSeeAll,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductList({
    required List<Product> products,
    double height = 275,
  }) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return ProductCard(
            product: products[index],
            width: 175,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = ref.watch(categoriesProvider);
    final dealProducts = ref.watch(dealProductsProvider);
    final popularProducts = ref.watch(featuredProductsProvider);
    final bestSellers = ref.watch(bestsellerProductsProvider);
    final newArrivals = ref.watch(newArrivalProductsProvider);
    final dealsOfTheDay = ref.watch(dealsOfTheDayProvider);
    final recommendedProducts = ref.watch(recommendedProductsProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);
    final userProfile = ref.watch(userProfileProvider);
    final deliveryCity = ref.watch(deliveryCityProvider);
    final unreadCount = ref.watch(notificationCountProvider);
    final orders = ref.watch(ordersProvider);
    final personalizedSections = ref.watch(personalizedHomeSectionsProvider);

    // Extract products from previous orders for "Buy Again"
    final buyAgainProducts = <Product>[];
    final seenIds = <String>{};
    for (final order in orders) {
      for (final item in order.items) {
        if (!seenIds.contains(item.product.id)) {
          seenIds.add(item.product.id);
          buyAgainProducts.add(item.product);
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== 1. TOP BAR ====================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    // Location & Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Welcome back, ${userProfile.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _showCityPicker(context, deliveryCity),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    deliveryCity,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification Icon with Badge
                    IconButton(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(unreadCount.toString()),
                        child: const Icon(Icons.notifications_outlined, size: 24),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 4),

                    // Profile Avatar
                    InkWell(
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).setIndex(4);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================== 2. SEARCH BAR ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search 75+ products, brands, tech, fashion...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ==================== 3. PROMOTIONAL CAROUSEL ====================
              SizedBox(
                height: 165,
                child: PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (index) {
                    setState(() => _currentBannerIndex = index);
                  },
                  itemCount: _promoBanners.length,
                  itemBuilder: (context, index) {
                    final banner = _promoBanners[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: banner['gradient'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (banner['gradient'][1] as Color).withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -15,
                              child: Icon(
                                banner['icon'] as IconData,
                                size: 140,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: banner['badgeColor'] as Color,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          banner['tag'] as String,
                                          style: TextStyle(
                                            color: banner['badgeTextColor'] as Color,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        banner['title'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        banner['subtitle'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _handleBannerTap(banner['destination'] as String),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: banner['gradient'][0] as Color,
                                      minimumSize: const Size(80, 30),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      banner['buttonText'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Carousel Indicators
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_promoBanners.length, (index) {
                  final isSelected = index == _currentBannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 18 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.grey[700] : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // ==================== 4. CATEGORIES ====================
              _buildSectionHeader(
                context: context,
                title: 'Categories',
                subtitle: 'Browse 9 departments & 75+ products',
                onSeeAll: () {
                  ref.read(bottomNavIndexProvider.notifier).setIndex(1);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).update(category);
                        ref.read(bottomNavIndexProvider.notifier).setIndex(1);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: theme.colorScheme.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 72,
                            child: Text(
                              category,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // ==================== 5. FLASH DEALS ====================
              _buildSectionHeader(
                context: context,
                title: 'Flash Deals',
                subtitle: 'Special discounts active today only',
                icon: Icons.bolt,
                iconColor: const Color(0xFFEF4444),
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DealsScreen(initialTabIndex: 0),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildHorizontalProductList(products: dealProducts),
              const SizedBox(height: 24),

              // ==================== 6. BEST SELLERS ====================
              _buildSectionHeader(
                context: context,
                title: 'Best Sellers',
                subtitle: 'Most ordered across all categories',
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(
                        title: 'Best Sellers',
                        onlyBestsellers: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildHorizontalProductList(products: bestSellers),
              const SizedBox(height: 24),

              // ==================== 7. NEW ARRIVALS ====================
              _buildSectionHeader(
                context: context,
                title: 'New Arrivals',
                subtitle: 'Fresh drops & latest releases',
                icon: Icons.fiber_new_rounded,
                iconColor: const Color(0xFF10B981),
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(
                        title: 'New Arrivals',
                        onlyNewArrivals: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildHorizontalProductList(products: newArrivals),
              const SizedBox(height: 24),

              // ==================== 8. DEALS OF THE DAY ====================
              _buildSectionHeader(
                context: context,
                title: 'Deals of the Day',
                subtitle: 'Biggest percentage markdowns',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFEA580C),
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DealsScreen(initialTabIndex: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildHorizontalProductList(products: dealsOfTheDay),
              const SizedBox(height: 24),

              // ==================== 9. POPULAR PRODUCTS ====================
              _buildSectionHeader(
                context: context,
                title: 'Popular Products',
                subtitle: 'Top rated picks loved by Pakistani customers',
                icon: Icons.thumb_up_rounded,
                iconColor: const Color(0xFF6366F1),
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(
                        title: 'Popular Products',
                        onlyFeatured: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildHorizontalProductList(products: popularProducts),
              const SizedBox(height: 24),

              // ==================== PERSONALIZED BEHAVIOR SECTIONS ====================
              for (final pSection in personalizedSections) ...[
                _buildSectionHeader(
                  context: context,
                  title: pSection.title,
                  subtitle: pSection.subtitle,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListScreen(
                          title: pSection.title,
                          initialCategory: pSection.category,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildHorizontalProductList(products: pSection.products),
                const SizedBox(height: 24),
              ],

              // ==================== 10. QUICK BUY AGAIN (Conditional) ====================
              if (buyAgainProducts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.replay_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buy Again',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Quickly reorder your previous items',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: buyAgainProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final product = buyAgainProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                        child: Container(
                          width: 250,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: ProductImage(
                                    imageUrl: product.image,
                                    category: product.category,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.brand,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormat.format(product.price),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () {
                                    ref.read(cartProvider.notifier).addItem(product);
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added ${product.name} to cart'),
                                        duration: const Duration(milliseconds: 1400),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ==================== 11. RECOMMENDED FOR YOU (GRID) ====================
              _buildSectionHeader(
                context: context,
                title: 'Recommended For You',
                subtitle: 'Personalized based on your browsing interests',
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(
                        title: 'Recommended For You',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: recommendedProducts.length > 8 ? 8 : recommendedProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: recommendedProducts[index]);
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ==================== 12. RECENTLY VIEWED ====================
              if (recentlyViewed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recently Viewed',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Products you checked out recently',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(recentlyViewedProvider.notifier).clear();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildHorizontalProductList(products: recentlyViewed),
                const SizedBox(height: 28),
              ],

              // ==================== 13. TRUST & SERVICE HIGHLIGHTS ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
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
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTrustItem(
                              icon: Icons.verified_outlined,
                              title: '100% Genuine',
                              subtitle: 'Original brand warranty',
                              color: const Color(0xFF10B981),
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                          Container(height: 40, width: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                          Expanded(
                            child: _buildTrustItem(
                              icon: Icons.payments_outlined,
                              title: 'Cash on Delivery',
                              subtitle: 'Pay at your doorstep',
                              color: const Color(0xFF2563EB),
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTrustItem(
                              icon: Icons.assignment_return_outlined,
                              title: '7-Day Returns',
                              subtitle: 'Hassle-free exchanges',
                              color: const Color(0xFFF59E0B),
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                          Container(height: 40, width: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                          Expanded(
                            child: _buildTrustItem(
                              icon: Icons.local_shipping_outlined,
                              title: 'TCS Express',
                              subtitle: 'Nationwide safe shipping',
                              color: const Color(0xFF8B5CF6),
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
