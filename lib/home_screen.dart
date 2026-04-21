import 'package:flutter/material.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import 'api_service.dart';
import 'theme_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Color themeColor;

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
    required this.themeColor,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] ?? '';
    return ServiceCategory(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: _getIcon(cat),
      provider: json['provider'] ?? '',
      contactPhone: json['contact']?['phone'] ?? '+251 000 000 000',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      price: json['price'] ?? '',
      location: json['location'] ?? '',
      verified: json['verified'] ?? false,
      image: json['image'] ?? 'assets/images/photo-1.jpg',
      themeColor: _getColor(cat),
    );
  }

  static IconData _getIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('plumbing')) return Icons.plumbing_rounded;
    if (category.contains('electric')) return Icons.electrical_services_rounded;
    if (category.contains('clean')) return Icons.cleaning_services_rounded;
    if (category.contains('garden')) return Icons.yard_rounded;
    if (category.contains('paint')) return Icons.format_paint_rounded;
    return Icons.miscellaneous_services_rounded;
  }

  static Color _getColor(String category) {
    category = category.toLowerCase();
    if (category.contains('plumbing')) return Colors.blue;
    if (category.contains('electric')) return Colors.orange;
    if (category.contains('clean')) return Colors.teal;
    if (category.contains('garden')) return Colors.green;
    if (category.contains('paint')) return Colors.purple;
    return Colors.indigo;
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
  String _userName = 'Guest';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final cats = await ApiService.getCategories();
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      setState(() {
        _userName = user['name'] ?? 'User';
      });
    }
    setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                _buildSectionHeader('Categories', () {}),
                _buildCategories(),
                _buildSectionHeader('Featured Services', () {}),
                _buildFeaturedServices(),
                _buildSectionHeader('Popular Near You', () {}),
              ],
            ),
          ),
          _buildServiceList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: Theme.of(context).scaffoldBackgroundColor),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $_userName', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal)),
                Text('Find Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) {
                    return IconButton(
                      onPressed: () {
                        themeNotifier.value = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                      },
                      icon: Icon(
                        mode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF6C63FF)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search for any service...',
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          final icon = ServiceCategory._getIcon(cat);
          final color = ServiceCategory._getColor(cat);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    child: Icon(icon, color: isSelected ? Colors.white : color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedServices() {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<dynamic>>(
        future: ApiService.getServices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final services = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.length > 3 ? 3 : services.length,
            itemBuilder: (context, index) {
              final service = ServiceCategory.fromJson(services[index]);
              return _FeaturedServiceCard(service: service);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceList() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getServices(query: _searchQuery, category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
        }
        final services = snapshot.data ?? [];
        if (services.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text('No services found.')));
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final service = ServiceCategory.fromJson(services[index]);
                return _ProfessionalServiceCard(service: service);
              },
              childCount: services.length,
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedServiceCard extends StatelessWidget {
  final ServiceCategory service;
  const _FeaturedServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(service.image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              child: Text(service.price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Text(service.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${service.rating} (${service.reviewsCount} reviews)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(service.image, width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  if (service.verified)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(service.provider, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(service.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 4),
                        Text('(${service.reviewsCount})', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const Spacer(),
                        Text(service.price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(service.location, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
