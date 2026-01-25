import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class AddStockItemDetailsSection extends StatelessWidget {
  const AddStockItemDetailsSection({
    super.key,
    required this.nameController,
    required this.barcodeController,
    required this.pieceSizeController,
    required this.baseUnitFieldKey,
    required this.categoryFieldKey,
    required this.baseUnit,
    required this.categoryLabel,
    required this.onSelectBaseUnit,
    required this.onSelectCategory,
  });

  final TextEditingController nameController;
  final TextEditingController barcodeController;
  final TextEditingController pieceSizeController;
  final GlobalKey<FormFieldState<String>> baseUnitFieldKey;
  final GlobalKey<FormFieldState<String>> categoryFieldKey;
  final String? baseUnit;
  final String? categoryLabel;
  final VoidCallback onSelectBaseUnit;
  final VoidCallback onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hintColor = Theme.of(context).hintColor;

    return InventorySectionCard(
      title: 'Item details',
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Item name',
            hintText: 'e.g., Milk 1000ml',
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
        FormField<String>(
          key: baseUnitFieldKey,
          validator: (_) =>
              baseUnit == null ? 'Please select a base unit' : null,
          builder: (state) {
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSelectBaseUnit,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Base unit',
                  helperText:
                      'ml for liquids, g for solids, pcs for countable items',
                  errorText: state.errorText,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        baseUnit ?? 'Select base unit',
                        style: baseUnit == null
                            ? textTheme.bodyMedium?.copyWith(color: hintColor)
                            : textTheme.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            );
          },
        ),
        TextFormField(
          controller: pieceSizeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Piece size',
            helperText: 'How many base units equal 1 piece',
          ),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed <= 0) {
              return 'Enter a piece size greater than 0';
            }
            return null;
          },
        ),
        TextFormField(
          controller: barcodeController,
          decoration: const InputDecoration(labelText: 'Barcode (optional)'),
        ),
        FormField<String>(
          key: categoryFieldKey,
          validator: (_) => null,
          builder: (state) {
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSelectCategory,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Category'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryLabel ?? 'Select category',
                      style: categoryLabel == null
                          ? textTheme.bodyMedium?.copyWith(color: hintColor)
                          : textTheme.bodyMedium,
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
