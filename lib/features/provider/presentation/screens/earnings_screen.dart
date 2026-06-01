import 'package:flutter/material.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'package:local_service_app/shared/widgets/etb_price_tag.dart';
import 'package:local_service_app/shared/widgets/loading_widget.dart';
import 'package:local_service_app/shared/widgets/error_display.dart';
import 'package:local_service_app/shared/widgets/empty_state.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<dynamic> _completedBookings = [];
  int _selectedMonthIndex = 0;
  late List<DateTime> _months;

  @override
  void initState() {
    super.initState();
    _initMonths();
    _loadData();
  }

  void _initMonths() {
    final now = DateTime.now();
    _months = List.generate(6, (i) {
      return DateTime(now.year, now.month - i, 1);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get(ApiConstants.providerBookings);
      final bookings = data is List ? List<dynamic>.from(data) : List<dynamic>.from(data['bookings'] ?? []);
      _completedBookings = bookings.where((b) {
        final status = (b['status'] as String? ?? '').toLowerCase();
        return status == 'completed';
      }).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load earnings data';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _selectedMonthBookings {
    final selected = _months[_selectedMonthIndex];
    final nextMonth = DateTime(selected.year, selected.month + 1, 1);
    return _completedBookings.where((b) {
      final dateStr = b['date'] as String? ?? b['created_at'] as String? ?? '';
      try {
        final date = DateTime.parse(dateStr);
        return date.isAfter(selected.subtract(const Duration(days: 1))) && date.isBefore(nextMonth);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<dynamic> get _last30Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _completedBookings.where((b) {
      final dateStr = b['date'] as String? ?? b['created_at'] as String? ?? '';
      try {
        final date = DateTime.parse(dateStr);
        return date.isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double _totalEarnings(List<dynamic> bookings) {
    double total = 0;
    for (final b in bookings) {
      total += (b['amount'] as num? ?? b['price'] as num? ?? 0).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: _loading
          ? const LoadingWidget(message: 'Loading earnings...')
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMonthPicker(),
                      const SizedBox(height: 16),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildLast30DaysSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMonthPicker() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = _months[index];
          final label = '${_monthName(month.month)} ${month.year}';
          final selected = _selectedMonthIndex == index;
          return ChoiceChip(
            label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
            selected: selected,
            selectedColor: const Color(0xFF007BFF),
            onSelected: (_) => setState(() => _selectedMonthIndex = index),
          );
        },
      ),
    );
  }

  String _monthName(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }

  Widget _buildSummaryCards() {
    final monthly = _selectedMonthBookings;
    final gross = _totalEarnings(monthly);
    final count = monthly.length;
    final avg = count > 0 ? gross / count : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(
              title: 'Gross Earnings',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF28A745),
              child: ETBPriceTag(price: gross, fontSize: 20),
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(
              title: 'Completed Jobs',
              icon: Icons.check_circle,
              color: const Color(0xFF007BFF),
              child: Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SummaryCard(
              title: 'Avg Per Job',
              icon: Icons.show_chart,
              color: const Color(0xFFF47E20),
              child: ETBPriceTag(price: avg, fontSize: 20),
            )),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildLast30DaysSection() {
    final recent = _last30Days;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 30 Days', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          const EmptyStateWidget(
            icon: Icons.receipt_long,
            title: 'No Recent Earnings',
            message: 'No completed bookings in the last 30 days.',
          )
        else
          ...recent.map((b) => _buildBookingRow(b)),
      ],
    );
  }

  Widget _buildBookingRow(dynamic booking) {
    final serviceName = booking['service_title'] as String? ?? booking['serviceName'] as String? ?? 'Service';
    final dateStr = booking['date'] as String? ?? booking['created_at'] as String? ?? '';
    final date = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    final amount = (booking['amount'] as num? ?? booking['price'] as num? ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF28A745).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt, color: Color(0xFF28A745), size: 22),
        ),
        title: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: ETBPriceTag(price: amount, fontSize: 15),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
