import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';

class SelectionChipsField extends StatelessWidget {
  const SelectionChipsField({
    super.key,
    required this.selectedIds,
    required this.labelResolver,
    required this.addButtonLabel,
    required this.onAddTap,
    required this.onRemove,
    this.editable = true,
    this.showAddButton = true,
  });

  final Iterable<String> selectedIds;
  final String Function(String id) labelResolver;
  final String addButtonLabel;
  final VoidCallback onAddTap;
  final void Function(String id) onRemove;
  final bool editable;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedIds
              .map((id) {
                final theme = Theme.of(context);
                final chipText = theme.textTheme.bodySmall?.copyWith(
                  color: AppTableTheme.filterPillValueColor,
                  fontWeight: FontWeight.w600,
                );
                return Chip(
                  backgroundColor: AppTableTheme.filterPillBackground,
                  surfaceTintColor: AppTableTheme.filterPillBackground,
                  side: const BorderSide(color: AppTableTheme.filterPillBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  label: Text(labelResolver(id), style: chipText),
                  deleteIconColor: AppTableTheme.filterPillIconColor,
                  onDeleted: editable ? () => onRemove(id) : null,
                );
              })
              .toList(),
        ),
        if (editable && showAddButton) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: onAddTap,
              child: CustomPaint(
                foregroundPainter: DashedBorderPainter(
                  color: Theme.of(context).primaryColor,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    addButtonLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

