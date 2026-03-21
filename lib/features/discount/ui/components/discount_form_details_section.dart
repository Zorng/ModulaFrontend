import 'package:flutter/material.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_card.dart';

class DiscountFormDetailsSection extends StatelessWidget {
  const DiscountFormDetailsSection({
    super.key,
    required this.nameController,
    required this.percentageController,
    required this.scope,
    required this.selectedBranchId,
    required this.selectedBranchName,
    required this.availableBranches,
    required this.isEditMode,
    required this.isSaving,
    required this.isReadOnly,
    required this.onBranchChanged,
    required this.onScopeChanged,
    required this.onNameChanged,
    required this.onPercentageChanged,
  });

  final TextEditingController nameController;
  final TextEditingController percentageController;
  final String scope;
  final String selectedBranchId;
  final String selectedBranchName;
  final List<BranchListItem> availableBranches;
  final bool isEditMode;
  final bool isSaving;
  final bool isReadOnly;
  final ValueChanged<String> onBranchChanged;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPercentageChanged;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isSaving && !isReadOnly;
    final dropdownTextStyle = Theme.of(context).textTheme.bodyMedium;
    return DiscountFormCard(
      title: 'Rule details',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth >= 720;
          final nameField = _FieldLabel(
            label: 'Discount name',
            child: TextFormField(
              controller: nameController,
              onChanged: onNameChanged,
              readOnly: isReadOnly,
              decoration: const InputDecoration(
                hintText: 'Morning Coffee 10%',
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter a discount name.';
                }
                return null;
              },
            ),
          );
          final percentageField = _FieldLabel(
            label: 'Percentage',
            child: TextFormField(
              controller: percentageController,
              onChanged: onPercentageChanged,
              readOnly: isReadOnly,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '10',
                suffixText: '%',
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Enter a valid percentage.';
                if (parsed <= 0 || parsed > 100) {
                  return 'Percentage must be between 0 and 100.';
                }
                return null;
              },
            ),
          );

          final scopeField = _FieldLabel(
            label: 'Scope',
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>('scope-$scope'),
              initialValue: scope,
              style: dropdownTextStyle,
              dropdownColor: Colors.white,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: DiscountScopes.item,
                  child: Text('Item-level'),
                ),
                DropdownMenuItem(
                  value: DiscountScopes.branchWide,
                  child: Text('Branch-wide'),
                ),
              ],
              onChanged: isEnabled
                  ? (value) {
                      if (value != null) onScopeChanged(value);
                    }
                  : null,
            ),
          );

          final branchField = _FieldLabel(
            label: isEditMode ? 'Assigned branch' : 'Assign branch',
            helperText: isEditMode
                ? 'Branch assignment is immutable after creation.'
                : 'Each discount rule must be assigned to one branch.',
            child: isEditMode
                ? TextFormField(
                    initialValue: selectedBranchName,
                    readOnly: true,
                    style: dropdownTextStyle,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  )
                : DropdownButtonFormField<String>(
                    key: ValueKey<String>('branch-$selectedBranchId'),
                    initialValue: selectedBranchId.isEmpty
                        ? null
                        : selectedBranchId,
                    style: dropdownTextStyle,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: availableBranches
                        .map(
                          (branch) => DropdownMenuItem<String>(
                            value: branch.branchId,
                            child: Text(
                              branch.branchName,
                              style: dropdownTextStyle,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isEnabled
                        ? (value) {
                            if (value != null) {
                              onBranchChanged(value);
                            }
                          }
                        : null,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Select one branch.';
                      }
                      return null;
                    },
                  ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useTwoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: nameField),
                    const SizedBox(width: 16),
                    Expanded(child: percentageField),
                  ],
                )
              else ...[
                nameField,
                const SizedBox(height: 16),
                percentageField,
              ],
              const SizedBox(height: 16),
              if (useTwoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: scopeField),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: branchField),
                  ],
                )
              else ...[
                scopeField,
                const SizedBox(height: 16),
                branchField,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
    this.helperText,
  });

  final String label;
  final Widget child;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 10),
        child,
        if ((helperText ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
