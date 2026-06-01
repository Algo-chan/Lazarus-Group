import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/service_provider.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/provider_verified_badge.dart';

class PublicProviderProfile extends StatefulWidget {
  final String providerId;

  const PublicProviderProfile({super.key, required this.providerId});

  @override
  State<PublicProviderProfile> createState() => _PublicProviderProfileState();
}

class _PublicProviderProfileState extends State<PublicProviderProfile> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceProvider = context.watch<ServiceProvider>();
    
    // Mock provider data
    final providerName = 'Abebe Plumbing Solutions';
    final providerBio = 'Expert plumbing services with over 10 years of experience in Addis Ababa. Specializing in emergency repairs and new installations.';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          providerName[0],
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            providerName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.white, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Rating', '4.8', Icons.star_rounded, Colors.amber),
                      _buildStatItem('Jobs', '150+', Icons.work_rounded, Colors.blue),
                      _buildStatItem('Joined', '2 yrs', Icons.calendar_today_rounded, Colors.green),
                    ],
                  ).animate().fade().slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(providerBio).animate().fade().slideY(begin: 0.1, delay: 100.ms),

                  const SizedBox(height: 24),

                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Services'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Services List
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: serviceProvider.services.length > 3 ? 3 : serviceProvider.services.length,
                  itemBuilder: (context, index) {
                    final service = serviceProvider.services[index];
                    return ServiceCard(
                      service: service,
                      onTap: () => context.push('/service/${service['id'] ?? service['_id']}'),
                    ).animate().fade().slideX(begin: 0.1, delay: (index * 100).ms);
                  },
                ),

                // Reviews List
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return _buildReviewItem(theme).animate().fade().slideY(begin: 0.1, delay: (index * 100).ms);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReviewItem(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 16, child: Text('U')),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text('2 days ago', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            const RatingStarsWidget(rating: 5, starSize: 14),
            const SizedBox(height: 4),
            const Text('Great service! Abebe was very professional and fixed my leak in no time. Highly recommended.'),
          ],
        ),
      ),
    );
  }
}
