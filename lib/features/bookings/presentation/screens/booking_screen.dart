import 'package:flutter/material.dart';
import 'package:local_service_app/api_service.dart';

class BookingScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String providerName;

  const BookingScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedSlot = 'Morning';
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _selectedDate ?? DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a booking date first')));
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.createBooking(
        serviceId: widget.serviceId,
        date: _selectedDate!.toIso8601String().split('T')[0],
        timeSlot: _selectedSlot,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking submitted successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.serviceName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Provider: ${widget.providerName}', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Select Date', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: colors.outline.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: colors.primary),
                  const SizedBox(width: 16),
                  Text(_selectedDate == null ? 'Pick a date' : _selectedDate!.toLocal().toString().split(' ').first, style: theme.textTheme.bodyLarge),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Choose Time Slot', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: ['Morning', 'Afternoon', 'Evening'].map((slot) {
              final selected = _selectedSlot == slot;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(slot),
                    selected: selected,
                    onSelected: (val) => setState(() => _selectedSlot = slot),
                    selectedColor: colors.primary,
                    labelStyle: TextStyle(color: selected ? colors.onPrimary : colors.onSurface),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Additional Notes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any specific requirements or instructions...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colors.surface,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('CONFIRM BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}
