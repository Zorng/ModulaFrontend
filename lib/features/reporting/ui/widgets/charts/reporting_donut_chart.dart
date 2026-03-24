import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReportingDonutChartSegment {
  const ReportingDonutChartSegment({
    required this.label,
    required this.value,
    required this.color,
    this.legendValue,
  });

  final String label;
  final double value;
  final Color color;
  final String? legendValue;
}

class ReportingDonutChart extends StatelessWidget {
  const ReportingDonutChart({
    super.key,
    required this.segments,
    this.emptyText = 'No chart data available.',
    this.showLegend = true,
  });

  final List<ReportingDonutChartSegment> segments;
  final String emptyText;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final hasData = segments.any((segment) => segment.value > 0);
    if (!hasData) {
      return Text(emptyText);
    }

    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 60,
              sectionsSpace: 4,
              
              sections: [
                for (final segment in segments)
                  PieChartSectionData(
                    color: segment.color,
                    value: segment.value,
                    radius: 36,
                    title: total <= 0
                        ? ''
                        : '${((segment.value / total) * 100).round()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final segment in segments)
                _LegendChip(
                  color: segment.color,
                  label: segment.label,
                  value: segment.legendValue,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
          if (value != null) ...[
            const SizedBox(width: 6),
            Text(
              value!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
