part of '../inventory_journal_page.dart';

class _JournalPageHeader extends StatelessWidget {
  const _JournalPageHeader({
    required this.filterStatusItems,
    required this.hasFiltersApplied,
    required this.onFilterPressed,
  });

  final List<_FilterStatusItem> filterStatusItems;
  final bool hasFiltersApplied;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTableTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Current filter',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterActionButton(
                hasFiltersApplied: hasFiltersApplied,
                onPressed: onFilterPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in filterStatusItems) _FilterInfoCard(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterInfoCard extends StatelessWidget {
  const _FilterInfoCard({required this.item});

  final _FilterStatusItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = item.isEmphasized
        ? colorScheme.primary.withValues(alpha: 0.08)
        : AppTableTheme.headerBackground;
    final borderColor = item.isEmphasized
        ? colorScheme.primary.withValues(alpha: 0.35)
        : AppTableTheme.divider;
    final labelColor = item.isEmphasized
        ? colorScheme.primary
        : const Color(0xFF6B7280);
    final valueColor = item.isEmphasized
        ? const Color(0xFF1F2937)
        : const Color(0xFF2B2B2B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${item.label}: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            TextSpan(
              text: item.value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: item.isEmphasized
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.hasFiltersApplied,
    required this.onPressed,
  });

  final bool hasFiltersApplied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onPressed,
          child: const Text('Filter'),
        ),
        if (hasFiltersApplied)
          const Positioned(top: 4, right: 4, child: _FilterAppliedDot()),
      ],
    );
  }
}

class _FilterStatusItem {
  const _FilterStatusItem({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;
}

class _FilterAppliedDot extends StatelessWidget {
  const _FilterAppliedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFFD14343),
        shape: BoxShape.circle,
      ),
    );
  }
}
