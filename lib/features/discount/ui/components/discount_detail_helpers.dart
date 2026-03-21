import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';

String discountDetailStatusLabel(String status) {
  switch (status) {
    case DiscountStatuses.active:
      return 'Active';
    case DiscountStatuses.archived:
      return 'Archived';
    default:
      return 'Inactive';
  }
}

String discountDetailScopeLabel(String scope) {
  return scope == DiscountScopes.branchWide ? 'Branch-wide' : 'Item-level';
}

String discountDetailStackingLabel(String stackingPolicy) {
  if (stackingPolicy == 'MULTIPLICATIVE') {
    return 'Multiplicative';
  }
  return stackingPolicy;
}

Color discountDetailStatusColor(String status) {
  switch (status) {
    case DiscountStatuses.active:
      return Colors.green;
    case DiscountStatuses.archived:
      return Colors.grey;
    default:
      return Colors.orange;
  }
}

String discountDetailPercentageLabel(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String discountDetailDateTimeLabel(DateTime? value, {String fallback = '-'}) {
  if (value == null) return fallback;
  return '${value.year}-${_two(value.month)}-${_two(value.day)} '
      '${_two(value.hour)}:${_two(value.minute)}';
}

String discountDetailItemLabel(String itemId) {
  final trimmed = itemId.trim();
  if (trimmed.isEmpty) return 'Unknown item';
  return trimmed.replaceAll('-', ' ');
}

String discountDetailUpdatedStatusMessage(String status) {
  return 'Discount marked as ${discountDetailStatusLabel(status).toLowerCase()}.';
}

String discountDetailScopeDescription(DiscountRule rule) {
  return rule.scope == DiscountScopes.branchWide
      ? 'Applies across its assigned branch.'
      : 'Applies only to selected items in its assigned branch.';
}

String _two(int value) => value.toString().padLeft(2, '0');
