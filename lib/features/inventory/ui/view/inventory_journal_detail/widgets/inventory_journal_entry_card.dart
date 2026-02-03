import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class InventoryJournalEntryCard extends ConsumerWidget {
  const InventoryJournalEntryCard({super.key, required this.entry});

  final InventoryJournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final deltaColor = entry.delta >= 0 ? scheme.primary : scheme.error;
    final currentUser = ref.watch(loginControllerProvider).user;
    final actorName = _resolvedActor(entry.actor, currentUser?.name);

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.itemName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(entry.occurredAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(_resolvedReason(entry)),
                  backgroundColor: scheme.secondaryContainer,
                  labelStyle: TextStyle(color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.delta > 0 ? '+' : ''}${entry.delta}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: deltaColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.note.isEmpty ? 'No note added' : entry.note),
            const SizedBox(height: 4),
            Text(
              'By $actorName',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              'Created at ${_formatTimestamp(entry.createdAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _resolvedReason(InventoryJournalEntry entry) {
    final label = entry.reason.label;
    if (label == 'Other') {
      return entry.delta >= 0 ? 'Add' : 'Remove';
    }
    return label;
  }

  String _resolvedActor(String actor, String? currentName) {
    final a = actor.trim();
    if (a.isEmpty) return currentName ?? 'Unknown';
    // Looks like an id if no spaces and contains hyphen or long length
    if (!a.contains(' ') && (a.contains('-') || a.length > 12)) {
      return currentName ?? a;
    }
    return a;
  }
}
