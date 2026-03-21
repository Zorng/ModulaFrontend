import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_card.dart';

class DiscountFormScheduleSection extends StatelessWidget {
  const DiscountFormScheduleSection({
    super.key,
    required this.startLabel,
    required this.endLabel,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearStart,
    required this.onClearEnd,
    required this.enabled,
  });

  final String startLabel;
  final String endLabel;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback? onClearStart;
  final VoidCallback? onClearEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DiscountFormCard(
      title: 'Schedule',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth >= 720;
          final startField = _DateTimeField(
            label: 'Start time',
            value: startLabel,
            onPick: onPickStart,
            onClear: onClearStart,
            enabled: enabled,
          );
          final endField = _DateTimeField(
            label: 'End time',
            value: endLabel,
            onPick: onPickEnd,
            onClear: onClearEnd,
            enabled: enabled,
          );

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: startField),
                const SizedBox(width: 16),
                Expanded(child: endField),
              ],
            );
          }

          return Column(
            children: [startField, const SizedBox(height: 12), endField],
          );
        },
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.enabled,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPick : null,
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onClear != null)
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: enabled ? onClear : null,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: enabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
