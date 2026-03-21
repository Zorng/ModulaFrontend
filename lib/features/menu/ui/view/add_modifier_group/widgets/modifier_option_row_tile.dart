import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_models.dart';

class ModifierOptionRowTile extends StatelessWidget {
  const ModifierOptionRowTile({
    super.key,
    required this.option,
    required this.requiresPriceInput,
    required this.isSingleSelection,
    required this.isDefaultSelected,
    required this.onRemove,
    required this.onChanged,
    required this.onDefaultSelected,
    this.readOnly = false,
    this.showRemoveAction = true,
    this.showDefaultSelector = true,
  });

  final ModifierOptionRowModel option;
  final bool requiresPriceInput;
  final bool isSingleSelection;
  final bool isDefaultSelected;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onDefaultSelected;
  final bool readOnly;
  final bool showRemoveAction;
  final bool showDefaultSelector;

  @override
  Widget build(BuildContext context) {
    final fillColor = const Color(0xFFF7F7F7);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    final isSmall = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            if (isSmall)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: option.nameController,
                      readOnly: readOnly,
                      decoration: InputDecoration(
                        hintText: 'Option Name',
                        prefixIcon: const Icon(Icons.text_fields, size: 18),
                        filled: true,
                        fillColor: fillColor,
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  if (showRemoveAction) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: onRemove,
                      tooltip: 'Remove option',
                    ),
                  ],
                ],
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final actionWidth =
                      isSingleSelection && showDefaultSelector ? 152.0 : 0.0;
                  final deleteWidth = showRemoveAction ? 48.0 : 0.0;
                  final gapCount =
                      (requiresPriceInput ? 1 : 0) +
                      (actionWidth > 0 ? 1 : 0);
                  final reservedWidth =
                      deleteWidth +
                      (requiresPriceInput ? 300.0 : 0.0) +
                      actionWidth +
                      (gapCount * 16.0);
                  final nameWidth = (constraints.maxWidth - reservedWidth).clamp(
                    220.0,
                    constraints.maxWidth,
                  );

                  return Row(
                    children: [
                      if (showRemoveAction)
                        SizedBox(
                          width: 48,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: onRemove,
                            tooltip: 'Remove option',
                          ),
                        ),
                      SizedBox(
                        width: nameWidth,
                        child: TextField(
                          controller: option.nameController,
                          readOnly: readOnly,
                          decoration: InputDecoration(
                            hintText: 'Option Name',
                            prefixIcon: const Icon(Icons.text_fields, size: 18),
                            filled: true,
                            fillColor: fillColor,
                            border: border,
                            enabledBorder: border,
                            focusedBorder: border,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      if (requiresPriceInput) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: option.priceController,
                            readOnly: readOnly,
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 14, right: 8),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    '\$',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              filled: true,
                              fillColor: fillColor,
                              border: border,
                              enabledBorder: border,
                              focusedBorder: border,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isSingleSelection && showDefaultSelector) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 152,
                          child: InkWell(
                            onTap: readOnly ? null : onDefaultSelected,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDefaultSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isDefaultSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isDefaultSelected ? 'Default' : 'Set default',
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDefaultSelected
                                                ? Theme.of(context).primaryColor
                                                : null,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            if (isSmall) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (requiresPriceInput)
                    Expanded(
                      child: TextField(
                        controller: option.priceController,
                        readOnly: readOnly,
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 14, right: 8),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                '\$',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          filled: true,
                          fillColor: fillColor,
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                  if (requiresPriceInput && isSingleSelection && showDefaultSelector)
                    const SizedBox(width: 12),
                  if (isSingleSelection && showDefaultSelector)
                    SizedBox(
                      width: 140,
                      child: InkWell(
                        onTap: readOnly ? null : onDefaultSelected,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                isDefaultSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isDefaultSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isDefaultSelected ? 'Default' : 'Set default',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDefaultSelected
                                            ? Theme.of(context).primaryColor
                                            : null,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
