import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';

class DiscountDetailHeader extends StatelessWidget {
  const DiscountDetailHeader({super.key, required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          AppBackButton(
            onPressed: onBackPressed,
            icon: Icons.arrow_back,
            tooltip: 'Back',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Discount details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}
