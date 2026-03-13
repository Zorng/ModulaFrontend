import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class RestockStockItemAutocomplete extends StatefulWidget {
  const RestockStockItemAutocomplete({
    super.key,
    required this.items,
    this.controller,
    required this.selectedItemId,
    required this.onSelected,
    required this.onCleared,
    required this.onTapEmpty,
  });

  final List<StockItem> items;
  final TextEditingController? controller;
  final String? selectedItemId;
  final ValueChanged<StockItem> onSelected;
  final VoidCallback onCleared;
  final VoidCallback onTapEmpty;

  @override
  State<RestockStockItemAutocomplete> createState() =>
      _RestockStockItemAutocompleteState();
}

class _RestockStockItemAutocompleteState
    extends State<RestockStockItemAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _fallbackController =
      TextEditingController();

  TextEditingController get _controller =>
      widget.controller ?? _fallbackController;

  @override
  void dispose() {
    _fallbackController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return FormField<String>(
      validator: (_) =>
          widget.selectedItemId == null ? 'Select an item to restock' : null,
      builder: (state) {
        return RawAutocomplete<StockItem>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where((item) {
              final name = item.name.toLowerCase();
              return name.contains(query);
            });
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Stock item',
                    hintText: widget.items.isEmpty
                        ? 'Select a branch first'
                        : 'Search stock item',
                    errorText: state.errorText,
                    suffixIcon: textController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: () {
                              _controller.clear();
                              widget.onCleared();
                              state.didChange(null);
                            },
                          ),
                  ),
                  onTap: () {
                    if (widget.items.isEmpty) widget.onTapEmpty();
                    textController.value = TextEditingValue(
                      text: textController.text,
                      selection: TextSelection.collapsed(
                        offset: textController.text.length,
                      ),
                    );
                  },
                  onChanged: (_) {
                    if (widget.selectedItemId != null) {
                      widget.onCleared();
                      state.didChange(null);
                    }
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            final optionList = options.toList();
            if (optionList.isEmpty) return const SizedBox.shrink();
            final boxWidth = width.clamp(280.0, 420.0);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: boxWidth,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: optionList.length,
                    itemBuilder: (context, index) {
                      final option = optionList[index];
                      return ListTile(
                        title: Text(option.name),
                        subtitle: Text(
                          '${option.baseUnit} • ${option.branchName}',
                        ),
                        onTap: () {
                          onSelected(option);
                          state.didChange(option.id);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (item) {
            widget.onSelected(item);
            state.didChange(item.id);
          },
        );
      },
    );
  }
}
