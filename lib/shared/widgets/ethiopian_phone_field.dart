import 'package:flutter/material.dart';

class EthiopianPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const EthiopianPhoneField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🇪🇹',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 4),
              Text(
                '+251',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        hintText: '912345678',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        if (!RegExp(r'^[79]\d{8}$').hasMatch(value)) {
          return 'Enter a valid 9-digit number starting with 7 or 9';
        }
        return null;
      },
    );
  }
}
