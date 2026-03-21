part of '../inventory_journal_page.dart';

class _JournalMobileList extends StatelessWidget {
  const _JournalMobileList({
    required this.groups,
    required this.baseUnitLookup,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<_JournalDateGroup> groups;
  final Map<String, String> baseUnitLookup;
  final bool hasNextPage;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!hasNextPage || isLoadingMore) return false;
        if (notification.metrics.extentAfter > 240) return false;
        onLoadMore();
        return false;
      },
      child: ListView.separated(
        itemCount: groups.length + ((hasNextPage || isLoadingMore) ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index >= groups.length) {
            return _JournalMobileLazyLoadingFooter(
              isLoadingMore: isLoadingMore,
            );
          }

          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d').format(group.date),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < group.entries.length; i++) ...[
                _JournalMobileCard(
                  entry: group.entries[i],
                  baseUnitLookup: baseUnitLookup,
                ),
                if (i < group.entries.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _JournalMobileLazyLoadingFooter extends StatelessWidget {
  const _JournalMobileLazyLoadingFooter({required this.isLoadingMore});

  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: isLoadingMore
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _JournalMobileCard extends StatelessWidget {
  const _JournalMobileCard({required this.entry, required this.baseUnitLookup});

  final InventoryJournalEntry entry;
  final Map<String, String> baseUnitLookup;

  @override
  Widget build(BuildContext context) {
    final quantityStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: _deltaColor(entry.delta),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.itemName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _MovementTypeBadge(entry: entry),
                ),
              ),
              Text(
                _formatDeltaWithUnit(entry, baseUnitLookup),
                style: quantityStyle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.branchName} • ${DateFormat('HH:mm').format(_journalCambodiaDateTime(entry.occurredAt))}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
