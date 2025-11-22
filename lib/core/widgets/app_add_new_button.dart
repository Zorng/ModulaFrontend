import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/core/theme/responsive.dart';

/// A standardized "Add New" button for consistent use across the app.
///
/// This is a specific implementation of [AppPrimaryButton] with a fixed
/// icon and label. It is not full-width by default.
class AppAddNewButton extends StatelessWidget {
  const AppAddNewButton({
    super.key,
    required this.onPressed,
    this.label = '+ Add new',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scheme = Theme.of(context).colorScheme;

    // Use slightly larger text on roomier layouts.
    final textStyle = (AppBreakpoints.isSmall(width)
            ? Theme.of(context).textTheme.labelMedium
            : Theme.of(context).textTheme.labelLarge)
        ?.copyWith(color: scheme.onPrimary);

    return FilledButton(
      onPressed: onPressed,
      style: AppButtons.primary(
        context,
        compact: true,
        textStyle: textStyle,
      ),
      child: Text(label, style: textStyle),
    );
  }
}
