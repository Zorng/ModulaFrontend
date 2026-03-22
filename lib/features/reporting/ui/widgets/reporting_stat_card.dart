import 'package:flutter/material.dart';

class ReportingStatCard extends StatelessWidget {
  const ReportingStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.accentColor,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!)],
        ],
      ),
    );
  }
}
