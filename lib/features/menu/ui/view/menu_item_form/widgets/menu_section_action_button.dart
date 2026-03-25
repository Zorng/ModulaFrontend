import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';

class MenuSectionActionButton extends StatelessWidget {
  const MenuSectionActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showAddIcon = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool showAddIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: scheme.onPrimary);

    return FilledButton(
      onPressed: onPressed,
      style: AppButtons.primary(
        context,
        compact: true,
        textStyle: textStyle,
      ).copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showAddIcon) ...[
              Icon(Icons.add, size: 16, color: scheme.onPrimary),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
