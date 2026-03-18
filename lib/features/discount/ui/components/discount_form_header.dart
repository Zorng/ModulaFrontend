import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';

class DiscountFormHeader extends StatelessWidget {
  const DiscountFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSaving,
    required this.onBack,
    this.onSave,
  });

  final String title;
  final String subtitle;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          onPressed: onBack,
          icon: Icons.arrow_back,
          tooltip: 'Back',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onSave != null)
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
      ],
    );
  }
}
