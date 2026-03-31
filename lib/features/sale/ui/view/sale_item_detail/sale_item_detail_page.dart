import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/widgets/sale_item_detail_bottom_bar.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/widgets/sale_item_detail_image.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/widgets/sale_item_modifier_group_section.dart';

class SaleItemDetailPage extends ConsumerStatefulWidget {
  const SaleItemDetailPage({super.key, required this.item});

  final MenuItem item;

  @override
  ConsumerState<SaleItemDetailPage> createState() => _SaleItemDetailPageState();
}

class _SaleItemDetailPageState extends ConsumerState<SaleItemDetailPage> {
  late int _quantity;
  late Map<String, Set<String>> _selectedOptionIds;
  late Future<(MenuItem, List<ModifierGroup>)> _loadFuture;
  bool _hasRetried = false;
  bool _isRepairingLegacyMultiSelect = false;
  final Set<String> _legacyRepairAttempted = <String>{};

  @override
  void initState() {
    super.initState();
    _quantity = 1;
    _selectedOptionIds = {};
    _loadFuture = ref
        .read(menuViewModelProvider.notifier)
        .loadItemWithModifiers(widget.item.id);
  }

  Map<String, Set<String>> _initialSelections(List<ModifierGroup> groups) {
    final map = <String, Set<String>>{};
    for (final group in groups) {
      final defaults = <String>{};
      if (group.selectionType == 'single') {
        final defaultId =
            group.defaultOptionId ??
            (group.options.isNotEmpty ? group.options.first.id : null);
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
        final modifiers = fetchedMods.isNotEmpty ? fetchedMods : hydratedMods;
        final staleMultiGroups = modifiers
            .where(_needsLegacyMultiSelectRepair)
            .toList(growable: false);
        final repairableMultiGroups = staleMultiGroups
            .where((group) => !_legacyRepairAttempted.contains(group.id))
            .toList(growable: false);

        final gate = ref.watch(saleAccessGateProvider);

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

        if (staleMultiGroups.isNotEmpty) {
          if (!_isRepairingLegacyMultiSelect &&
              repairableMultiGroups.isNotEmpty) {
            _legacyRepairAttempted.addAll(
              repairableMultiGroups.map((group) => group.id),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              unawaited(_repairLegacyMultiSelectGroups(repairableMultiGroups));
            });
          }
          return const Center(child: CircularProgressIndicator());
        }

        final hasError =
            snapshot.hasError ||
            menuState.hydrationErrors.containsKey(widget.item.id);
        final isHydrating =
            !hasError &&
            modifiers.isEmpty &&
            snapshot.connectionState != ConnectionState.done;
        final showError = hasError && _hasRetried && modifiers.isEmpty;

        final width = MediaQuery.of(context).size.width;
        final isLarge = AppBreakpoints.isLarge(width);

        final imageSection = Center(
          child: SizedBox(
            width: isLarge ? double.infinity : width * 0.5,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                clipBehavior: Clip.antiAlias,
                child: SaleItemDetailImage(imageUrl: itemToUse.imageUrl),
              ),
            ),
          ),
        );

        final headerSection = Row(
          children: [
            Expanded(
              child: Text(
                itemToUse.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '\$${itemToUse.price.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        );

        final modifiersSection = isHydrating
            ? const Center(child: CircularProgressIndicator())
            : showError
            ? const Center(child: Text('Unable to load modifiers.'))
            : modifiers.isEmpty
            ? const Center(child: Text('No modifiers for this item.'))
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 8, 16, isLarge ? 80 : 16),
                itemCount: modifiers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final group = modifiers[index];
                  final selected = _selectedOptionIds[group.id] ?? {};
                  return SaleItemModifierGroupSection(
                    group: group,
                    selectedOptionIds: selected,
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedOptionIds[group.id] = newSelection;
                      });
                    },
                  );
                },
              );

        // Compute pricing breakdown
        final pricing = _computeSelectionPricing(
          itemToUse,
          modifiers,
          _selectedOptionIds,
          _quantity,
        );
        final selectionValidation = _validateSelections(
          modifiers,
          _selectedOptionIds,
        );
        final hasUnpricedSelections = pricing.unpricedOptionNames.isNotEmpty;
        final canAddToCart =
            gate.canAddToCart &&
            selectionValidation.blockingMessage == null &&
            !hasUnpricedSelections;
        final blockingMessage = !gate.canAddToCart
            ? gate.blockingMessage
            : selectionValidation.blockingMessage ??
                  (hasUnpricedSelections
                      ? 'One or more selected modifier options do not have item-level prices configured yet.'
                      : null);

        // Check if we're in a dialog context (no Scaffold parent)
        final isDialog = ModalRoute.of(context) is! PageRoute;

        final bottomBar = SaleItemDetailBottomBar(
          basePrice: itemToUse.price,
          addonTotal: pricing.addonTotalUsd,
          totalUsd: pricing.lineTotalUsd,
          quantity: _quantity,
          selectedOptions: pricing.selectedOptions,
          onQuantityChanged: (value) => setState(() => _quantity = value),
          canAddToCart: canAddToCart,
          blockingMessage: blockingMessage,
          showPriceBreakdown: true, // Always show price breakdown
          onAddItem: canAddToCart
              ? () {
                  final result = SaleItemSelectionResult(
                    item: itemToUse,
                    quantity: _quantity,
                    selectedOptionIds: {
                      for (final entry in _selectedOptionIds.entries)
                        entry.key: entry.value.toList(),
                    },
                    selectedOptions: pricing.selectedOptions,
                    addonTotalUsd: pricing.addonTotalUsd,
                    unitPriceUsd: pricing.unitPriceUsd,
                    lineTotalUsd: pricing.lineTotalUsd,
                  );
                  context.pop(result);
                }
              : null,
        );

        // Build the modal content for dialogs
        if (isDialog) {
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header with title, description, and close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemToUse.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (itemToUse.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                itemToUse.description,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Modifiers and bottom bar (no image)
                Expanded(child: modifiersSection),
                bottomBar,
              ],
            ),
          );
        }

        // Build the content for navigation routes (Scaffold with AppBar)
        Widget bodyContent = isLarge
            ? Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: imageSection,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: headerSection,
                        ),
                        Expanded(child: modifiersSection),
                        bottomBar,
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  imageSection,
                  const SizedBox(height: 16),
                  headerSection,
                  const SizedBox(height: 12),
                  if (isHydrating)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (showError)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Unable to load modifiers.')),
                    )
                  else if (modifiers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No modifiers for this item.')),
                    )
                  else
                    ...List.generate(modifiers.length, (index) {
                      final group = modifiers[index];
                      final selected = _selectedOptionIds[group.id] ?? {};
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          SaleItemModifierGroupSection(
                            group: group,
                            selectedOptionIds: selected,
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _selectedOptionIds[group.id] = newSelection;
                              });
                            },
                          ),
                        ],
                      );
                    }),
                  const SizedBox(height: 16),
                ],
              );

        // For navigation, use Scaffold
        return Scaffold(
          appBar: AppBar(title: Text(itemToUse.name), centerTitle: false),
          body: SafeArea(child: bodyContent),
          bottomNavigationBar: isLarge ? null : bottomBar,
        );
      },
    );
  }

  bool _needsLegacyMultiSelectRepair(ModifierGroup group) {
    return group.selectionType == 'multiple' && group.maxSelections <= 1;
  }

  ModifierGroup _normalizedMultiSelectGroup(ModifierGroup group) {
    return group.copyWith(
      selectionType: 'multiple',
      selectionMode: 'MULTI',
      minSelections: group.minSelections < 0 ? 0 : group.minSelections,
      maxSelections: group.maxSelections > 1 ? group.maxSelections : 99,
    );
  }

  Future<void> _repairLegacyMultiSelectGroups(
    List<ModifierGroup> groups,
  ) async {
    if (_isRepairingLegacyMultiSelect) return;
    setState(() => _isRepairingLegacyMultiSelect = true);
    try {
      final notifier = ref.read(menuViewModelProvider.notifier);
      for (final group in groups) {
        await notifier.updateModifierGroup(_normalizedMultiSelectGroup(group));
      }
      if (!mounted) return;
      setState(() {
        _selectedOptionIds = {};
        _hasRetried = false;
        _loadFuture = notifier.loadItemWithModifiers(widget.item.id);
      });
    } finally {
      if (mounted) {
        setState(() => _isRepairingLegacyMultiSelect = false);
      }
    }
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

// double _computeTotal(
//   MenuItem item,
//   List<ModifierGroup> groups,
//   Map<String, Set<String>> selections,
//   int quantity,
// ) {
//   double addon = 0;
//   for (final group in groups) {
//     final selected = selections[group.id];
//     Set<String> chosen;
//     if (selected != null && selected.isNotEmpty) {
//       chosen = selected;
//     } else {
//       // Fallback to defaults
//       final defaults = group.options
//           .where((o) => o.isDefault)
//           .map((o) => o.id)
//           .toSet();
//       if (defaults.isNotEmpty) {
//         chosen = defaults;
//       } else if (group.selectionType == 'single' && group.options.isNotEmpty) {
//         chosen = {group.options.first.id};
//       } else {
//         chosen = {};
//       }
//     }
//     for (final option in group.options) {
//       if (chosen.contains(option.id)) {
//         addon += option.price;
//       }
//     }
//   }
//   return (item.price + addon) * quantity;
// }

class _SelectionPricing {
  const _SelectionPricing({
    required this.selectedOptions,
    required this.unpricedOptionNames,
    required this.addonTotalUsd,
    required this.unitPriceUsd,
    required this.lineTotalUsd,
  });

  final Map<String, List<ModifierOption>> selectedOptions;
  final List<String> unpricedOptionNames;
  final double addonTotalUsd;
  final double unitPriceUsd;
  final double lineTotalUsd;
}

class _SelectionValidation {
  const _SelectionValidation({this.blockingMessage});

  final String? blockingMessage;
}

_SelectionValidation _validateSelections(
  List<ModifierGroup> groups,
  Map<String, Set<String>> selections,
) {
  for (final group in groups) {
    final selectedCount = selections[group.id]?.length ?? 0;
    final minSelections = _requiredMinSelections(group);
    if (selectedCount < minSelections) {
      final optionLabel = minSelections == 1 ? 'option' : 'options';
      return _SelectionValidation(
        blockingMessage:
            'Select at least $minSelections $optionLabel for ${group.name}.',
      );
    }

    if (group.maxSelections > 0 && selectedCount > group.maxSelections) {
      final optionLabel = group.maxSelections == 1 ? 'option' : 'options';
      return _SelectionValidation(
        blockingMessage:
            'Select no more than ${group.maxSelections} $optionLabel for ${group.name}.',
      );
    }
  }

  return const _SelectionValidation();
}

int _requiredMinSelections(ModifierGroup group) {
  if (group.minSelections > 0) {
    return group.minSelections;
  }
  return group.isRequired == true ? 1 : 0;
}

_SelectionPricing _computeSelectionPricing(
  MenuItem item,
  List<ModifierGroup> groups,
  Map<String, Set<String>> selections,
  int quantity,
) {
  final groupLookup = {for (final group in groups) group.id: group};
  final selectedOptions = <String, List<ModifierOption>>{};
  final unpricedOptionNames = <String>[];
  double addonTotal = 0;

  selections.forEach((groupId, optionIds) {
    final group = groupLookup[groupId];
    if (group == null) return;
    final chosen = group.options
        .where((opt) => optionIds.contains(opt.id))
        .toList(growable: false);
    if (chosen.isEmpty) return;
    selectedOptions[groupId] = chosen;
    addonTotal += chosen.fold<double>(0, (sum, opt) {
      if (!opt.isPriceConfigured) {
        unpricedOptionNames.add(opt.name);
        return sum;
      }
      return sum + opt.price;
    });
  });

  final unitPriceUsd = item.price + addonTotal;
  return _SelectionPricing(
    selectedOptions: selectedOptions,
    unpricedOptionNames: unpricedOptionNames,
    addonTotalUsd: addonTotal,
    unitPriceUsd: unitPriceUsd,
    lineTotalUsd: unitPriceUsd * quantity,
  );
}
