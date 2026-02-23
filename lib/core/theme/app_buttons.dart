import 'package:flutter/material.dart';

/// Centralized button styles for consistent usage across the app.
///
/// - Primary buttons (login, add) use the app primary color with onPrimary text.
/// - Secondary buttons use a neutral surface with onSurface text.
/// - Compact variants tighten padding/density for inline use (e.g., search bars).
class AppButtons {
  const AppButtons._();

  static const Color disabledFillColor = Color(0xFFF6B8AD);

  static ButtonStyle primary(
    BuildContext context, {
    bool compact = false,
    TextStyle? textStyle,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      disabledBackgroundColor: disabledFillColor,
      disabledForegroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: (textStyle ?? theme.textTheme.labelLarge)?.copyWith(
        color: scheme.onPrimary,
      ),
    );

    if (!compact) return base;

    return base.copyWith(
      visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
    );
  }

  static ButtonStyle secondary(
    BuildContext context, {
    bool compact = false,
    TextStyle? textStyle,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = FilledButton.styleFrom(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      disabledBackgroundColor: disabledFillColor,
      disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.7),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: (textStyle ?? theme.textTheme.labelLarge)?.copyWith(
        color: scheme.onSurface,
      ),
    );

    if (!compact) return base;

    return base.copyWith(
      visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
    );
  }
}
