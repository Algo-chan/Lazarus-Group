import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'providers/auth_provider.dart';
import 'shared/widgets/rating_stars.dart';
import 'shared/widgets/provider_verified_badge.dart';
import 'shared/widgets/etb_price_tag.dart';
import 'shared/widgets/loading_widget.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Map<String, dynamic>? _service;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getServiceById(widget.serviceId),
        ApiService.getServiceReviews(widget.serviceId),
        _checkIfCanReview(),
      ]);
      if (mounted) {
        setState(() {
          _service = results[0] as Map<String, dynamic>?;
          _reviews = results[1] as List<dynamic>? ?? [];
          _canReview = results[2] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkIfCanReview() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return false;
    
    try {
      final bookings = await ApiService.getMyBookings();
      // Check if there's a completed booking for this service that hasn't been reviewed yet
      // For simplicity, we just check if any booking for this service is completed
      return bookings.any((b) => b['serviceId'] == widget.serviceId && b['status'] == 'completed');
    } catch (_) {
      return false;
    }
  }

  Future<void> _launchPhone() async {
    final phone = _service?['contact_phone'] ?? _service?['contact']?['phone'];
    if (phone != null) {
      final url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = _service?['contact_whatsapp'] ?? _service?['contact']?['whatsapp'];
    if (phone != null) {
      final cleanPhone = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
      final url = Uri.parse('https://wa.me/$cleanPhone');
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: LoadingWidget(message: 'Loading service details...')));
    if (_service == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Service not found')));

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final images = _service!['images'] as List? ?? [_service!['image']];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'service_image_${widget.serviceId}',
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final img = images[index];
                    if (img == null) return Container(color: Colors.grey);
                    return img.startsWith('assets')
                        ? Image.asset(img, fit: BoxFit.cover)
                        : Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey));
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_service!['title'] ?? 'Service', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_service!['category'] ?? 'General', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (_service!['verified'] == true) const ProviderVerifiedBadge(),
                    ],
                  ).animate().fade().slideY(begin: 0.1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingStarsWidget(rating: (_service!['avgRating'] ?? _service!['rating'] ?? 0).toDouble(), starSize: 18),
                      const SizedBox(width: 8),
                      Text('(${_service!['reviewCount'] ?? _service!['reviewsCount'] ?? 0} reviews)', style: theme.textTheme.bodySmall),
                    ],
                  ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
                  const SizedBox(height: 24),
                  Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_service!['description'] ?? '', maxLines: _isDescriptionExpanded ? null : 4, overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis),
                        Text(_isDescriptionExpanded ? 'Show less' : 'Read more', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
                  const SizedBox(height: 32),
                  _buildProviderCard(theme, colors),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildContactButton(Icons.phone, 'Call', Colors.blue, _launchPhone),
                      _buildContactButton(Icons.message, 'WhatsApp', Colors.green, _launchWhatsApp),
                      _buildContactButton(Icons.chat_bubble, 'Chat', colors.primary, _openChat),
                    ],
                  ).animate().fade().slideY(begin: 0.1, delay: 400.ms),
                  const SizedBox(height: 40),
                  _buildReviewsSection(theme, colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme, colors),
    );
  }

  Widget _buildProviderCard(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(radius: 24, child: Text(_service!['provider']?[0].toUpperCase() ?? 'P')),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_service!['provider'] ?? 'Unknown Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Professional Partner', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(onPressed: () => context.push('/provider/${_service!['provider_id']}'), child: const Text('Profile')),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (_canReview)
              TextButton.icon(
                onPressed: () => context.push('/customer/review/${widget.serviceId}/${_service!['id']}', extra: {'serviceName': _service!['title'], 'providerId': _service!['provider_id']}),
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Write Review'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No reviews yet. Be the first!')))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(review['reviewerName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      RatingStarsWidget(rating: (review['rating'] ?? 0).toDouble(), starSize: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review['comment'] ?? '', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_formatDate(review['createdAt']), style: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.5), fontSize: 11)),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Price', style: TextStyle(fontSize: 12)),
              ETBPriceTag(price: _service!['price'], fontSize: 20),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: FilledButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (!auth.isAuthenticated) {
                  context.push('/login');
                } else {
                  context.push('/customer/book/${widget.serviceId}', extra: {
                    'serviceName': _service!['title'],
                    'providerId': _service!['provider_id'],
                    'providerName': _service!['provider'],
                  });
                }
              },
              child: const Text('Book Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _openChat() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    try {
      final chat = await ApiService.createChat(serviceId: widget.serviceId);
      if (mounted) context.push('/customer/chat/${chat['id']}', extra: _service!['provider']);
    } catch (_) {}
  }

  String _formatDate(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }
}
