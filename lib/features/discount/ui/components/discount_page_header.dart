import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';

class DiscountPageHeader extends StatelessWidget {
  const DiscountPageHeader({
    super.key,
    required this.subtitle,
    required this.onBackPressed,
    this.onAddPressed,
    this.compact = false,
  });

  final String subtitle;
  final Future<void> Function()? onAddPressed;
  final VoidCallback onBackPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBackButton(
          onPressed: onBackPressed,
          icon: Icons.arrow_back,
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discounts',
                      style: compact
                          ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                          : Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
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
              if (onAddPressed != null)
                _DiscountAddButton(onPressed: onAddPressed!, compact: compact),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscountAddButton extends StatelessWidget {
  const _DiscountAddButton({required this.onPressed, required this.compact});

  final Future<void> Function() onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: () => onPressed(),
      icon: const Icon(Icons.add, size: 18),
      label: Text(compact ? 'Add discount' : 'Create discount'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 22,
          vertical: 0,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
