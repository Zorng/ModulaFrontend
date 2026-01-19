import 'package:flutter/material.dart';

class InventoryJournalSearchAutocomplete extends StatefulWidget {
  const InventoryJournalSearchAutocomplete({
    super.key,
    required this.initialValue,
    required this.options,
    required this.onChanged,
  });

  final String initialValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<InventoryJournalSearchAutocomplete> createState() =>
      _InventoryJournalSearchAutocompleteState();
}

class _InventoryJournalSearchAutocompleteState
    extends State<InventoryJournalSearchAutocomplete> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant InventoryJournalSearchAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return widget.options.where(
          (option) => option.toLowerCase().contains(query),
        );
      },
      onSelected: widget.onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.value = _controller.value;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search stock item or note',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: widget.onChanged,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

