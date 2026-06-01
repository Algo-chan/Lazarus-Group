import 'package:flutter/material.dart';

class ETBPriceTag extends StatelessWidget {
  final dynamic price;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  const ETBPriceTag({
    super.key,
    required this.price,
    this.fontSize,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPrice(price),
      style: TextStyle(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? const Color(0xFFF47E20),
      ),
    );
  }

  static String formatPrice(dynamic price) {
    if (price == null) return 'ETB 0';
    num amount;
    if (price is String) {
      amount = double.tryParse(price) ?? 0;
    } else if (price is int) {
      amount = price;
    } else if (price is double) {
      amount = price;
    } else {
      amount = 0;
    }
    final whole = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
      count++;
    }
    return 'ETB ${buffer.toString().split('').reversed.join()}';
  }
}
