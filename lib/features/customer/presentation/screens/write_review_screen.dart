import 'package:flutter/material.dart';
import 'package:local_service_app/api_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String? bookingId;

  const WriteReviewScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    this.bookingId,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  void _onStarTap(int index) {
    setState(() => _rating = index + 1);
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await ApiService.submitReview(
        serviceId: widget.serviceId,
        rating: _rating,
        comment: comment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your review!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Rate your experience with',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.serviceName,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isSelected = index < _rating;
              return IconButton(
                iconSize: 48,
                icon: Icon(isSelected ? Icons.star : Icons.star_border, color: isSelected ? Colors.amber : Colors.grey),
                onPressed: () => _onStarTap(index),
              );
            }),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Share your experience with others...',
              labelText: 'Your Review',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
