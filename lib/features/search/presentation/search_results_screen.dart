import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/service_provider.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedCity = 'All Cities';
  String _sortBy = 'Popular';

  final List<String> _cities = [
    'All Cities',
    'Addis Ababa',
    'Adama',
    'Bahir Dar',
    'Dire Dawa',
    'Hawassa',
    'Mekelle',
    'Gondar',
    'Jimma',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      if (queryParams.containsKey('category')) {
        setState(() => _selectedCategory = queryParams['category']!);
      }
      _performSearch();
    });
  }

  void _performSearch() {
    context.read<ServiceProvider>().fetchServices(
      query: _searchController.text,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: 'Search for services...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Category Chip
                _buildFilterChip(
                  label: _selectedCategory,
                  icon: Icons.category_rounded,
                  onTap: _showCategoryPicker,
                ),
                const SizedBox(width: 8),
                // City Chip
                _buildFilterChip(
                  label: _selectedCity,
                  icon: Icons.location_on_rounded,
                  onTap: _showCityPicker,
                ),
                const SizedBox(width: 8),
                // Sort Chip
                _buildFilterChip(
                  label: 'Sort: $_sortBy',
                  icon: Icons.sort_rounded,
                  onTap: _showSortPicker,
                ),
              ],
            ).animate().fade().slideY(begin: -0.2),
          ),

          // Results
          Expanded(
            child: serviceProvider.isLoading
                ? const Center(child: LoadingWidget(message: 'Searching...'))
                : serviceProvider.services.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No services found',
                        message: 'Try adjusting your search or filters to find what you are looking for.',
                        buttonLabel: 'Clear All Filters',
                        onButtonPressed: () {
                          setState(() {
                            _searchController.clear();
                            _selectedCategory = 'All';
                            _selectedCity = 'All Cities';
                            _sortBy = 'Popular';
                          });
                          _performSearch();
                        },
                      ).animate().fade().scale()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: serviceProvider.services.length,
                        itemBuilder: (context, index) {
                          final service = serviceProvider.services[index];
                          return ServiceCard(
                            service: service,
                            onTap: () => context.push('/service/${service['id'] ?? service['_id']}'),
                          ).animate().fade().slideY(begin: 0.1, delay: (index * 50).ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  void _showCategoryPicker() {
    final categories = context.read<ServiceProvider>().categories;
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: 'Select Category',
        items: categories,
        selectedItem: _selectedCategory,
        onSelected: (item) {
          setState(() => _selectedCategory = item);
          _performSearch();
        },
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: 'Select City',
        items: _cities,
        selectedItem: _selectedCity,
        onSelected: (item) {
          setState(() => _selectedCity = item);
          // In a real app, this would filter by city in API
          _performSearch();
        },
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: 'Sort By',
        items: const ['Popular', 'Newest', 'Price: Low to High', 'Price: High to Low', 'Top Rated'],
        selectedItem: _sortBy,
        onSelected: (item) {
          setState(() => _sortBy = item);
          _performSearch();
        },
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selectedItem;
  final Function(String) onSelected;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == selectedItem;
                return ListTile(
                  title: Text(
                    item,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(context);
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
