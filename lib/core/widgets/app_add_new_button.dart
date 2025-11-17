import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_primary_button.dart';

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
      child: Text('+ Add new'),
    );
  }
}
