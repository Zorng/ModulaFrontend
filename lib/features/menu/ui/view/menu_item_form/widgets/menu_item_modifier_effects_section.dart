import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/menu_item_composition_section.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/menu_section_action_button.dart';

class MenuItemModifierEffectsSection extends StatelessWidget {
  const MenuItemModifierEffectsSection({
    super.key,
    required this.modifierGroups,
    required this.priceControllersByOptionId,
    required this.effectRowsByOptionId,
    required this.stockItems,
    required this.isEditing,
    this.isLoading = false,
    this.errorText,
    this.helperText,
    this.emptyText = 'No item-scoped modifier pricing configured yet.',
    this.onAddRow,
    this.onRemoveRow,
    this.onStockItemChanged,
    this.onTrackingModeChanged,
  });

  final List<ModifierGroup> modifierGroups;
  final Map<String, TextEditingController> priceControllersByOptionId;
  final Map<String, List<MenuItemCompositionDraft>> effectRowsByOptionId;
  final List<StockItem> stockItems;
  final bool isEditing;
  final bool isLoading;
  final String? errorText;
  final String? helperText;
  final String emptyText;
  final ValueChanged<String>? onAddRow;
  final void Function(String optionId, String rowId)? onRemoveRow;
  final void Function(String optionId, String rowId, String? stockItemId)?
  onStockItemChanged;
  final void Function(String optionId, String rowId, String trackingMode)?
  onTrackingModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasOptions = modifierGroups.any((group) => group.options.isNotEmpty);

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
            Text(
              'Modifier option pricing and effects',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((helperText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(helperText!, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (isLoading && !hasOptions)
              const Center(child: CircularProgressIndicator())
            else if (errorText != null && errorText!.trim().isNotEmpty) ...[
              Text(
                errorText!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!hasOptions)
              Text(
                emptyText,
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
              )
            else
              ...modifierGroups
                  .where((group) => group.options.isNotEmpty)
                  .map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ModifierEffectGroupCard(
                        group: group,
                        priceControllersByOptionId: priceControllersByOptionId,
                        effectRowsByOptionId: effectRowsByOptionId,
                        stockItems: stockItems,
                        isEditing: isEditing,
                        onAddRow: onAddRow,
                        onRemoveRow: onRemoveRow,
                        onStockItemChanged: onStockItemChanged,
                        onTrackingModeChanged: onTrackingModeChanged,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ModifierEffectGroupCard extends StatelessWidget {
  const _ModifierEffectGroupCard({
    required this.group,
    required this.priceControllersByOptionId,
    required this.effectRowsByOptionId,
    required this.stockItems,
    required this.isEditing,
    this.onAddRow,
    this.onRemoveRow,
    this.onStockItemChanged,
    this.onTrackingModeChanged,
  });

  final ModifierGroup group;
  final Map<String, TextEditingController> priceControllersByOptionId;
  final Map<String, List<MenuItemCompositionDraft>> effectRowsByOptionId;
  final List<StockItem> stockItems;
  final bool isEditing;
  final ValueChanged<String>? onAddRow;
  final void Function(String optionId, String rowId)? onRemoveRow;
  final void Function(String optionId, String rowId, String? stockItemId)?
  onStockItemChanged;
  final void Function(String optionId, String rowId, String trackingMode)?
  onTrackingModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final configuredOptionCount = group.options.where((option) {
      final priceText =
          priceControllersByOptionId[option.id]?.text.trim() ?? '';
      final hasPrice = priceText.isNotEmpty;
      final rows = effectRowsByOptionId[option.id] ?? const [];
      return hasPrice || rows.isNotEmpty;
    }).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(group.name, style: textTheme.titleSmall),
          subtitle: Text(
            '${group.options.length} option${group.options.length == 1 ? '' : 's'}'
            ' • $configuredOptionCount configured',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          children: group.options
              .map((option) {
                final priceController = priceControllersByOptionId[option.id];
                if (priceController == null) {
                  return const SizedBox.shrink();
                }
                final rows =
                    effectRowsByOptionId[option.id] ??
                    const <MenuItemCompositionDraft>[];
                return SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ModifierEffectOptionCard(
                      optionName: option.name,
                      priceController: priceController,
                      rows: rows,
                      stockItems: stockItems,
                      isEditing: isEditing,
                      onAddRow: onAddRow == null
                          ? null
                          : () => onAddRow!(option.id),
                      onRemoveRow: onRemoveRow == null
                          ? null
                          : (rowId) => onRemoveRow!(option.id, rowId),
                      onStockItemChanged: onStockItemChanged == null
                          ? null
                          : (rowId, stockItemId) => onStockItemChanged!(
                              option.id,
                              rowId,
                              stockItemId,
                            ),
                      onTrackingModeChanged: onTrackingModeChanged == null
                          ? null
                          : (rowId, trackingMode) => onTrackingModeChanged!(
                              option.id,
                              rowId,
                              trackingMode,
                            ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ModifierEffectOptionCard extends StatelessWidget {
  const _ModifierEffectOptionCard({
    required this.optionName,
    required this.priceController,
    required this.rows,
    required this.stockItems,
    required this.isEditing,
    this.onAddRow,
    this.onRemoveRow,
    this.onStockItemChanged,
    this.onTrackingModeChanged,
  });

  final String optionName;
  final TextEditingController priceController;
  final List<MenuItemCompositionDraft> rows;
  final List<StockItem> stockItems;
  final bool isEditing;
  final VoidCallback? onAddRow;
  final ValueChanged<String>? onRemoveRow;
  final void Function(String rowId, String? stockItemId)? onStockItemChanged;
  final void Function(String rowId, String trackingMode)? onTrackingModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMobileLayout = MediaQuery.sizeOf(context).width < 640;
    final hasRows = rows.isNotEmpty;
    final priceText = priceController.text.trim();
    final parsedPrice = double.tryParse(priceText);
    final hasConfiguredPrice = parsedPrice != null && priceText.isNotEmpty;
    final configuredPriceLabel = parsedPrice == null || priceText.isEmpty
        ? 'Price not configured'
        : _formatPriceDeltaLabel(parsedPrice);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(optionName, style: textTheme.titleSmall)),
              if (!isMobileLayout && isEditing && onAddRow != null)
                MenuSectionActionButton(
                  label: 'Add component effect',
                  onPressed: onAddRow!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEditing) ...[
            _ModifierOptionPriceField(
              controller: priceController,
              requiresPrice: hasRows,
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                configuredPriceLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: hasConfiguredPrice
                      ? Colors.grey.shade800
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasRows) const SizedBox(height: 12),
          ],
          if (hasRows) ...[
            Text(
              'Component effects',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: isEditing
                      ? _EditableModifierEffectRow(
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
                      : _ReadOnlyModifierEffectRow(
                          row: row,
                          stockItemLabel: _stockItemLabel(
                            stockItems,
                            row.selectedStockItemId,
                          ),
                        ),
                ),
              ),
            ),
          ],
          if (!hasConfiguredPrice && !hasRows)
            Text(
              'No item-scoped pricing or component effects configured for this option.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          if (isMobileLayout && isEditing && onAddRow != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: MenuSectionActionButton(
                label: 'Add component effect',
                onPressed: onAddRow!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModifierOptionPriceField extends StatelessWidget {
  const _ModifierOptionPriceField({
    required this.controller,
    required this.requiresPrice,
  });

  final TextEditingController controller;
  final bool requiresPrice;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Price delta',
        hintText: '0.00',
        filled: true,
        fillColor: Colors.white,
        prefixText: '\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) {
          return requiresPrice ? 'Set price' : null;
        }
        final parsed = double.tryParse(text);
        if (parsed == null) return 'Invalid price';
        if (parsed < 0) return 'Must be >= 0';
        return null;
      },
    );
  }
}

class _EditableModifierEffectRow extends StatelessWidget {
  const _EditableModifierEffectRow({
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
    final selectedTrackingMode = row.trackingMode == 'NOT_TRACKED'
        ? 'NOT_TRACKED'
        : 'TRACKED';

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackFields = constraints.maxWidth < 720;
        final stockField = _EffectDropdown<String>(
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
            hintText: 'Delta quantity',
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'Enter delta quantity';
            final parsed = double.tryParse(text);
            if (parsed == null || parsed <= 0) {
              return 'Quantity must be more than 0';
            }
            return null;
          },
        );
        final trackingField = _EffectDropdown<String>(
          initialSelection: selectedTrackingMode,
          entries: const [
            DropdownMenuEntry(value: 'TRACKED', label: 'Tracked'),
            DropdownMenuEntry(value: 'NOT_TRACKED', label: 'Untracked'),
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
                          tooltip: 'Remove effect',
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
                  tooltip: 'Remove effect',
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

class _EffectDropdown<T> extends StatelessWidget {
  const _EffectDropdown({
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

class _ReadOnlyModifierEffectRow extends StatelessWidget {
  const _ReadOnlyModifierEffectRow({
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
        color: Colors.white,
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
                  'Delta: ${_formatDelta(quantity)}',
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
    return 'Unknown stock item';
  }
  final unit = match.baseUnit.trim();
  if (unit.isEmpty) return match.name;
  return '${match.name} ($unit)';
}

String _formatDelta(double? value) {
  if (value == null) return '-';
  final formatted = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
  return value > 0 ? '+$formatted' : formatted;
}

String _formatPriceDeltaLabel(double value) {
  if (value == 0) {
    return 'Price delta: Free';
  }
  return 'Price delta: +\$${value.toStringAsFixed(2)}';
}
