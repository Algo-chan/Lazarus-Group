import 'package:flutter/material.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import 'api_service.dart';
import 'login_screen.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _currentIndex = 0;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  String _userName = 'Guest';
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
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

  void _navigateToDetail(ServiceCategory service) async {
    final isGuest = await ApiService.isGuest();
    if (isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to view details and contact providers'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } else {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailScreen(category: service)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: Building build()');
    return Scaffold(
      extendBody: true,
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
              accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('user@example.com'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            _buildDrawerItem(Icons.home_rounded, 'Home', () => Navigator.pop(context), true),
            _buildDrawerItem(Icons.person_rounded, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            }),
            _buildDrawerItem(Icons.history_rounded, 'My Bookings', () => Navigator.pop(context)),
            const Divider(indent: 20, endIndent: 20),
            _buildDrawerItem(Icons.settings_rounded, 'Settings', () => Navigator.pop(context)),
            const Spacer(),
            _buildDrawerItem(Icons.logout_rounded, 'Logout', () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            }, false, Colors.red),
            const SizedBox(height: 40),
          ],
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, [bool isSelected = false, Color? color]) {
    return ListTile(
      leading: Icon(icon, color: color ?? (isSelected ? Theme.of(context).primaryColor : null)),
      title: Text(title, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : null)),
      onTap: onTap,
      selected: isSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0.5,
      backgroundColor: Colors.white,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFF007BFF), size: 20),
          const SizedBox(width: 4),
          Text(
            'Addis Ababa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => ThemeManager.toggleTheme(),
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF007BFF),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.business_center), label: 'B2B'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 26,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          final icon = ServiceCategory._getIcon(cat);
          final color = ServiceCategory._getColor(cat);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
              return _FeaturedServiceCard(service: service, onTap: _navigateToDetail);
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
                return _ProfessionalServiceCard(service: service, onTap: _navigateToDetail);
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
  final Function(ServiceCategory) onTap;
  const _FeaturedServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(service),
      child: Container(
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
      ),
    );
  }
}

class _ProfessionalServiceCard extends StatelessWidget {
  final ServiceCategory service;
  final Function(ServiceCategory) onTap;
  const _ProfessionalServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => onTap(service),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(service.image, width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (service.verified)
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    service.rating.toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const Icon(Icons.star, color: Colors.white, size: 10),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${service.reviewsCount} Ratings',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.location,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open until 8:00 PM',
                          style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(context, Icons.phone, 'Call Now', const Color(0xFF007BFF)),
                  _buildActionButton(context, Icons.chat_bubble_outline, 'WhatsApp', Colors.green),
                  _buildActionButton(context, Icons.email_outlined, 'Enquire', const Color(0xFFF47E20)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => onTap(service),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
