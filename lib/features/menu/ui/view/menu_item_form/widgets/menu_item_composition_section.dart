import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class MenuItemCompositionDraft {
  MenuItemCompositionDraft({
    String? stockItemId,
    String? quantity,
    this.trackingMode = 'TRACKED',
  }) : id = UniqueKey().toString(),
       quantityController = TextEditingController(text: quantity ?? ''),
       selectedStockItemId = stockItemId;

  final String id;
  String? selectedStockItemId;
  final TextEditingController quantityController;
  String trackingMode;

  void dispose() {
    quantityController.dispose();
  }
}

class MenuItemCompositionSection extends StatelessWidget {
  const MenuItemCompositionSection({
    super.key,
    required this.rows,
    required this.stockItems,
    required this.isEditing,
    this.isLoading = false,
    this.errorText,
    this.emptyText = 'No base components configured.',
    this.helperText,
    this.onAddRow,
    this.onRemoveRow,
    this.onStockItemChanged,
    this.onTrackingModeChanged,
  });

  final List<MenuItemCompositionDraft> rows;
  final List<StockItem> stockItems;
  final bool isEditing;
  final bool isLoading;
  final String? errorText;
  final String emptyText;
  final String? helperText;
  final VoidCallback? onAddRow;
  final ValueChanged<String>? onRemoveRow;
  final void Function(String rowId, String? stockItemId)? onStockItemChanged;
  final void Function(String rowId, String trackingMode)? onTrackingModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Composition',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if ((helperText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(helperText!, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (isLoading && rows.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (errorText != null && errorText!.trim().isNotEmpty) ...[
                Text(
                  errorText!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (stockItems.isEmpty && isEditing && rows.isEmpty)
                Text(
                  'No stock items available. Add stock items in Inventory before configuring composition.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                )
              else if (rows.isEmpty)
                Text(
                  emptyText,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                )
              else
                ...rows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: isEditing
                        ? _EditableCompositionRow(
                            row: row,
                            stockItems: stockItems,
                            onRemove: onRemoveRow == null
                                ? null
                                : () => onRemoveRow!(row.id),
                            onStockItemChanged: (value) =>
                                onStockItemChanged?.call(row.id, value),
                            onTrackingModeChanged: (value) =>
                                onTrackingModeChanged?.call(row.id, value),
                          )
                        : _ReadOnlyCompositionRow(
                            row: row,
                            stockItemLabel: _stockItemLabel(
                              stockItems,
                              row.selectedStockItemId,
                            ),
                          ),
                  ),
                ),
              if (isEditing) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: stockItems.isEmpty ? null : onAddRow,
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
                          'Add component',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EditableCompositionRow extends StatelessWidget {
  const _EditableCompositionRow({
    required this.row,
    required this.stockItems,
    required this.onStockItemChanged,
    required this.onTrackingModeChanged,
    this.onRemove,
  });

  final MenuItemCompositionDraft row;
  final List<StockItem> stockItems;
  final ValueChanged<String?> onStockItemChanged;
  final ValueChanged<String> onTrackingModeChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final stockItemEntries = stockItems
        .map(
          (item) => DropdownMenuEntry<String>(
            value: item.id,
            label: _stockItemLabel(stockItems, item.id),
          ),
        )
        .toList(growable: false);
    final selectedStockItemId =
        stockItems.any((item) => item.id == row.selectedStockItemId)
        ? row.selectedStockItemId
        : null;
    final selectedTrackingMode = row.trackingMode == 'UNTRACKED'
        ? 'UNTRACKED'
        : 'TRACKED';

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackFields = constraints.maxWidth < 720;
        final stockField = _CompositionDropdown<String>(
          initialSelection: selectedStockItemId,
          entries: stockItemEntries,
          onChanged: onStockItemChanged,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          hintText: 'Stock item',
        );
        final quantityField = TextFormField(
          controller: row.quantityController,
          decoration: const InputDecoration(
            hintText: 'Quantity',
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'Enter quantity';
            final parsed = double.tryParse(text);
            if (parsed == null || parsed <= 0) {
              return 'Quantity must be more than 0';
            }
            return null;
          },
        );
        final trackingField = _CompositionDropdown<String>(
          initialSelection: selectedTrackingMode,
          entries: const [
            DropdownMenuEntry(value: 'TRACKED', label: 'Tracked'),
            DropdownMenuEntry(value: 'UNTRACKED', label: 'Untracked'),
          ],
          hintText: 'Tracking mode',
          onChanged: (value) {
            if (value != null) onTrackingModeChanged(value);
          },
        );

        if (stackFields) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: stockField),
                    if (onRemove != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          tooltip: 'Remove component',
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: quantityField),
                    const SizedBox(width: 8),
                    Expanded(child: trackingField),
                  ],
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: stockField),
            const SizedBox(width: 12),
            Expanded(child: quantityField),
            const SizedBox(width: 12),
            Expanded(child: trackingField),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton(
                  tooltip: 'Remove component',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CompositionDropdown<T> extends StatelessWidget {
  const _CompositionDropdown({
    required this.initialSelection,
    required this.entries,
    required this.onChanged,
    this.hintText,
    this.enableFilter = false,
    this.enableSearch = false,
    this.requestFocusOnTap = false,
  });

  final T? initialSelection;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final bool enableFilter;
  final bool enableSearch;
  final bool requestFocusOnTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return DropdownMenuTheme(
          data: DropdownMenuThemeData(
            menuStyle: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              fixedSize: WidgetStatePropertyAll(Size(width, double.nan)),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          child: DropdownMenu<T>(
            width: width,
            initialSelection: initialSelection,
            hintText: hintText,
            dropdownMenuEntries: entries,
            onSelected: onChanged,
            requestFocusOnTap: requestFocusOnTap,
            enableFilter: enableFilter,
            enableSearch: enableSearch,
          ),
        );
      },
    );
  }
}

class _ReadOnlyCompositionRow extends StatelessWidget {
  const _ReadOnlyCompositionRow({
    required this.row,
    required this.stockItemLabel,
  });

  final MenuItemCompositionDraft row;
  final String stockItemLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trackingColor = row.trackingMode == 'TRACKED'
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade700;
    final quantity = double.tryParse(row.quantityController.text.trim());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stockItemLabel,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${_formatQuantity(quantity)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Chip(
            label: Text(row.trackingMode),
            side: BorderSide(color: trackingColor.withValues(alpha: 0.2)),
            backgroundColor: trackingColor.withValues(alpha: 0.08),
            labelStyle: textTheme.labelMedium?.copyWith(
              color: trackingColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _stockItemLabel(List<StockItem> stockItems, String? stockItemId) {
  StockItem? match;
  for (final item in stockItems) {
    if (item.id == stockItemId) {
      match = item;
      break;
    }
  }
  if (match == null) {
    return (stockItemId ?? '').trim().isEmpty
        ? 'Unknown stock item'
        : stockItemId!;
  }
  final unit = match.baseUnit.trim();
  if (unit.isEmpty) return match.name;
  return '${match.name} ($unit)';
}

String _formatQuantity(double? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
