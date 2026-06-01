import 'package:flutter/material.dart';
import 'package:local_service_app/core/constants/api_constants.dart';
import 'package:local_service_app/core/network/api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _api = ApiClient();

  String _category = 'Plumbing';
  String _city = 'Addis Ababa';

  static const List<String> _categories = [
    'Plumbing', 'Electrician', 'Cleaning', 'Gardening',
    'Painting', 'Carpentry', 'AC Repair', 'Car Mechanic',
  ];

  static const List<String> _cities = [
    'Addis Ababa', 'Adama', 'Bahir Dar', 'Dire Dawa',
    'Hawassa', 'Jijiga', 'Mekelle', 'Jimma',
  ];

  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  final List<bool> _isOpen = List.filled(7, true);
  final List<TimeOfDay> _openTimes = List.filled(7, const TimeOfDay(hour: 8, minute: 0));
  final List<TimeOfDay> _closeTimes = List.filled(7, const TimeOfDay(hour: 17, minute: 0));
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index, bool isOpenTime) async {
    final initial = isOpenTime ? _openTimes[index] : _closeTimes[index];
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTimes[index] = picked;
        } else {
          _closeTimes[index] = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final businessHours = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      businessHours.add({
        'day': _days[i],
        'is_open': _isOpen[i],
        'open_time': '${_openTimes[i].hour.toString().padLeft(2, '0')}:${_openTimes[i].minute.toString().padLeft(2, '0')}',
        'close_time': '${_closeTimes[i].hour.toString().padLeft(2, '0')}:${_closeTimes[i].minute.toString().padLeft(2, '0')}',
      });
    }

    try {
      final body = {
        'title': _titleController.text.trim(),
        'category': _category,
        'city': _city,
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'business_hours': businessHours,
      };
      await _api.post(ApiConstants.services, body: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service published successfully'), backgroundColor: Color(0xFF28A745)),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFDC3545)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish service: $e'), backgroundColor: const Color(0xFFDC3545)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Service')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Service Title', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().length < 3) return 'Title must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _city,
              decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v ?? _city),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description', border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 2000,
              validator: (v) {
                if (v == null || v.trim().length < 50) return 'Description must be at least 50 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (ETB)', border: OutlineInputBorder(),
                prefixText: 'ETB ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Business Hours', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(7, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(_days[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      IconButton(
                        icon: Icon(
                          _isOpen[index] ? Icons.check_circle : Icons.cancel,
                          color: _isOpen[index] ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                        ),
                        onPressed: () => setState(() => _isOpen[index] = !_isOpen[index]),
                      ),
                      if (_isOpen[index]) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(index, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _openTimes[index].format(context),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('to', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(index, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _closeTimes[index].format(context),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publish Service', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
