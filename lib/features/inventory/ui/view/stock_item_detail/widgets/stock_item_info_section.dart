import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class StockItemInfoSection extends StatelessWidget {
  const StockItemInfoSection({
    super.key,
    required this.isEditing,
    required this.nameController,
    required this.categoryController,
    required this.categoryOptions,
    required this.selectedTypes,
    required this.typeOptions,
    required this.pieceSizeController,
    required this.barcodeController,
    required this.isActive,
    required this.pieceDescription,
    required this.usageTags,
    required this.categoryLabel,
    required this.barcodeLabel,
    required this.onCategoryChanged,
    required this.onToggleUsageTag,
    required this.onActiveChanged,
    required this.onPieceSizeChanged,
  });

  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController categoryController;
  final List<InventoryCategory> categoryOptions;
  final Set<String> selectedTypes;
  final List<String> typeOptions;
  final TextEditingController pieceSizeController;
  final TextEditingController barcodeController;
  final bool isActive;
  final String pieceDescription;
  final List<String> usageTags;
  final String categoryLabel;
  final String barcodeLabel;
  final void Function(String? categoryId, String categoryName) onCategoryChanged;
  final void Function(String tag, bool selected) onToggleUsageTag;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onPieceSizeChanged;

  @override
  Widget build(BuildContext context) {
    final chipColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return InventorySectionCard(
      title: 'Item information',
      backgroundColor: Colors.white,
      children: [
        isEditing
            ? TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              )
            : InventoryDetailField(label: 'Name', value: nameController.text),
        isEditing
            ? SizedBox(
                width: double.infinity,
                child: InventoryDropdown<String>(
                  initialValue: categoryController.text,
                  label: const Text('Category'),
                  entries: categoryOptions
                      .map(
                        (category) => DropdownMenuEntry(
                          value: category.id,
                          label: category.name,
                        ),
                      )
                      .toList(),
                  onSelected: (value) {
                    if (value == null) return;
                    final selected = categoryOptions.firstWhere(
                      (c) => c.id == value,
                      orElse: () => InventoryCategory(
                        id: value,
                        name: value,
                        isActive: true,
                      ),
                    );
                    onCategoryChanged(selected.id, selected.name);
                  },
                ),
              )
            : InventoryDetailField(label: 'Category', value: categoryLabel),
        isEditing
            ? TextFormField(
                controller: pieceSizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Piece size',
                  helperText: 'Number of base units per piece',
                ),
                onChanged: (_) => onPieceSizeChanged(),
              )
            : InventoryDetailField(label: 'Piece size', value: pieceDescription),
        isEditing
            ? TextFormField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
              )
            : InventoryDetailField(label: 'Barcode', value: barcodeLabel),
        isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: typeOptions
                    .map(
                      (type) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(type),
                        value: selectedTypes.contains(type),
                        onChanged: (value) =>
                            onToggleUsageTag(type, value ?? false),
                      ),
                    )
                    .toList(),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: usageTags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: chipColor,
                      ),
                    )
                    .toList(),
              ),
        isEditing
            ? SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Item is active'),
                value: isActive,
                onChanged: onActiveChanged,
              )
            : InventoryDetailField(
                label: 'Status',
                value: isActive ? 'Active' : 'Inactive',
              ),
      ],
    );
  }
}
