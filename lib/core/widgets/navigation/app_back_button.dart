import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Standard back button used across the app.
///
/// Folder: `lib/core/widgets/navigation/`
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.icon, this.tooltip});

  final VoidCallback? onPressed;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon ?? Icons.chevron_left),
      tooltip: tooltip ?? 'Back',
      onPressed:
          onPressed ??
          () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            Navigator.of(context).maybePop();
          },
    );
  }
}
