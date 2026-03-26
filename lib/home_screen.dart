import 'package:flutter/material.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';

class ServiceCategory {
  final String name;
  final String description;
  final IconData icon;
  final String contactName;
  final String contactPhone;

  ServiceCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.contactName,
    required this.contactPhone,
  });
}

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<ServiceCategory> _categories = [
    ServiceCategory(
      name: 'Plumbing',
      description: 'Pipe repair, installation, and maintenance services',
      icon: Icons.plumbing,
      contactName: 'Abebe Plumbing Services',
      contactPhone: '+251 911 234 567',
    ),
    ServiceCategory(
      name: 'Electrician',
      description: 'Electrical wiring, repair, and installation',
      icon: Icons.electrical_services,
      contactName: 'Kebede Electric',
      contactPhone: '+251 912 345 678',
    ),
    ServiceCategory(
      name: 'Cleaning',
      description: 'Home and office cleaning services',
      icon: Icons.cleaning_services,
      contactName: 'Clean Pro Services',
      contactPhone: '+251 913 456 789',
    ),
    ServiceCategory(
      name: 'Carpentry',
      description: 'Furniture making and wood repair',
      icon: Icons.hardware,
      contactName: 'Dawit Woodworks',
      contactPhone: '+251 914 567 890',
    ),
    ServiceCategory(
      name: 'Painting',
      description: 'Interior and exterior painting services',
      icon: Icons.format_paint,
      contactName: 'Color Masters',
      contactPhone: '+251 915 678 901',
    ),
    ServiceCategory(
      name: 'AC Repair',
      description: 'Air conditioning installation and repair',
      icon: Icons.ac_unit,
      contactName: 'Cool Air Services',
      contactPhone: '+251 916 789 012',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocalConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Categories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find the right professional for your needs',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _ServiceCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailScreen(
                            category: category,
                          ),
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
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
