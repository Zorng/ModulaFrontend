import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_card.dart';

class DiscountFormLifecycleSection extends StatelessWidget {
  const DiscountFormLifecycleSection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DiscountFormCard(title: 'Lifecycle', child: Text(message));
  }
}
