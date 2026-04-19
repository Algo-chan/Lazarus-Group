import 'package:flutter/material.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import 'api_service.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String provider;
  final String contactPhone;
  final double rating;
  final int reviewsCount;
  final String price;
  final String location;
  final bool verified;
  final String image;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.provider,
    required this.contactPhone,
    required this.rating,
    required this.reviewsCount,
    required this.price,
    required this.location,
    required this.verified,
    required this.image,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: _getIcon(json['category'] ?? ''),
      provider: json['provider'] ?? '',
      contactPhone: json['contact']?['phone'] ?? '+251 000 000 000',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      price: json['price'] ?? '',
      location: json['location'] ?? '',
      verified: json['verified'] ?? false,
      image: json['image'] ?? 'assets/images/photo-1.jpg',
    );
  }

  static IconData _getIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('plumbing')) return Icons.plumbing;
    if (category.contains('electric')) return Icons.electrical_services;
    if (category.contains('clean')) return Icons.cleaning_services;
    if (category.contains('garden')) return Icons.yard;
    if (category.contains('paint')) return Icons.format_paint;
    return Icons.work;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final cats = await ApiService.getCategories();
    setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('LocalConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Location Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Location Selector (Mock)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
                    const SizedBox(width: 8),
                    const Text('Bole, Addis Ababa', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search for "Plumber", "Cleaner"...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF1F2F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Horizontal Categories
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: const Color(0xFFFF6B35),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  ),
                );
              },
            ),
          ),

          // Service List
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: ApiService.getServices(query: _searchQuery, category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final services = snapshot.data ?? [];
                if (services.isEmpty) {
                  return const Center(child: Text('No results found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = ServiceCategory.fromJson(services[index]);
                    return _ProfessionalServiceCard(service: service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalServiceCard extends StatelessWidget {
  final ServiceCategory service;
  const _ProfessionalServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailScreen(category: service))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(service.image, width: 100, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (service.verified) const Icon(Icons.verified, color: Colors.blue, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(service.provider, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              Text(service.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 2),
                              const Icon(Icons.star, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${service.reviewsCount} Reviews', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(service.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Text(service.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35))),
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
}
