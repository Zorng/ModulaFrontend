import 'package:flutter/material.dart';

/// A standardized "Add New" button for consistent use across the app.
///
/// This is a specific implementation of [AppPrimaryButton] with a fixed
/// icon and label. It is not full-width by default.
class AppAddNewButton extends StatelessWidget {
  const AppAddNewButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        // Use a less rounded shape than the default stadium border.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),
      child: const Text('+ Add new'),
    );
  }
}
