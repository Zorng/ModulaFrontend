import 'package:flutter/material.dart';

class StaffDetailInfoRow extends StatelessWidget {
  const StaffDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // If valueWidget, just place it naturally — no Expanded
              if (valueWidget != null)
                valueWidget!
              else
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: value == '-' || value == '—'
                          ? Colors.grey.shade400
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}
