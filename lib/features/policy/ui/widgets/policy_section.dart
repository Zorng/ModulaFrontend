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
    final cardColor = Theme.of(context).colorScheme.surface;
    final border = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
      width: 0.7,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.fromBorderSide(border),
              borderRadius: BorderRadius.circular(12),
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
      horizontal: 12,
      vertical: isCompact ? 8 : 12,
    );

    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: tilePadding,
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                item.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(item.title, style: titleStyle),
            subtitle: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _valueLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: readOnly ? null : onTap,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.7,
            indent: 12,
            endIndent: 12,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      ],
    );
  }
}
