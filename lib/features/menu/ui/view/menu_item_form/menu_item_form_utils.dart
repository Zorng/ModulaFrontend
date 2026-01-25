import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showCheckboxSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required Set<String> selectedValues,
  required String Function(T) idBuilder,
  required String Function(T) titleBuilder,
  String Function(T)? subtitleBuilder,
  required void Function(Set<String>) onApply,
}) async {
  final itemIds = items.map(idBuilder).toList();
  final selections = List<bool>.generate(
    itemIds.length,
    (index) => selectedValues.contains(itemIds[index]),
  );
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final id = itemIds[index];
                      final isSelected = selections[index];
                      final subtitleText =
                          subtitleBuilder != null ? subtitleBuilder(item) : null;
                      return CheckboxListTile(
                        key: ValueKey(id),
                        value: isSelected,
                        title: Text(titleBuilder(item)),
                        subtitle:
                            subtitleText != null ? Text(subtitleText) : null,
                        onChanged: (value) {
                          setSheetState(() {
                            selections[index] = value ?? false;
                          });
                        },
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {
                      final updatedSelection = <String>{};
                      for (var i = 0; i < selections.length; i++) {
                        if (selections[i]) updatedSelection.add(itemIds[i]);
                      }
                      onApply(updatedSelection);
                      context.pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
