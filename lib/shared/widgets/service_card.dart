import 'package:flutter/material.dart';
import 'provider_verified_badge.dart';
import 'etb_price_tag.dart';

class ServiceCard extends StatelessWidget {
  final dynamic service;
  final VoidCallback? onTap;
  final bool featured;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = service['name'] as String? ?? 'Service';
    final providerName = service['provider_name'] as String? ?? '';
    final location = service['location'] as String? ?? '';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0.0;
    final price = service['price'];
    final imageUrl = service['image'] as String?;
    final isVerified = service['verified'] as bool? ?? false;
    final serviceId = service['id'] as String? ?? '';

    final cardWidth = featured ? double.infinity : 220.0;
    final imageHeight = featured ? 160.0 : 120.0;
    final titleSize = featured ? 16.0 : 14.0;
    final subtitleSize = featured ? 13.0 : 11.0;

    Widget imageWidget;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.asset(
        imageUrl,
        width: cardWidth,
        height: imageHeight,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackIcon(theme),
      );
    } else {
      imageWidget = _buildFallbackIcon(theme);
    }

    if (featured) {
      imageWidget = Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Hero(
        tag: 'service_$serviceId',
        child: Container(
          width: cardWidth,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: cardWidth,
                  height: imageHeight,
                  child: imageWidget,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(featured ? 16 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: featured ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: ProviderVerifiedBadge(showLabel: false, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (providerName.isNotEmpty) ...[
                      Text(
                        providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                          color: featured
                              ? Colors.white.withValues(alpha: 0.9)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: subtitleSize + 2,
                          color: featured
                              ? Colors.white.withValues(alpha: 0.8)
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location.isNotEmpty ? location : 'Ethiopia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: featured
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RatingStarDisplay(rating: rating, size: subtitleSize + 2),
                        ETBPriceTag(
                          price: price,
                          fontSize: titleSize,
                          color: featured ? Colors.white : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Icon(
        Icons.build_circle_outlined,
        size: 48,
        color: theme.colorScheme.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

class _RatingStarDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const _RatingStarDisplay({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: const Color(0xFFFFC107)),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFC107),
          ),
        ),
      ],
    );
  }
}
