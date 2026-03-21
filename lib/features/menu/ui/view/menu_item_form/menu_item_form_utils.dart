import 'package:flutter/material.dart';

Future<void> showCheckboxSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required Set<String> selectedValues,
  required String Function(T) idBuilder,
  required String Function(T) titleBuilder,
  String Function(T)? subtitleBuilder,
  required void Function(Set<String>) onApply,
  bool useDialog = false,
  bool showSelectAllAction = false,
  String selectAllLabel = 'Select all',
  String clearAllLabel = 'Clear all',
}) async {
  const dialogBorderRadius = BorderRadius.all(Radius.circular(16));
  const sheetBorderRadius = BorderRadius.vertical(top: Radius.circular(16));
  const maxVisibleItems = 5;
  final itemIds = items.map(idBuilder).toList();
  final selections = List<bool>.generate(
    itemIds.length,
    (index) => selectedValues.contains(itemIds[index]),
  );

  Widget buildSelectionContent(
    BuildContext context,
    void Function(void Function()) setState,
  ) {
    final allSelected = selections.isNotEmpty && selections.every((selected) => selected);
    final hasSubtitles = subtitleBuilder != null;
    final tileHeight = hasSubtitles ? 72.0 : 56.0;
    final listMaxHeight =
        (items.length < maxVisibleItems ? items.length : maxVisibleItems) *
        tileHeight;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: useDialog ? dialogBorderRadius : sheetBorderRadius,
      child: Padding(
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (showSelectAllAction) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      for (var i = 0; i < selections.length; i++) {
                        selections[i] = !allSelected;
                      }
                    });
                  },
                  child: Text(allSelected ? clearAllLabel : selectAllLabel),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: listMaxHeight),
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
                    subtitle: subtitleText != null ? Text(subtitleText) : null,
                    onChanged: (value) {
                      setState(() {
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
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (useDialog) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(borderRadius: dialogBorderRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return buildSelectionContent(context, setDialogState);
              },
            ),
          ),
        );
      },
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: sheetBorderRadius),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return buildSelectionContent(context, setSheetState);
        },
      );
    },
  );
}
