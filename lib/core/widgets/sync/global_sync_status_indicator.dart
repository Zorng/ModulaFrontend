import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';

class GlobalSyncStatusIndicator extends ConsumerWidget {
  const GlobalSyncStatusIndicator({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(globalSyncStatusProvider);
    return GlobalSyncStatusPill(status: status, compact: compact);
  }
}

class GlobalSyncStatusPill extends StatelessWidget {
  const GlobalSyncStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final GlobalSyncStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _paletteFor(theme.colorScheme, status.kind);
    final icon = _iconFor(status.kind);

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: palette.foregroundColor),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.foregroundColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    final tooltip = status.detail;
    if (tooltip == null || tooltip.trim().isEmpty) {
      return content;
    }

    return Tooltip(message: tooltip, child: content);
  }

  IconData _iconFor(GlobalSyncStatusKind kind) {
    return switch (kind) {
      GlobalSyncStatusKind.offline => Icons.cloud_off_outlined,
      GlobalSyncStatusKind.syncing => Icons.sync_outlined,
      GlobalSyncStatusKind.stale => Icons.history_outlined,
      GlobalSyncStatusKind.online => Icons.cloud_done_outlined,
    };
  }

  _GlobalSyncPalette _paletteFor(
    ColorScheme colorScheme,
    GlobalSyncStatusKind kind,
  ) {
    return switch (kind) {
      GlobalSyncStatusKind.offline => _GlobalSyncPalette(
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      GlobalSyncStatusKind.syncing => _GlobalSyncPalette(
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.primary,
      ),
      GlobalSyncStatusKind.stale => _GlobalSyncPalette(
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      GlobalSyncStatusKind.online => _GlobalSyncPalette(
        backgroundColor: colorScheme.surfaceContainerHighest,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
    };
  }
}

class _GlobalSyncPalette {
  const _GlobalSyncPalette({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
}
