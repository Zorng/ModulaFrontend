part of '../inventory_journal_page.dart';

class _JournalDesktopTable extends StatelessWidget {
  const _JournalDesktopTable({
    required this.groups,
    required this.baseUnitLookup,
    required this.hideItemColumn,
    required this.hideBranchColumn,
    required this.rangeLabel,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.isPageLoading,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final List<_JournalDateGroup> groups;
  final Map<String, String> baseUnitLookup;
  final bool hideItemColumn;
  final bool hideBranchColumn;
  final String rangeLabel;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool isPageLoading;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTableTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTableTheme.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: ColoredBox(
                  color: AppTableTheme.background,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _DesktopTableHeader(
                          hideItemColumn: hideItemColumn,
                          hideBranchColumn: hideBranchColumn,
                        ),
                        for (final group in groups) ...[
                          _DateDividerRow(date: group.date),
                          for (final entry in group.entries)
                            _DesktopEntryRow(
                              entry: entry,
                              baseUnitLookup: baseUnitLookup,
                              hideItemColumn: hideItemColumn,
                              hideBranchColumn: hideBranchColumn,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPaginationBar(
          rangeLabel: rangeLabel,
          canGoPrevious: hasPreviousPage,
          canGoNext: hasNextPage,
          isLoading: isPageLoading,
          onPrevious: onPreviousPage,
          onNext: onNextPage,
        ),
      ],
    );
  }
}

class _DesktopTableHeader extends StatelessWidget {
  const _DesktopTableHeader({
    required this.hideItemColumn,
    required this.hideBranchColumn,
  });

  final bool hideItemColumn;
  final bool hideBranchColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTableTheme.headerBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text('Time', style: AppTableTheme.headerText),
          ),
          if (!hideItemColumn)
            const Expanded(
              flex: 3,
              child: Text('Item', style: AppTableTheme.headerText),
            ),
          if (!hideBranchColumn)
            const Expanded(
              flex: 3,
              child: Text('Branch', style: AppTableTheme.headerText),
            ),
          const Expanded(
            flex: 3,
            child: Text('Movement', style: AppTableTheme.headerText),
          ),
          const Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Quantity', style: AppTableTheme.headerText),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDividerRow extends StatelessWidget {
  const _DateDividerRow({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTableTheme.divider)),
      ),
      child: Text(
        DateFormat('MMM d, y').format(date),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DesktopEntryRow extends StatelessWidget {
  const _DesktopEntryRow({
    required this.entry,
    required this.baseUnitLookup,
    required this.hideItemColumn,
    required this.hideBranchColumn,
  });

  final InventoryJournalEntry entry;
  final Map<String, String> baseUnitLookup;
  final bool hideItemColumn;
  final bool hideBranchColumn;

  @override
  Widget build(BuildContext context) {
    final quantityStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: _deltaColor(entry.delta),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTableTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              DateFormat(
                'HH:mm',
              ).format(_journalCambodiaDateTime(entry.occurredAt)),
              style: AppTableTheme.cellText,
            ),
          ),
          if (!hideItemColumn)
            Expanded(
              flex: 3,
              child: Text(entry.itemName, style: AppTableTheme.cellText),
            ),
          if (!hideBranchColumn)
            Expanded(
              flex: 3,
              child: Text(entry.branchName, style: AppTableTheme.cellText),
            ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _MovementTypeBadge(entry: entry),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatDeltaWithUnit(entry, baseUnitLookup),
                style: quantityStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTypeBadge extends StatelessWidget {
  const _MovementTypeBadge({required this.entry});

  final InventoryJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, borderColor, textColor) = switch (entry.reason) {
      InventoryJournalReason.restock => (
        const Color(0xFFECFDF5),
        const Color(0xFF10B981),
        const Color(0xFF047857),
      ),
      InventoryJournalReason.add || InventoryJournalReason.remove => (
        const Color(0xFFFFF7ED),
        const Color(0xFFF59E0B),
        const Color(0xFFB45309),
      ),
      InventoryJournalReason.sale ||
      InventoryJournalReason.voided ||
      InventoryJournalReason.reopen ||
      InventoryJournalReason.unknown => (
        const Color(0xFFFEF2F2),
        const Color(0xFFEF4444),
        const Color(0xFFB91C1C),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        _movementTypeLabel(entry),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
