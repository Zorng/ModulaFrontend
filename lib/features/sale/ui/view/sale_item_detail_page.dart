import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/network_image_helper_web.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

class SaleItemDetailPage extends ConsumerStatefulWidget {
  const SaleItemDetailPage({
    super.key,
    required this.item,
  });

  final MenuItem item;

  @override
  ConsumerState<SaleItemDetailPage> createState() => _SaleItemDetailPageState();
}

class _SaleItemDetailPageState extends ConsumerState<SaleItemDetailPage> {
  late int _quantity;
  late Map<String, Set<String>> _selectedOptionIds;
  late Future<(MenuItem, List<ModifierGroup>)> _loadFuture;
  bool _hasRetried = false;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
    _selectedOptionIds = {};
    _loadFuture =
        ref.read(menuViewModelProvider.notifier).loadItemWithModifiers(widget.item.id);
  }

  Map<String, Set<String>> _initialSelections(List<ModifierGroup> groups) {
    final map = <String, Set<String>>{};
    for (final group in groups) {
      final defaults = <String>{};
      if (group.selectionType == 'single') {
        final defaultId =
            group.defaultOptionId ?? (group.options.isNotEmpty ? group.options.first.id : null);
        if (defaultId != null) defaults.add(defaultId);
      } else {
        for (final option in group.options) {
          if (option.isDefault) defaults.add(option.id);
        }
      }
      if (defaults.isNotEmpty) {
        map[group.id] = defaults;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    return FutureBuilder<(MenuItem, List<ModifierGroup>)?>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final tuple = snapshot.data;
        final hydratedItemFromState = menuState.hydratedItems[widget.item.id];
        final itemToUse = tuple?.$1 ?? hydratedItemFromState ?? widget.item;

        final fetchedMods = tuple?.$2 ?? const <ModifierGroup>[];
        final hydratedMods = itemToUse.modifierGroupIds
            .map((id) => menuState.hydratedModifierGroups[id])
            .whereType<ModifierGroup>()
            .toList();
        var modifiers = fetchedMods.isNotEmpty ? fetchedMods : hydratedMods;
        final sessionOpen =
            ref.watch(cashSessionViewModelProvider).sessionStatus ==
                SessionStatus.open;

        // If the first attempt returned empty, trigger one retry automatically.
        if (modifiers.isEmpty &&
            !_hasRetried &&
            snapshot.connectionState == ConnectionState.done) {
          _hasRetried = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _loadFuture = ref
                  .read(menuViewModelProvider.notifier)
                  .loadItemWithModifiers(widget.item.id);
            });
          });
          return const Center(child: CircularProgressIndicator());
        }

        if (_selectedOptionIds.isEmpty && modifiers.isNotEmpty) {
          _selectedOptionIds = _initialSelections(modifiers);
        }

        final hasError = snapshot.hasError ||
            menuState.hydrationErrors.containsKey(widget.item.id);
        final isHydrating =
            !hasError && modifiers.isEmpty && snapshot.connectionState != ConnectionState.done;
        final showError = hasError && _hasRetried && modifiers.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(itemToUse.name),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _SaleImage(
                            imageUrl: itemToUse.imageUrl,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemToUse.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '\$${itemToUse.price.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            Expanded(
              child: isHydrating
                  ? const Center(child: CircularProgressIndicator())
                  : showError
                      ? const Center(child: Text('Unable to load modifiers.'))
                      : modifiers.isEmpty
                          ? const Center(child: Text('No modifiers for this item.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: modifiers.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final group = modifiers[index];
                                final selected = _selectedOptionIds[group.id] ?? {};
                                return _ModifierGroupSection(
                                  group: group,
                                  selectedOptionIds: selected,
                                  onSelectionChanged: (newSelection) {
                                    setState(() {
                                      _selectedOptionIds[group.id] = newSelection;
                                    });
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '\$${_computeTotal(itemToUse, modifiers, _selectedOptionIds, _quantity).toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: _quantity,
                        onChanged: (value) => setState(() => _quantity = value),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: sessionOpen
                                ? () {
                                    final pricing = _computeSelectionPricing(
                                      itemToUse,
                                      modifiers,
                                      _selectedOptionIds,
                                      _quantity,
                                    );
                                    final result = SaleItemSelectionResult(
                                      item: itemToUse,
                                      quantity: _quantity,
                                      selectedOptionIds: {
                                        for (final entry
                                            in _selectedOptionIds.entries)
                                          entry.key: entry.value.toList(),
                                      },
                                      selectedOptions: pricing.selectedOptions,
                                      addonTotalUsd: pricing.addonTotalUsd,
                                      unitPriceUsd: pricing.unitPriceUsd,
                                      lineTotalUsd: pricing.lineTotalUsd,
                                    );
                                    Navigator.pop(context, result);
                                  }
                                : null,
                            child: const Text('Add Item'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!sessionOpen) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Start a cash session to add items.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SaleItemSelectionResult {
  const SaleItemSelectionResult({
    required this.item,
    required this.quantity,
    required this.selectedOptionIds,
    required this.selectedOptions,
    required this.addonTotalUsd,
    required this.unitPriceUsd,
    required this.lineTotalUsd,
  });

  final MenuItem item;
  final int quantity;
  final Map<String, List<String>> selectedOptionIds;
  final Map<String, List<ModifierOption>> selectedOptions;
  final double addonTotalUsd;
  final double unitPriceUsd;
  final double lineTotalUsd;
}

class _SaleImage extends StatelessWidget {
  const _SaleImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final placeholder = Container(
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_cafe_outlined,
        size: 48,
      ),
    );
    if (!hasUrl) return placeholder;
    return buildAdaptiveNetworkImage(imageUrl!, placeholder);
  }
}

double _computeTotal(
  MenuItem item,
  List<ModifierGroup> groups,
  Map<String, Set<String>> selections,
  int quantity,
) {
  double addon = 0;
  for (final group in groups) {
    final selected = selections[group.id];
    Set<String> chosen;
    if (selected != null && selected.isNotEmpty) {
      chosen = selected;
    } else {
      // Fallback to defaults
      final defaults = group.options.where((o) => o.isDefault).map((o) => o.id).toSet();
      if (defaults.isNotEmpty) {
        chosen = defaults;
      } else if (group.selectionType == 'single' && group.options.isNotEmpty) {
        chosen = {group.options.first.id};
      } else {
        chosen = {};
      }
    }
    for (final option in group.options) {
      if (chosen.contains(option.id)) {
        addon += option.price;
      }
    }
  }
  return (item.price + addon) * quantity;
}

class _SelectionPricing {
  const _SelectionPricing({
    required this.selectedOptions,
    required this.addonTotalUsd,
    required this.unitPriceUsd,
    required this.lineTotalUsd,
  });

  final Map<String, List<ModifierOption>> selectedOptions;
  final double addonTotalUsd;
  final double unitPriceUsd;
  final double lineTotalUsd;
}

_SelectionPricing _computeSelectionPricing(
  MenuItem item,
  List<ModifierGroup> groups,
  Map<String, Set<String>> selections,
  int quantity,
) {
  final groupLookup = {for (final group in groups) group.id: group};
  final selectedOptions = <String, List<ModifierOption>>{};
  double addonTotal = 0;

  selections.forEach((groupId, optionIds) {
    final group = groupLookup[groupId];
    if (group == null) return;
    final chosen = group.options
        .where((opt) => optionIds.contains(opt.id))
        .toList(growable: false);
    if (chosen.isEmpty) return;
    selectedOptions[groupId] = chosen;
    addonTotal += chosen.fold<double>(0, (sum, opt) => sum + opt.price);
  });

  final unitPriceUsd = item.price + addonTotal;
  return _SelectionPricing(
    selectedOptions: selectedOptions,
    addonTotalUsd: addonTotal,
    unitPriceUsd: unitPriceUsd,
    lineTotalUsd: unitPriceUsd * quantity,
  );
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Qty'),
        const SizedBox(width: 8),
        IconButton(
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$quantity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _ModifierGroupSection extends StatelessWidget {
  const _ModifierGroupSection({
    required this.group,
    required this.selectedOptionIds,
    required this.onSelectionChanged,
  });

  final ModifierGroup group;
  final Set<String> selectedOptionIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  bool get _isSingle => group.selectionType == 'single';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (group.isRequired == true) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Required'),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ...group.options.map((option) {
            final isSelected = selectedOptionIds.contains(option.id);
            final priceDelta = option.price;
            final priceLabel =
                priceDelta == 0 ? '' : ' (+\$${priceDelta.toStringAsFixed(2)})';
            final highlightColor =
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
            final tile = Container(
              decoration: BoxDecoration(
                color: isSelected ? highlightColor : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isSingle
                  ? RadioListTile<String>(
                      value: option.id,
                      groupValue: selectedOptionIds.isNotEmpty
                          ? selectedOptionIds.first
                          : null,
                      title: Text('${option.name}$priceLabel'),
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 4, right: 8),
                      onChanged: (value) {
                        if (value == null) return;
                        onSelectionChanged({value});
                      },
                    )
                  : CheckboxListTile(
                      value: isSelected,
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 4, right: 8),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text('${option.name}$priceLabel'),
                      onChanged: (checked) {
                        final updated = {...selectedOptionIds};
                        if (checked == true) {
                          updated.add(option.id);
                        } else {
                          updated.remove(option.id);
                        }
                        onSelectionChanged(updated);
                      },
                    ),
            );

            if (_isSingle) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: tile,
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: tile,
              );
            }
          }),
        ],
      ),
    );
  }
}
