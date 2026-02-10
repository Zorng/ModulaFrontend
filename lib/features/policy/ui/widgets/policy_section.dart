import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/models/policy_models.dart';

typedef PolicyItemTap = void Function(PolicyItem item, dynamic value);

class PolicySection extends StatelessWidget {
  const PolicySection({
    super.key,
    required this.title,
    required this.items,
    required this.isCompact,
    required this.toggleValues,
    required this.selectorValues,
    required this.onItemTap,
    this.readOnly = false,
  });

  final String title;
  final List<PolicyItem> items;
  final bool isCompact;
  final Map<String, bool> toggleValues;
  final Map<String, String> selectorValues;
  final bool readOnly;
  final PolicyItemTap onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                PolicyTile(
                  item: items[i],
                  isCompact: isCompact,
                  value: items[i].type == PolicyItemType.toggle
                      ? (toggleValues[items[i].id] ?? false)
                      : selectorValues[items[i].id] ??
                            items[i].defaultValue ??
                            '',
                  displayValue: _displayValueForItem(items[i]),
                  readOnly: readOnly,
                  showDivider: i != items.length - 1,
                  onTap: () => onItemTap(
                    items[i],
                    items[i].type == PolicyItemType.toggle
                        ? (toggleValues[items[i].id] ?? false)
                        : selectorValues[items[i].id] ??
                              items[i].defaultValue ??
                              '',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _displayValueForItem(PolicyItem item) {
    if (item.id == 'apply_vat') {
      final enabled = toggleValues[item.id] ?? false;
      final rate = selectorValues['vat_rate'] ?? item.defaultValue ?? '';
      return enabled ? 'On ($rate)' : 'Off';
    }
    if (item.type == PolicyItemType.selector) {
      return selectorValues[item.id] ?? item.defaultValue ?? '';
    }
    if (item.type == PolicyItemType.info) {
      return item.subtitle ?? 'Coming soon';
    }
    return null;
  }
}

class PolicyTile extends StatelessWidget {
  const PolicyTile({
    super.key,
    required this.item,
    required this.value,
    required this.isCompact,
    required this.showDivider,
    required this.onTap,
    this.displayValue,
    this.readOnly = false,
  });

  final PolicyItem item;
  final dynamic value;
  final bool readOnly;
  final bool isCompact;
  final bool showDivider;
  final VoidCallback? onTap;
  final String? displayValue;

  String get _valueLabel {
    if (displayValue != null) return displayValue!;
    if (item.type == PolicyItemType.toggle) {
      return (value as bool? ?? false) ? 'On' : 'Off';
    }
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tilePadding = EdgeInsets.symmetric(
      horizontal: 16,
      vertical: isCompact ? 12 : 16,
    );

    final titleStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.type == PolicyItemType.info ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: tilePadding,
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.title, style: titleStyle)),
                  const SizedBox(width: 12),
                  if (item.type == PolicyItemType.toggle)
                    Text(
                      _valueLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: (value as bool? ?? false)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (item.type == PolicyItemType.selector)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _valueLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    )
                  else
                    Text(_valueLabel, style: subtitleStyle),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 48,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
