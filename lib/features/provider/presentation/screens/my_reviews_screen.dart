import 'package:flutter/material.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/core/services/secure_storage_service.dart';
import 'package:local_service_app/shared/widgets/rating_stars.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/empty_state.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final _api = ApiClient();
  final _storage = SecureStorageService();

  bool _loading = true;
  String? _error;
  List<dynamic> _allReviews = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userData = await _storage.getUserData();
      final providerId = userData?['id'] ?? userData?['_id'] ?? '';
      final data = await _api.get('${ApiConstants.reviews}/provider/$providerId');
      final reviews = data is List ? data : (data['reviews'] as List<dynamic>? ?? []);
      _allReviews = reviews;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load reviews';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filteredReviews {
    if (_filter == 'All') return _allReviews;
    final star = int.tryParse(_filter.replaceAll('★', '')) ?? 0;
    return _allReviews.where((r) => (r['rating'] as num? ?? 0).toInt() == star).toList();
  }

  double get _averageRating {
    if (_allReviews.isEmpty) return 0;
    final sum = _allReviews.fold<num>(0, (a, r) => a + (r['rating'] as num? ?? 0));
    return sum / _allReviews.length;
  }

  Map<int, int> get _ratingDistribution {
    final dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _allReviews) {
      final star = (r['rating'] as num? ?? 0).toInt();
      if (star >= 1 && star <= 5) dist[star] = dist[star]! + 1;
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: _loading
          ? const LoadingWidget(message: 'Loading reviews...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadReviews)
              : _allReviews.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.star_outline,
                      title: 'No Reviews Yet',
                      message: 'Reviews from customers will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildOverallRating(),
                          const SizedBox(height: 24),
                          _buildRatingDistribution(),
                          const SizedBox(height: 16),
                          _buildFilterChips(),
                          const SizedBox(height: 16),
                          ..._filteredReviews.map((review) => _buildReviewCard(review)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOverallRating() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF007BFF)),
            ),
            const SizedBox(height: 8),
            RatingStarsWidget(rating: _averageRating, starSize: 28),
            const SizedBox(height: 8),
            Text(
              '${_allReviews.length} review${_allReviews.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final dist = _ratingDistribution;
    final maxCount = dist.values.reduce((a, b) => a > b ? a : b).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(5, (index) {
            final star = 5 - index;
            final count = dist[star] ?? 0;
            final fraction = maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text('$star★', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text('$count', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', '5★', '4★', '3★', '2★', '1★'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: const Color(0xFF007BFF).withOpacity(0.15),
              checkmarkColor: const Color(0xFF007BFF),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final name = review['customer_name'] as String? ?? review['reviewerName'] as String? ?? 'Anonymous';
    final rating = (review['rating'] as num? ?? 0).toDouble();
    final comment = review['comment'] as String? ?? '';
    final date = review['created_at'] as String? ?? review['date'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF007BFF),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (date.isNotEmpty)
                  Text(
                    date.length >= 10 ? date.substring(0, 10) : date,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RatingStarsWidget(rating: rating, starSize: 16),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }
}
