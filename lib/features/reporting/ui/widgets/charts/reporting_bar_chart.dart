import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportingBarChartItem {
  const ReportingBarChartItem({
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

class ReportingBarChart extends StatelessWidget {
  const ReportingBarChart({
    super.key,
    required this.items,
    this.emptyText = 'No chart data available.',
  });

  final List<ReportingBarChartItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((item) => item.value > 0);
    if (!hasData) {
      return Text(emptyText);
    }

    final maxValue = items.fold<double>(
      0,
      (current, item) => item.value > current ? item.value : current,
    );
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final leftAxisFormatter = NumberFormat.compact();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          leftAxisFormatter.format(value),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= items.length) {
                        return const SizedBox.shrink();
                      }
                      final label = items[index].label;
                      final compactLabel = label.length > 10
                          ? '${label.substring(0, 10)}…'
                          : label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          compactLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < items.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: items[i].value,
                        width: 22,
                        borderRadius: BorderRadius.circular(8),
                        color: items[i].color,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final item in items)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.label),
                    if (item.legendValue != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.legendValue!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
