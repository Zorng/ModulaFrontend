import 'package:flutter/material.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';

class SyncFreshnessBanner extends StatelessWidget {
  const SyncFreshnessBanner({super.key, required this.freshness, this.margin});

  final SyncWorkspaceFreshness freshness;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = _paletteFor(colorScheme, freshness.kind);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderColor),
      ),
      child: Row(
        children: [
          Icon(palette.icon, size: 18, color: palette.foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              freshness.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.foregroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SyncFreshnessPalette _paletteFor(
    ColorScheme colorScheme,
    SyncWorkspaceFreshnessKind kind,
  ) {
    return switch (kind) {
      SyncWorkspaceFreshnessKind.syncing => _SyncFreshnessPalette(
        icon: Icons.sync_outlined,
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      SyncWorkspaceFreshnessKind.staleUsable => _SyncFreshnessPalette(
        icon: Icons.cloud_off_outlined,
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      SyncWorkspaceFreshnessKind.refreshFailed => _SyncFreshnessPalette(
        icon: Icons.refresh_outlined,
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
    };
  }
}

class _SyncFreshnessPalette {
  const _SyncFreshnessPalette({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
}
