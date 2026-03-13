import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';

/// A standardized "Add New" button for consistent use across the app.
///
/// This is a specific implementation of [AppPrimaryButton] with a fixed
/// icon and label. It is not full-width by default.
///
/// Folder: `lib/core/widgets/buttons/`
class AppAddNewButton extends StatelessWidget {
  const AppAddNewButton({
    super.key,
    required this.onPressed,
    this.label = 'Add new',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = 16.0;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: scheme.onPrimary);

    return FilledButton(
      onPressed: onPressed,
      style: AppButtons.primary(
        context,
        compact: true,
        textStyle: textStyle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.add,
            size: iconSize,
            color: scheme.onPrimary,
          ),
          Text(label)
        ],
      ),
    );
  }
}
