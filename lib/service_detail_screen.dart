import 'package:flutter/material.dart';
import 'home_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceCategory category;

  const ServiceDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Image.asset(
              category.image,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Verification
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (category.verified)
                        const Icon(Icons.verified, color: Colors.blue, size: 28),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Provider & Location
                  Text(
                    category.provider,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(category.location, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Rating & Reviews Summary
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            Text(category.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${category.reviewsCount} Ratings & Reviews', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Divider(height: 40),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(icon: Icons.call, label: 'Call Now', color: Colors.blue, onTap: () {}),
                      _ActionButton(icon: Icons.message, label: 'WhatsApp', color: Colors.green, onTap: () {}),
                      _ActionButton(icon: Icons.directions, label: 'Direction', color: Colors.orange, onTap: () {}),
                      _ActionButton(icon: Icons.share, label: 'Share', color: Colors.grey, onTap: () {}),
                    ],
                  ),
                  const Divider(height: 40),

                  // Description
                  const Text('About Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    category.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // Mock Reviews Section
                  const Text('Top Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _ReviewTile(name: 'Aman K.', rating: 5, comment: 'Excellent service! Very professional and arrived on time.'),
                  _ReviewTile(name: 'Selam W.', rating: 4, comment: 'Great job, but slightly expensive. Worth it for the quality though.'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Enquire Now'),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;

  const _ReviewTile({required this.name, required this.rating, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, backgroundColor: Colors.grey[300], child: Text(name[0], style: const TextStyle(fontSize: 10))),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < rating ? Colors.orange : Colors.grey[300]))),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}
