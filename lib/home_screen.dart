import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/other_providers.dart';
import 'shared/widgets/app_logo.dart';
import 'shared/widgets/service_card.dart';
import 'shared/widgets/loading_widget.dart';
import 'core/enums/user_role.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _featuredController = PageController();
  Timer? _featuredTimer;
  int _currentFeaturedPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ServiceProvider>().fetchServices();
      context.read<ServiceProvider>().fetchCategories();
      
      if (auth.isAuthenticated && auth.token != null) {
        context.read<ChatProvider>().initSocket(auth.token!);
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
    _startFeaturedTimer();
  }

  void _startFeaturedTimer() {
    _featuredTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_featuredController.hasClients) {
        final serviceProvider = context.read<ServiceProvider>();
        final featuredCount = serviceProvider.services.length > 5 ? 5 : serviceProvider.services.length;
        if (featuredCount > 0) {
          _currentFeaturedPage = (_currentFeaturedPage + 1) % featuredCount;
          _featuredController.animateToPage(
            _currentFeaturedPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _featuredTimer?.cancel();
    _featuredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const AppLogo(size: 28, showText: true).animate().fade().slideX(begin: -0.2),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => context.push('/notifications'),
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ).animate().fade().slideX(begin: 0.2),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: authProvider.isAuthenticated
                ? InkWell(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        authProvider.currentUser?['name']?[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Login'),
                  ),
          ).animate().fade().slideX(begin: 0.2),
        ],
      ),
      drawer: _buildDrawer(context, authProvider, theme),
      body: RefreshIndicator(
        onRefresh: () async {
          await serviceProvider.fetchServices();
          await serviceProvider.fetchCategories();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authProvider.isAuthenticated && (authProvider.role == UserRole.provider || authProvider.role == UserRole.admin))
                _buildQuickRoleInfo(context, authProvider, theme),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Search for services...',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ).animate().fade().slideY(begin: 0.1),

              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Categories',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: serviceProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = serviceProvider.categories[index];
                    return _CategoryCard(category: category)
                        .animate()
                        .fade()
                        .slideX(begin: 0.2, delay: (150 + index * 50).ms);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Featured Carousel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Featured Services',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: serviceProvider.isLoading
                    ? const Center(child: LoadingWidget())
                    : PageView.builder(
                        controller: _featuredController,
                        itemCount: serviceProvider.services.length > 5 ? 5 : serviceProvider.services.length,
                        onPageChanged: (index) => setState(() => _currentFeaturedPage = index),
                        itemBuilder: (context, index) {
                          final service = serviceProvider.services[index];
                          return _FeaturedCard(service: service);
                        },
                      ),
              ).animate().fade().scale(begin: const Offset(0.95, 0.95), delay: 250.ms),

              const SizedBox(height: 24),

              // All Services
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Services',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/search'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.1, delay: 300.ms),
              
              if (serviceProvider.isLoading && serviceProvider.services.isEmpty)
                const Center(child: LoadingWidget(message: 'Loading services...'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: serviceProvider.services.length,
                  itemBuilder: (context, index) {
                    final service = serviceProvider.services[index];
                    return ServiceCard(
                      service: service,
                      onTap: () => context.push('/service/${service['id'] ?? service['_id']}'),
                    ).animate().fade().slideY(begin: 0.1, delay: (350 + index * 50).ms);
                  },
                ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: authProvider.isGuest
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Log in to book services and message providers!',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOut)
          : null,
    );
  }

  Widget _buildQuickRoleInfo(BuildContext context, AuthProvider auth, ThemeData theme) {
    final isProvider = auth.role == UserRole.provider;
    final title = isProvider ? 'Provider Overview' : 'Admin Overview';
    final actionLabel = isProvider ? 'Dashboard' : 'Console';
    final actionRoute = isProvider ? '/provider/dashboard' : '/admin/dashboard';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(isProvider ? Icons.business_center_rounded : Icons.admin_panel_settings_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Manage your ${isProvider ? 'services & bookings' : 'platform data'}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => context.push(actionRoute),
            child: Text(actionLabel),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.1);
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth, ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.currentUser?['name'] ?? (auth.isGuest ? 'Guest User' : 'LocalConnect User')),
            accountEmail: Text(auth.currentUser?['email'] ?? (auth.isGuest ? 'Browse Mode' : '')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (auth.currentUser?['name']?[0] ?? 'L').toUpperCase(),
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(Icons.home_rounded, 'Home', () => Navigator.pop(context), selected: true),
                
                if (auth.isAuthenticated) ...[
                  if (auth.role == UserRole.customer) ...[
                    _drawerTile(Icons.dashboard_rounded, 'My Dashboard', () {
                      Navigator.pop(context);
                      context.push('/customer');
                    }),
                    _drawerTile(Icons.calendar_month_rounded, 'My Bookings', () {
                      Navigator.pop(context);
                      context.push('/customer/bookings');
                    }),
                    _drawerTile(Icons.favorite_rounded, 'Saved Services', () {
                      Navigator.pop(context);
                      context.push('/customer/saved');
                    }),
                  ],
                  if (auth.role == UserRole.provider) ...[
                    _drawerTile(Icons.analytics_rounded, 'Provider Dashboard', () {
                      Navigator.pop(context);
                      context.push('/provider/dashboard');
                    }),
                    _drawerTile(Icons.build_circle_rounded, 'My Services', () {
                      Navigator.pop(context);
                      context.push('/provider/services');
                    }),
                    _drawerTile(Icons.upcoming_rounded, 'Incoming Bookings', () {
                      Navigator.pop(context);
                      context.push('/provider/bookings');
                    }),
                  ],
                  if (auth.role == UserRole.admin) ...[
                    _drawerTile(Icons.admin_panel_settings_rounded, 'Admin Console', () {
                      Navigator.pop(context);
                      context.push('/admin/dashboard');
                    }),
                  ],
                  _drawerTile(Icons.chat_rounded, 'Messages', () {
                    Navigator.pop(context);
                    context.push(auth.role == UserRole.provider ? '/provider/chats' : '/customer/chats');
                  }),
                ],

                const Divider(),
                _drawerTile(Icons.search_rounded, 'Find Services', () {
                  Navigator.pop(context);
                  context.push('/search');
                }),
                _drawerTile(Icons.settings_rounded, 'Settings', () {
                  Navigator.pop(context);
                  context.push('/settings');
                }),
              ],
            ),
          ),
          const Divider(),
          if (auth.isAuthenticated)
            _drawerTile(Icons.logout_rounded, 'Logout', () {
              Navigator.pop(context);
              auth.logout();
            }, color: Colors.red)
          else
            _drawerTile(Icons.login_rounded, 'Login / Signup', () {
              Navigator.pop(context);
              context.push('/login');
            }, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {bool selected = false, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: color)),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/search?category=$category'),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all': return Icons.grid_view_rounded;
      case 'plumbing': return Icons.plumbing_rounded;
      case 'electrician': return Icons.electrical_services_rounded;
      case 'cleaning': return Icons.cleaning_services_rounded;
      case 'gardening': return Icons.yard_rounded;
      case 'painting': return Icons.format_paint_rounded;
      case 'carpentry': return Icons.handyman_rounded;
      case 'ac repair': return Icons.ac_unit_rounded;
      case 'car mechanic': return Icons.directions_car_rounded;
      default: return Icons.miscellaneous_services_rounded;
    }
  }
}

class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> service;

  const _FeaturedCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/service/${service['id'] ?? service['_id']}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: service['image'] != null && service['image'].startsWith('assets')
                ? AssetImage(service['image']) as ImageProvider
                : NetworkImage(service['image'] ?? 'https://via.placeholder.com/400x200') as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service['category'] ?? 'Service',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service['title'] ?? service['name'] ?? 'Premium Service',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${service['rating'] ?? 0.0} (${service['reviewsCount'] ?? 0} reviews)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    service['price'] ?? 'Contact for price',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
