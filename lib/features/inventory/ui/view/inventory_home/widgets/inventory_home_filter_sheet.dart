import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_branch_option.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/inventory_home_filter_models.dart';

Future<InventoryHomeFilterDraft?> showInventoryHomeFilterModal(
  BuildContext context, {
  required List<InventoryBranchOption> branchOptions,
  required List<DropdownMenuEntry<String>> categoryEntries,
  required InventoryHomeFilterDraft initialDraft,
}) {
  final isSmallScreen = AppBreakpoints.isSmall(
    MediaQuery.sizeOf(context).width,
  );
  if (isSmallScreen) {
    return Navigator.of(context).push<InventoryHomeFilterDraft>(
      MaterialPageRoute<InventoryHomeFilterDraft>(
        fullscreenDialog: true,
        builder: (context) => _InventoryHomeFilterMobileScaffold(
          child: InventoryHomeFilterSheet(
            branchOptions: branchOptions,
            categoryEntries: categoryEntries,
            initialDraft: initialDraft,
          ),
        ),
      ),
    );
  }

  return showDialog<InventoryHomeFilterDraft>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: InventoryHomeFilterSheet(
            branchOptions: branchOptions,
            categoryEntries: categoryEntries,
            initialDraft: initialDraft,
          ),
        ),
      ),
    ),
  );
}

class InventoryHomeFilterSheet extends StatefulWidget {
  const InventoryHomeFilterSheet({
    super.key,
    required this.branchOptions,
    required this.categoryEntries,
    required this.initialDraft,
  });

  final List<InventoryBranchOption> branchOptions;
  final List<DropdownMenuEntry<String>> categoryEntries;
  final InventoryHomeFilterDraft initialDraft;

  @override
  State<InventoryHomeFilterSheet> createState() =>
      _InventoryHomeFilterSheetState();
}

class _InventoryHomeFilterSheetState extends State<InventoryHomeFilterSheet> {
  late String _categoryId;
  late String _branchId;
  late InventoryHomeStockStatusFilter _stockStatus;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialDraft.categoryId;
    _branchId = widget.initialDraft.branchId;
    _stockStatus = widget.initialDraft.stockStatus;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.sizeOf(context).width,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Filter inventory',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!isSmallScreen)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _appliedFilterSummaryLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
              TextButton(
                onPressed: _appliedFilterCount == 0 ? null : _clearFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Clear filters'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Branch',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<String>(
            value: _branchId,
            entries: widget.branchOptions
                .map(
                  (entry) => DropdownMenuEntry<String>(
                    value: entry.id,
                    label: entry.name,
                  ),
                )
                .toList(growable: false),
            onSelected: (value) => setState(() => _branchId = value ?? 'all'),
          ),
          const SizedBox(height: 16),
          Text(
            'Category',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<String>(
            value: _categoryId,
            entries: widget.categoryEntries,
            onSelected: (value) => setState(() => _categoryId = value ?? 'all'),
          ),
          const SizedBox(height: 16),
          Text(
            'Status',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<InventoryHomeStockStatusFilter>(
            value: _stockStatus,
            entries: InventoryHomeStockStatusFilter.values
                .map(
                  (filter) => DropdownMenuEntry(
                    value: filter,
                    label: inventoryHomeStockStatusFilterLabel(filter),
                  ),
                )
                .toList(growable: false),
            onSelected: (value) => setState(
              () => _stockStatus = value ?? InventoryHomeStockStatusFilter.all,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: AppTheme.cancelActionButtonStyle,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int get _appliedFilterCount {
    var count = 0;
    if (_categoryId != 'all') count += 1;
    if (_stockStatus != InventoryHomeStockStatusFilter.all) count += 1;
    if (_branchId != 'all') count += 1;
    return count;
  }

  String get _appliedFilterSummaryLabel {
    final count = _appliedFilterCount;
    return count == 1 ? '1 filter applied' : '$count filters applied';
  }

  void _clearFilters() {
    setState(() {
      _categoryId = 'all';
      _branchId = 'all';
      _stockStatus = InventoryHomeStockStatusFilter.all;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      InventoryHomeFilterDraft(
        categoryId: _categoryId,
        branchId: _branchId,
        stockStatus: _stockStatus,
      ),
    );
  }
}

class _DialogDropdown<T> extends StatelessWidget {
  const _DialogDropdown({
    required this.value,
    required this.entries,
    required this.onSelected,
  });

  final T value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxMenuHeight = _filterOverlayMaxHeight(context);
        return DropdownMenu<T>(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          menuHeight: maxMenuHeight,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          ),
          initialSelection: value,
          dropdownMenuEntries: entries,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _InventoryHomeFilterMobileScaffold extends StatelessWidget {
  const _InventoryHomeFilterMobileScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            top: 8,
            right: 16,
            bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

double _filterOverlayMaxHeight(BuildContext context) {
  final viewportHeight = MediaQuery.sizeOf(context).height;
  return math.min(220, math.max(160, viewportHeight * 0.28)).toDouble();
}
