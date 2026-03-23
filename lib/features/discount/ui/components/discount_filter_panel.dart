import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class DiscountFilterPanel extends StatelessWidget {
  const DiscountFilterPanel({
    super.key,
    required this.statusFilter,
    required this.scopeFilter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onScopeChanged,
    required this.isCompact,
    this.onAddPressed,
    this.showStatusFilter = true,
    this.showScopeFilter = true,
    this.searchHintText = 'Search discount rules',
  });

  final String statusFilter;
  final String scopeFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onScopeChanged;
  final bool isCompact;
  final Future<void> Function()? onAddPressed;
  final bool showStatusFilter;
  final bool showScopeFilter;
  final String searchHintText;

  static const _statusOptions = <_DiscountFilterOption>[
    _DiscountFilterOption('ALL', 'All statuses'),
    _DiscountFilterOption('ACTIVE', 'Active'),
    _DiscountFilterOption('INACTIVE', 'Inactive'),
    _DiscountFilterOption('ARCHIVED', 'Archived'),
  ];

  static const _scopeOptions = <_DiscountFilterOption>[
    _DiscountFilterOption('ALL', 'All scopes'),
    _DiscountFilterOption('ITEM', 'Item-level'),
    _DiscountFilterOption('BRANCH_WIDE', 'Branch-wide'),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    if (isCompact) {
      return _buildCompactLayout(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _buildExpandedLayout(context),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                controller: searchController,
                hintText: searchHintText,
                onChanged: onSearchChanged,
                fillColor: Colors.white,
              ),
            ),
            if (onAddPressed != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: AppAddNewButton(
                  label: 'Add discount',
                  onPressed: () => onAddPressed!(),
                ),
              ),
            ],
          ],
        ),
        if (showStatusFilter || showScopeFilter) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (showStatusFilter)
                Expanded(
                  child: InventoryDropdown<String>(
                    initialValue: statusFilter,
                    entries: _statusOptions
                        .map(
                          (option) => DropdownMenuEntry<String>(
                            value: option.value,
                            label: option.label,
                          ),
                        )
                        .toList(),
                    onSelected: (value) => onStatusChanged(value ?? 'ALL'),
                    hintText: 'All statuses',
                  ),
                ),
              if (showStatusFilter && showScopeFilter) const SizedBox(width: 8),
              if (showScopeFilter)
                Expanded(
                  child: InventoryDropdown<String>(
                    initialValue: scopeFilter,
                    entries: _scopeOptions
                        .map(
                          (option) => DropdownMenuEntry<String>(
                            value: option.value,
                            label: option.label,
                          ),
                        )
                        .toList(),
                    onSelected: (value) => onScopeChanged(value ?? 'ALL'),
                    hintText: 'All scopes',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search and filter',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        AppSearchBar(
          controller: searchController,
          hintText: searchHintText,
          onChanged: onSearchChanged,
        ),
        if (showStatusFilter) ...[
          const SizedBox(height: 16),
          Text('Status', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                const [
                  _DiscountFilterChip(label: 'All', value: 'ALL'),
                  _DiscountFilterChip(label: 'Active', value: 'ACTIVE'),
                  _DiscountFilterChip(label: 'Inactive', value: 'INACTIVE'),
                  _DiscountFilterChip(label: 'Archived', value: 'ARCHIVED'),
                ].map((chip) {
                  return DiscountFilterChip(
                    label: chip.label,
                    value: chip.value,
                    groupValue: statusFilter,
                    onSelected: onStatusChanged,
                  );
                }).toList(),
          ),
        ],
        if (showScopeFilter) ...[
          const SizedBox(height: 16),
          Text('Scope', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                const [
                  _DiscountFilterChip(label: 'All', value: 'ALL'),
                  _DiscountFilterChip(label: 'Item-level', value: 'ITEM'),
                  _DiscountFilterChip(
                    label: 'Branch-wide',
                    value: 'BRANCH_WIDE',
                  ),
                ].map((chip) {
                  return DiscountFilterChip(
                    label: chip.label,
                    value: chip.value,
                    groupValue: scopeFilter,
                    onSelected: onScopeChanged,
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}

class DiscountFilterChip extends StatelessWidget {
  const DiscountFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: groupValue == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _DiscountFilterOption {
  const _DiscountFilterOption(this.value, this.label);

  final String value;
  final String label;
}

class _DiscountFilterChip {
  const _DiscountFilterChip({required this.label, required this.value});

  final String label;
  final String value;
}
