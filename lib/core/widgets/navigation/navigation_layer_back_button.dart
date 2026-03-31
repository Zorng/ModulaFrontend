import 'package:flutter/material.dart';

class NavigationLayerBackButton extends StatelessWidget {
  const NavigationLayerBackButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.framed = true,
  });

  final VoidCallback onPressed;
  final String? tooltip;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(14);

    if (!framed) {
      return Tooltip(
        message: tooltip ?? 'Back',
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(Icons.arrow_back, size: 20, color: colorScheme.onSurface),
        ),
      );
    }

    return Tooltip(
      message: tooltip ?? 'Back',
      child: Material(
        color: colorScheme.surface,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: borderRadius,
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
