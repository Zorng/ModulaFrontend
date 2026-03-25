import 'package:flutter/material.dart';

class SalesSummaryKpiItem {
  const SalesSummaryKpiItem({
    required this.title,
    required this.value,
    required this.icon,
    this.secondaryValue,
    this.accentColor,
  });

  final String title;
  final String value;
  final String? secondaryValue;
  final IconData icon;
  final Color? accentColor;
}
