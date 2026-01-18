import 'package:flutter/material.dart';

/// Standard back button used across the app.
///
/// Folder: `lib/core/widgets/navigation/`
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chevron_left),
      tooltip: 'Back',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
