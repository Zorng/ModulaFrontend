import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_branch_option.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/widgets/restock_stock_summary.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/widgets/adjust_quantity_inputs.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_field_label.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class AdjustStockQuantityPage extends ConsumerStatefulWidget {
  const AdjustStockQuantityPage({
    super.key,
    required this.item,
    this.initialBranchId,
  });

  final StockItem item;
  final String? initialBranchId;

  @override
  ConsumerState<AdjustStockQuantityPage> createState() =>
      _AdjustStockQuantityPageState();
}

class _AdjustStockQuantityPageState
    extends ConsumerState<AdjustStockQuantityPage> {
  static const double _sectionCardElevation = 0;
  static const double _sectionRowSpacing = 16;
  static const double _wideSegmentWidth = 180;
  final _pcsCtrl = TextEditingController();
  final _baseUnitCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  _AdjustmentMode _mode = _AdjustmentMode.delta;
  _AdjustmentType _type = _AdjustmentType.add;
  String? _selectedBranchId;
  int? _selectedBranchOnHand;
  int? _selectedBranchMinThreshold;
  bool _isBranchContextLoading = false;
  bool _isBranchAvailabilityLoading = false;
  Map<String, bool> _branchHasStockPosition = const <String, bool>{};
  int _branchAvailabilityRequestId = 0;
  String _branchAvailabilityKey = '';
  String? _branchError;
  String? _quantityError;
  String? _submitError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = _normalizeBranchId(widget.initialBranchId);
    _pcsCtrl.addListener(_handleQuantityInputChanged);
    _baseUnitCtrl.addListener(_handleQuantityInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final branchState = ref.read(branchControllerProvider);
      if (branchState.branches.isEmpty) {
        try {
          await ref.read(branchControllerProvider.notifier).loadInitial();
        } catch (_) {
          // Keep user-branch fallback options when the branch directory fails.
        }
      }
      await _loadSelectedBranchContext();
    });
  }

  @override
  void dispose() {
    _pcsCtrl.removeListener(_handleQuantityInputChanged);
    _baseUnitCtrl.removeListener(_handleQuantityInputChanged);
    _pcsCtrl.dispose();
    _baseUnitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseItem = widget.item;
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );
    final isWide = !isSmallScreen;
    final loginState = ref.watch(loginControllerProvider);
    final activeTenantId =
        (loginState.session?.activeTenantId ??
                loginState.session?.user.tenantId)
            ?.trim() ??
        '';
    final tenantBranches = ref
        .watch(branchControllerProvider.select((state) => state.branches))
        .where(
          (branch) =>
              activeTenantId.isEmpty ||
              branch.tenantId.trim().isEmpty ||
              branch.tenantId.trim() == activeTenantId,
        )
        .toList(growable: false);
    final branchOptions = buildInventoryBranchOptions(
      items: [baseItem],
      tenantBranches: tenantBranches,
      userBranches: loginState.user?.branches ?? const [],
    ).where((entry) => entry.id != 'all').toList(growable: false);
    final branchAvailabilityKey = branchOptions
        .map((entry) => entry.id)
        .join('|');
    if (_branchAvailabilityKey != branchAvailabilityKey) {
      _branchAvailabilityKey = branchAvailabilityKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_loadBranchAvailability(branchOptions));
      });
    }
    final resolvedSelectedBranchId =
        branchOptions.any((entry) => entry.id == _selectedBranchId)
        ? _selectedBranchId
        : null;
    final selectedBranchEntries = branchOptions
        .where((entry) => entry.id == resolvedSelectedBranchId)
        .toList(growable: false);
    final selectedBranchName = selectedBranchEntries.isNotEmpty
        ? selectedBranchEntries.first.name
        : null;
    final effectiveItem = baseItem.copyWith(
      branchId: resolvedSelectedBranchId ?? baseItem.branchId,
      branchName: selectedBranchName ?? baseItem.branchName,
      onHand: resolvedSelectedBranchId == null
          ? baseItem.onHand
          : (_selectedBranchOnHand ?? 0),
      minThreshold: resolvedSelectedBranchId == null
          ? baseItem.minThreshold
          : (_selectedBranchMinThreshold ?? baseItem.minThreshold),
    );
    final sortedBranchOptions = [...branchOptions]
      ..sort((a, b) {
        final aHasStock = _branchHasStockPosition[a.id] ?? true;
        final bHasStock = _branchHasStockPosition[b.id] ?? true;
        if (aHasStock != bHasStock) {
          return aHasStock ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
    final hasSelectableBranch = sortedBranchOptions.any(
      (branch) => _branchHasStockPosition[branch.id] ?? true,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Adjust inventory'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
        children: [
          _buildSectionCard(
            title: 'Item & Branch',
            children: [
              if (isSmallScreen) ...[
                InventoryFieldLabel(
                  text: 'Item name',
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(
                      baseItem.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                InventoryFieldLabel(
                  text: 'Branch',
                  isRequired: true,
                  child: InventoryDropdown<String>(
                    key: ValueKey(
                      'adjust-branch-${resolvedSelectedBranchId ?? 'none'}',
                    ),
                    initialValue: resolvedSelectedBranchId,
                    hintText: 'Select branch',
                    enabled:
                        branchOptions.isNotEmpty &&
                        !_isBranchAvailabilityLoading &&
                        hasSelectableBranch,
                    entries: sortedBranchOptions
                        .map(
                          (branch) => DropdownMenuEntry<String>(
                            value: branch.id,
                            label: (_branchHasStockPosition[branch.id] ?? true)
                                ? branch.name
                                : '${branch.name} (No stock)',
                            enabled: _branchHasStockPosition[branch.id] ?? true,
                          ),
                        )
                        .toList(),
                    helperText: branchOptions.isEmpty
                        ? 'No branches are available for adjustment.'
                        : _isBranchAvailabilityLoading
                        ? 'Checking branch stock availability.'
                        : !hasSelectableBranch
                        ? 'This item has no stock in any branch yet.'
                        : resolvedSelectedBranchId == null
                        ? 'Select a branch to load current stock.'
                        : _isBranchContextLoading
                        ? 'Loading current stock.'
                        : null,
                    errorText: _branchError,
                    onSelected: (value) async {
                      final selected = _normalizeBranchId(value);
                      setState(() {
                        _selectedBranchId = selected;
                        _branchError = null;
                        _quantityError = null;
                        _submitError = null;
                      });
                      await _loadSelectedBranchContext();
                    },
                  ),
                ),
              ] else
                _buildSectionRow(
                  first: InventoryFieldLabel(
                    text: 'Item name',
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Text(
                        baseItem.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  second: InventoryFieldLabel(
                    text: 'Branch',
                    isRequired: true,
                    child: InventoryDropdown<String>(
                      key: ValueKey(
                        'adjust-branch-${resolvedSelectedBranchId ?? 'none'}',
                      ),
                      initialValue: resolvedSelectedBranchId,
                      hintText: 'Select branch',
                      enabled:
                          branchOptions.isNotEmpty &&
                          !_isBranchAvailabilityLoading &&
                          hasSelectableBranch,
                      entries: sortedBranchOptions
                          .map(
                            (branch) => DropdownMenuEntry<String>(
                              value: branch.id,
                              label:
                                  (_branchHasStockPosition[branch.id] ?? true)
                                  ? branch.name
                                  : '${branch.name} (No stock)',
                              enabled:
                                  _branchHasStockPosition[branch.id] ?? true,
                            ),
                          )
                          .toList(),
                      helperText: branchOptions.isEmpty
                          ? 'No branches are available for adjustment.'
                          : _isBranchAvailabilityLoading
                          ? 'Checking branch stock availability.'
                          : !hasSelectableBranch
                          ? 'This item has no stock in any branch yet.'
                          : resolvedSelectedBranchId == null
                          ? 'Select a branch to load current stock.'
                          : _isBranchContextLoading
                          ? 'Loading current stock.'
                          : null,
                      errorText: _branchError,
                      onSelected: (value) async {
                        final selected = _normalizeBranchId(value);
                        setState(() {
                          _selectedBranchId = selected;
                          _branchError = null;
                          _quantityError = null;
                          _submitError = null;
                        });
                        await _loadSelectedBranchContext();
                      },
                    ),
                  ),
                ),
              if (resolvedSelectedBranchId != null)
                RestockStockSummary(
                  item: effectiveItem,
                  isLoading: _isBranchContextLoading,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Adjustment Type',
            children: [
              InventoryFieldLabel(
                text: 'Adjustment mode',
                child: _RoundedSegmentedControl<_AdjustmentMode>(
                  value: _mode,
                  wideSegmentWidth: _wideSegmentWidth,
                  options: const [
                    _RoundedSegmentedControlOption(
                      value: _AdjustmentMode.delta,
                      label: 'Adjust by amount',
                    ),
                    _RoundedSegmentedControlOption(
                      value: _AdjustmentMode.setToCount,
                      label: 'Set counted stock',
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _mode = value;
                    _quantityError = null;
                    _submitError = null;
                  }),
                ),
              ),
              if (_mode == _AdjustmentMode.delta)
                InventoryFieldLabel(
                  text: 'Adjustment direction',
                  child: _RoundedSegmentedControl<_AdjustmentType>(
                    value: _type,
                    wideSegmentWidth: _wideSegmentWidth,
                    options: const [
                      _RoundedSegmentedControlOption(
                        value: _AdjustmentType.add,
                        label: 'Add',
                      ),
                      _RoundedSegmentedControlOption(
                        value: _AdjustmentType.reduce,
                        label: 'Remove',
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _type = value;
                      _quantityError = null;
                      _submitError = null;
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Adjustment Details',
            children: [
              AdjustQuantityInputs(
                item: effectiveItem,
                pcsCtrl: _pcsCtrl,
                baseCtrl: _baseUnitCtrl,
                mode: _mode == _AdjustmentMode.delta
                    ? AdjustQuantityInputMode.delta
                    : AdjustQuantityInputMode.setToCount,
                errorText: _quantityError,
              ),
              _buildProjectedStockCard(
                context,
                item: effectiveItem,
                hasSelectedBranch: resolvedSelectedBranchId != null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Notes',
            children: [
              InventoryFieldLabel(
                text: 'Notes',
                isOptional: true,
                child: TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add notes for this adjustment',
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ActionRow(
            isWide: isWide,
            isSaving: _isSaving,
            onCancel: _handleCancel,
            onSave: () =>
                _submit(effectiveItem, selectedBranchName: selectedBranchName),
            saveLabel: 'Apply Adjustment',
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              _submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return InventorySectionCard(
      title: title,
      backgroundColor: Colors.white,
      elevation: _sectionCardElevation,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withSectionSpacing(children),
        ),
      ],
    );
  }

  List<Widget> _withSectionSpacing(List<Widget> items) {
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      spaced.add(items[i]);
      if (i != items.length - 1) {
        spaced.add(const SizedBox(height: _sectionRowSpacing));
      }
    }
    return spaced;
  }

  Widget _buildSectionRow({required Widget first, Widget? second}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        if (second != null) ...[
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
      ],
    );
  }

  Widget _buildProjectedStockCard(
    BuildContext context, {
    required StockItem item,
    required bool hasSelectedBranch,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pcsCtrl, _baseUnitCtrl]),
      builder: (context, _) {
        final enteredBaseQty = _enteredBaseQuantity(item);
        final titleStyle = Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600);
        final defaultValueStyle = Theme.of(context).textTheme.titleMedium;
        final bodyStyle = Theme.of(context).textTheme.bodySmall;

        String valueText = '--';
        String helperText = 'Select a branch to preview projected stock.';

        if (hasSelectedBranch) {
          if (enteredBaseQty == null) {
            helperText =
                'Projected stock will update after valid quantity input.';
          } else {
            final projectedOnHand = _mode == _AdjustmentMode.setToCount
                ? enteredBaseQty
                : item.onHand +
                      (_type == _AdjustmentType.add
                          ? enteredBaseQty
                          : -enteredBaseQty);
            valueText = _mode == _AdjustmentMode.setToCount
                ? _formatBaseUnits(item, enteredBaseQty)
                : _formatProjectedOnHand(item, projectedOnHand);
            helperText = _mode == _AdjustmentMode.setToCount
                ? 'Counted total in base units'
                : 'Projected on-hand after adjustment';
          }
        }

        final isBelowZero = valueText == 'Would go below zero';
        final valueStyle = isBelowZero
            ? Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
            : defaultValueStyle;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Projected stock', style: titleStyle),
              const SizedBox(height: 4),
              Text(valueText, style: valueStyle),
              const SizedBox(height: 8),
              Text(helperText, style: bodyStyle),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(StockItem item, {String? selectedBranchName}) async {
    final selectedBranchId = _normalizeBranchId(_selectedBranchId);
    if (selectedBranchId == null) {
      setState(() {
        _branchError = 'Please select a branch';
        _quantityError = null;
        _submitError = null;
      });
      return;
    }

    final totalBaseQty = _enteredBaseQuantity(item);
    if (totalBaseQty == null) {
      setState(() {
        _quantityError = 'Enter non-negative whole numbers for quantity.';
        _submitError = null;
      });
      return;
    }
    final allowsZero = _mode == _AdjustmentMode.setToCount;
    if ((allowsZero && totalBaseQty < 0) ||
        (!allowsZero && totalBaseQty <= 0)) {
      setState(() {
        _quantityError = _mode == _AdjustmentMode.setToCount
            ? 'Enter a counted quantity of 0 or more.'
            : 'Enter a non-zero quantity.';
        _submitError = null;
      });
      return;
    }
    if (_mode == _AdjustmentMode.setToCount && totalBaseQty == item.onHand) {
      setState(() {
        _quantityError = 'Count already matches current on-hand.';
        _submitError = null;
      });
      return;
    }

    final magnitude = totalBaseQty.abs();
    final delta = _type == _AdjustmentType.add ? magnitude : -magnitude;
    final adjustmentDelta = _mode == _AdjustmentMode.setToCount
        ? totalBaseQty - item.onHand
        : delta;

    setState(() {
      _isSaving = true;
      _branchError = null;
      _quantityError = null;
      _submitError = null;
    });

    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .applyInventoryAdjustment(
            stockItemId: widget.item.id,
            branchId: selectedBranchId,
            style: _mode == _AdjustmentMode.setToCount
                ? 'SET_TO_COUNT'
                : 'DELTA',
            delta: _mode == _AdjustmentMode.delta ? delta : null,
            countedOnHandInBaseUnit: _mode == _AdjustmentMode.setToCount
                ? totalBaseQty
                : null,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      final actor = ref.read(loginControllerProvider).user?.name ?? 'System';
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .recordEntry(
            InventoryJournalEntry(
              id: 'ja-${DateTime.now().microsecondsSinceEpoch}',
              itemId: widget.item.id,
              itemName: widget.item.name,
              branchId: selectedBranchId,
              branchName: selectedBranchName ?? selectedBranchId,
              reason: adjustmentDelta < 0
                  ? InventoryJournalReason.remove
                  : InventoryJournalReason.add,
              delta: adjustmentDelta,
              note: _noteCtrl.text.trim().isEmpty
                  ? _defaultAdjustmentNote()
                  : _noteCtrl.text.trim(),
              actor: actor,
              createdAt: DateTime.now(),
              occurredAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_successMessage(magnitude, totalBaseQty))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to adjust stock.',
      );
      if (_showInlineQuantityError(mapped.code)) {
        setState(() => _quantityError = mapped.message);
        return;
      }
      if (_showInlineSubmitError(mapped.code)) {
        setState(() => _submitError = mapped.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadSelectedBranchContext() async {
    final branchId = _normalizeBranchId(_selectedBranchId);
    if (branchId == null) {
      if (!mounted) return;
      setState(() {
        _selectedBranchOnHand = null;
        _selectedBranchMinThreshold = null;
        _isBranchContextLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isBranchContextLoading = true);
    }

    try {
      final onHandRecords = await ref
          .read(branchStockRepositoryProvider)
          .fetchOnHand(branchId: branchId);
      final matchingRecords = onHandRecords
          .where((record) => record.stockItemId == widget.item.id)
          .toList(growable: false);
      final matchingRecord = matchingRecords.isNotEmpty
          ? matchingRecords.first
          : null;
      if (!mounted) return;
      setState(() {
        _selectedBranchOnHand = matchingRecord?.onHand ?? 0;
        _selectedBranchMinThreshold =
            matchingRecord?.minThreshold ?? widget.item.minThreshold;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedBranchOnHand = 0;
        _selectedBranchMinThreshold = widget.item.minThreshold;
      });
    } finally {
      if (mounted) {
        setState(() => _isBranchContextLoading = false);
      }
    }
  }

  void _handleQuantityInputChanged() {
    if (_quantityError == null) return;
    setState(() => _quantityError = null);
  }

  void _handleCancel() {
    context.pop();
  }

  Future<void> _loadBranchAvailability(
    List<InventoryBranchOption> branchOptions,
  ) async {
    final branchIds = branchOptions
        .map((entry) => entry.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final requestId = ++_branchAvailabilityRequestId;

    if (branchIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        _branchHasStockPosition = const <String, bool>{};
        _isBranchAvailabilityLoading = false;
        _selectedBranchId = null;
      });
      return;
    }

    if (mounted) {
      setState(() => _isBranchAvailabilityLoading = true);
    }

    final availabilityEntries = await Future.wait(
      branchIds.map((branchId) async {
        try {
          final records = await ref
              .read(branchStockRepositoryProvider)
              .fetchOnHand(branchId: branchId, status: 'all');
          final hasStockPosition = records.any(
            (record) => record.stockItemId == widget.item.id,
          );
          return MapEntry(branchId, hasStockPosition);
        } catch (_) {
          // If the availability lookup fails, keep the branch selectable.
          return MapEntry(branchId, true);
        }
      }),
    );

    if (!mounted || requestId != _branchAvailabilityRequestId) return;

    final availability = {
      for (final entry in availabilityEntries) entry.key: entry.value,
    };
    final selectedBranchIsAvailable = _selectedBranchId == null
        ? true
        : (availability[_selectedBranchId] ?? true);

    setState(() {
      _branchHasStockPosition = availability;
      _isBranchAvailabilityLoading = false;
      if (!selectedBranchIsAvailable) {
        _selectedBranchId = null;
        _selectedBranchOnHand = null;
        _selectedBranchMinThreshold = null;
      }
    });
  }

  bool _showInlineSubmitError(InventoryErrorCode code) {
    switch (code) {
      case InventoryErrorCode.stockItemInactive:
      case InventoryErrorCode.adjustmentInvalid:
      case InventoryErrorCode.restockBatchArchived:
      case InventoryErrorCode.restockBatchNotFound:
        return true;
      default:
        return isInventoryAccessErrorCode(code);
    }
  }

  bool _showInlineQuantityError(InventoryErrorCode code) {
    switch (code) {
      case InventoryErrorCode.quantityInvalid:
      case InventoryErrorCode.negativeStockBlocked:
        return true;
      default:
        return false;
    }
  }

  String _typeLabel() =>
      _type == _AdjustmentType.add ? 'Addition' : 'Reduction';

  int? _enteredBaseQuantity(StockItem item) {
    final pcs = _parseNonNegative(_pcsCtrl.text);
    final base = _parseNonNegative(_baseUnitCtrl.text);
    if (pcs == null || base == null) return null;
    return item.pieceSize <= 1 ? base : pcs * item.pieceSize + base;
  }

  int? _parseNonNegative(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 0;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  String _formatBaseUnits(StockItem item, int baseQty) {
    return StockQuantityFormatter(
      baseQty: baseQty,
      pieceSize: 1,
      baseUnit: item.baseUnit,
    ).format();
  }

  String _formatProjectedOnHand(StockItem item, int projectedOnHand) {
    if (projectedOnHand < 0) return 'Would go below zero';
    return StockQuantityFormatter(
      baseQty: projectedOnHand,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    ).format();
  }

  String _defaultAdjustmentNote() {
    if (_mode == _AdjustmentMode.setToCount) {
      return 'Counted stock correction';
    }
    return _type == _AdjustmentType.add
        ? 'Manual addition'
        : 'Manual reduction';
  }

  String _successMessage(int magnitude, int countedTotal) {
    if (_mode == _AdjustmentMode.setToCount) {
      return 'Counted stock set to ${_formatBaseUnits(widget.item, countedTotal)}';
    }
    return '${_typeLabel()} of $magnitude applied';
  }

  String? _normalizeBranchId(String? branchId) {
    final trimmed = branchId?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == 'all') return null;
    return trimmed;
  }
}

enum _AdjustmentMode { delta, setToCount }

enum _AdjustmentType { add, reduce }

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isWide,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
  });

  final bool isWide;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final cancelStyle = AppTheme.cancelActionButtonStyle;
    final saveStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );

    if (!isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 140,
            child: FilledButton(
              style: cancelStyle,
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: FilledButton(
              style: saveStyle,
              onPressed: isSaving ? null : onSave,
              child: Text(saveLabel),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 140,
          child: FilledButton(
            style: cancelStyle,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 160,
          child: FilledButton(
            style: saveStyle,
            onPressed: isSaving ? null : onSave,
            child: Text(saveLabel),
          ),
        ),
      ],
    );
  }
}

class _RoundedSegmentedControl<T> extends StatelessWidget {
  const _RoundedSegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
    this.wideSegmentWidth,
  });

  final T value;
  final List<_RoundedSegmentedControlOption<T>> options;
  final ValueChanged<T> onChanged;
  final double? wideSegmentWidth;

  @override
  Widget build(BuildContext context) {
    final isSmall = AppBreakpoints.isSmall(MediaQuery.of(context).size.width);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final segmentChildren = [
      for (final option in options)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: option.value == value
                ? colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(option.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style:
                        (isSmall ? textTheme.labelMedium : textTheme.labelLarge)
                            ?.copyWith(
                              color: option.value == value
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];

    final track = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: isSmall ? MainAxisSize.max : MainAxisSize.min,
        children: isSmall
            ? [for (final child in segmentChildren) Expanded(child: child)]
            : [
                for (final child in segmentChildren)
                  if (wideSegmentWidth != null)
                    SizedBox(width: wideSegmentWidth, child: child)
                  else
                    child,
              ],
      ),
    );

    if (isSmall) return track;
    return Align(alignment: Alignment.centerLeft, child: track);
  }
}

class _RoundedSegmentedControlOption<T> {
  const _RoundedSegmentedControlOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}
