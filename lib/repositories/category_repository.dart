import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final List<String> subcategories;
  final String bannerImageUrl;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.subcategories = const [],
    this.bannerImageUrl = '',
  });
}

abstract class CategoryRepository {
  List<CategoryItem> getCategories();
  CategoryItem? getCategoryByName(String name);
}

class LocalCategoryRepository implements CategoryRepository {
  static const List<CategoryItem> _categories = [
    CategoryItem(
      id: 'cat_electronics',
      name: 'Electronics',
      icon: Icons.headphones_outlined,
      description: 'Audio gear, chargers, smart devices & computing peripherals',
      subcategories: ['Headphones', 'Earbuds', 'Speakers', 'Power Banks', 'Accessories'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_mobiles',
      name: 'Mobiles',
      icon: Icons.smartphone_outlined,
      description: 'Flagship smartphones, tablets, high-speed adapters & screen protectors',
      subcategories: ['Smartphones', 'Tablets', 'Chargers', 'Mobile Accessories'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_fashion',
      name: 'Fashion',
      icon: Icons.checkroom_outlined,
      description: 'Men’s & Women’s seasonal apparel, eastern wear, kurtas & jackets',
      subcategories: ["Men's Clothing", "Women's Clothing", 'Eastern Wear', 'Jackets & Hoodies'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_shoes',
      name: 'Shoes',
      icon: Icons.snowshoeing_outlined,
      description: 'Sneakers, formal leather shoes, athletic runners & casual loafers',
      subcategories: ['Sneakers', 'Running Shoes', 'Formal Shoes', 'Loafers'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_watches',
      name: 'Watches',
      icon: Icons.watch_outlined,
      description: 'Smart fitness watches, classic chronograph timepieces & luxury bands',
      subcategories: ['Smart Watches', 'Luxury Watches', 'Chronographs', 'Straps'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_bags',
      name: 'Bags & Accessories',
      icon: Icons.backpack_outlined,
      description: 'Travel backpacks, leather wallets, sunglasses, luggage & laptop sleeves',
      subcategories: ['Backpacks', 'Wallets', 'Sunglasses', 'Travel Gear'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_home',
      name: 'Home & Living',
      icon: Icons.kitchen_outlined,
      description: 'Kitchen appliances, modern lighting, organizers & room aesthetic decor',
      subcategories: ['Kitchen', 'Home Decor', 'Lighting', 'Storage'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_beauty',
      name: 'Beauty & Care',
      icon: Icons.spa_outlined,
      description: 'Premium skincare, designer fragrances, hair care & grooming kits',
      subcategories: ['Skincare', 'Fragrances', 'Hair Care', 'Grooming'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80',
    ),
    CategoryItem(
      id: 'cat_sports',
      name: 'Sports & Fitness',
      icon: Icons.fitness_center_outlined,
      description: 'Gym equipment, yoga mats, resistance gear, fitness apparel & shaker bottles',
      subcategories: ['Fitness Equipment', 'Yoga & Pilates', 'Accessories', 'Activewear'],
      bannerImageUrl: 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=800&q=80',
    ),
  ];

  @override
  List<CategoryItem> getCategories() => List.unmodifiable(_categories);

  @override
  CategoryItem? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase() ||
               c.name.toLowerCase().contains(name.toLowerCase()) ||
               name.toLowerCase().contains(c.name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }
}
