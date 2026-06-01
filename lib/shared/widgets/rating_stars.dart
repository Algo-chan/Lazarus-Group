import 'package:flutter/material.dart';

class RatingStarsWidget extends StatefulWidget {
  final double rating;
  final double? starSize;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.starSize,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  State<RatingStarsWidget> createState() => _RatingStarsWidgetState();
}

class _RatingStarsWidgetState extends State<RatingStarsWidget>
    with SingleTickerProviderStateMixin {
  late double _currentRating;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int _animatingStarIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onStarTap(int starIndex) {
    if (!widget.interactive) return;
    final newRating = starIndex.toDouble();
    setState(() => _currentRating = newRating);
    _animatingStarIndex = starIndex;
    _bounceController.forward(from: 0);
    widget.onRatingChanged?.call(newRating);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.starSize ?? 24.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        IconData icon;
        if (_currentRating >= starIndex) {
          icon = Icons.star;
        } else if (_currentRating >= starIndex - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        Widget star = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(icon, size: size, color: const Color(0xFFFFC107)),
        );

        if (widget.interactive && _animatingStarIndex == starIndex) {
          star = AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_bounceAnimation.value * 0.3),
                child: child,
              );
            },
            child: star,
          );
        }

        if (widget.interactive) {
          return GestureDetector(
            onTap: () => _onStarTap(starIndex),
            child: Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: star,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(right: 2),
          child: star,
        );
      }),
    );
  }
}
