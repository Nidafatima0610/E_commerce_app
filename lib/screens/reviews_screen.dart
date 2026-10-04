import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/product_review.dart';
import '../providers/app_providers.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ReviewsScreen({super.key, required this.product});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  int? _selectedStarFilter; // null = all
  bool _onlyVerified = false;
  String _sortBy = 'recent'; // 'recent', 'highest', 'lowest'

  void _openWriteReviewSheet(BuildContext context, bool isVerified) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _WriteReviewSheet(
        product: widget.product,
        isVerified: isVerified,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allReviews = ref.watch(productReviewsProvider(widget.product.id));
    final breakdown = ref.watch(ratingBreakdownProvider(widget.product));
    final isPurchased = ref.watch(isProductPurchasedByUserProvider(widget.product.id));

    // Filter
    var filtered = allReviews.where((r) {
      if (_selectedStarFilter != null && r.rating.round() != _selectedStarFilter) {
        return false;
      }
      if (_onlyVerified && !r.verifiedPurchase) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    if (_sortBy == 'recent') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'highest') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'lowest') {
      filtered.sort((a, b) => a.rating.compareTo(b.rating));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Write a Review',
            onPressed: () => _openWriteReviewSheet(context, isPurchased),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. PRODUCT SUMMARY HEADER ====================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.product.brand} • ${widget.product.category}',
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
            const SizedBox(height: 16),

            // ==================== 2. OVERALL RATING & BREAKDOWN ====================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Overall Big Score
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${breakdown.averageRating}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          final filled = index < breakdown.averageRating.floor();
                          final half = index == breakdown.averageRating.floor() &&
                              (breakdown.averageRating - breakdown.averageRating.floor()) >= 0.5;
                          return Icon(
                            half
                                ? Icons.star_half_rounded
                                : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
                            color: const Color(0xFFF59E0B),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${breakdown.totalCount} ratings',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // 5 Star Bars
                  Expanded(
                    child: Column(
                      children: [
                        _buildBarRow('5★', breakdown.fiveStarRatio, breakdown.fiveStarCount, theme),
                        _buildBarRow('4★', breakdown.fourStarRatio, breakdown.fourStarCount, theme),
                        _buildBarRow('3★', breakdown.threeStarRatio, breakdown.threeStarCount, theme),
                        _buildBarRow('2★', breakdown.twoStarRatio, breakdown.twoStarCount, theme),
                        _buildBarRow('1★', breakdown.oneStarRatio, breakdown.oneStarCount, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== 3. FILTER CHIPS & SORT ====================
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStarFilter == null && !_onlyVerified,
                    onSelected: (_) {
                      setState(() {
                        _selectedStarFilter = null;
                        _onlyVerified = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  for (int star = 5; star >= 1; star--) ...[
                    FilterChip(
                      label: Text('$star ★'),
                      selected: _selectedStarFilter == star,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStarFilter = selected ? star : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text('Verified Only'),
                      ],
                    ),
                    selected: _onlyVerified,
                    onSelected: (selected) {
                      setState(() {
                        _onlyVerified = selected;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sort Selector Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Reviews',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.sort_rounded, size: 18),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                    DropdownMenuItem(value: 'highest', child: Text('Highest Rated')),
                    DropdownMenuItem(value: 'lowest', child: Text('Lowest Rated')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ==================== 4. REVIEWS LIST ====================
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No reviews match your filter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try resetting filters or be the first to write a review!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedStarFilter = null;
                          _onlyVerified = false;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset Filters'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = filtered[index];
                  return _ReviewCard(review: review);
                },
              ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWriteReviewSheet(context, isPurchased),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                isPurchased ? 'Write a Verified Review' : 'Write a Product Review',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarRow(String starLabel, double ratio, int count, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              starLabel,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ProductReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
          // Reviewer Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                        if (review.verifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 11, color: Color(0xFF10B981)),
                                SizedBox(width: 2),
                                Text(
                                  'Verified Purchase',
                                  style: TextStyle(
                                    color: Color(0xFF047857),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${review.userCity} • ${_formatReviewDate(review.createdAt)}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '${review.rating.toInt()}★',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.grey[200] : Colors.grey[850],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final Product product;
  final bool isVerified;

  const _WriteReviewSheet({
    required this.product,
    required this.isVerified,
  });

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (!_formKey.currentState!.validate()) return;

    final userProfile = ref.read(userProfileProvider);
    final deliveryCity = ref.read(deliveryCityProvider);
    ref.read(reviewsProvider.notifier).addReview(
      productId: widget.product.id,
      rating: _rating,
      comment: _commentController.text.trim(),
      userName: userProfile.name.isNotEmpty ? userProfile.name : 'Customer',
      userCity: deliveryCity.isNotEmpty ? deliveryCity : 'Pakistan',
      verifiedPurchase: widget.isVerified,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isVerified
              ? 'Thank you! Your verified review has been submitted.'
              : 'Thank you! Your review has been submitted.',
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Write a Review',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              if (widget.isVerified) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Verified Purchaser on This Account',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Rating Stars Picker
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_rating out of 5',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled = starNumber <= _rating;
                        return IconButton(
                          iconSize: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          icon: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                          onPressed: () {
                            setState(() => _rating = starNumber.toDouble());
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Comment Input
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'Share your genuine experience with this product in Pakistan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Please enter at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
