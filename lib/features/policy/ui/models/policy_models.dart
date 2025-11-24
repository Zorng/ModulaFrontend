import 'package:flutter/material.dart';

enum PolicyItemType { toggle, selector, info }

class PolicyItem {
  const PolicyItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.type,
    this.subtitle,
    this.options,
    this.defaultValue,
  });

  final String id;
  final String title;
  final IconData icon;
  final String? subtitle;
  final PolicyItemType type;
  final List<String>? options;
  final String? defaultValue;
}

class PolicySectionData {
  const PolicySectionData({
    required this.title,
    required this.items,
  });

  final String title;
  final List<PolicyItem> items;
}
