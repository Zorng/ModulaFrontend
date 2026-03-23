import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportingHorizontalBarChartItem {
  const ReportingHorizontalBarChartItem({
    required this.label,
    required this.value,
    required this.color,
    this.trailingValue,
  });

  final String label;
  final double value;
  final Color color;
  final String? trailingValue;
}

class ReportingHorizontalBarChart extends StatelessWidget {
  const ReportingHorizontalBarChart({
    super.key,
    required this.items,
    this.emptyText = 'No chart data available.',
    this.axisSteps = 0,
    this.minChartHeight = 220,
    this.chartHeightPerItem = 42,
  });

  final List<ReportingHorizontalBarChartItem> items;
  final String emptyText;
  final int axisSteps;
  final double minChartHeight;
  final double chartHeightPerItem;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((item) => item.value > 0);
    if (!hasData) {
      return Text(emptyText);
    }

    final maxItemValue = items.fold<double>(
      0,
      (current, item) => item.value > current ? item.value : current,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedAxisSteps = _resolveAxisSteps(constraints.maxWidth);
        final interval = _resolveAxisInterval(
          maxItemValue: maxItemValue,
          axisSteps: resolvedAxisSteps,
        );
        final maxAxisValue = math.max(1.0, interval * resolvedAxisSteps);
        final formatter = NumberFormat.decimalPattern();
        final theme = Theme.of(context);
        final axisColor = theme.dividerColor;
        final chartHeight = math.max(
          minChartHeight,
          (items.length * chartHeightPerItem) + 88,
        );

        return SizedBox(
          height: chartHeight,
          child: RotatedBox(
            quarterTurns: 1,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxAxisValue,
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: axisColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.symmetric(
                    horizontal: BorderSide(color: axisColor),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 140,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= items.length ||
                            value != index.toDouble()) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 12,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SizedBox(
                              width: 132,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: items[index].color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      items[index].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > maxAxisValue + 0.001) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              formatter.format(value.round()),
                              style: theme.textTheme.bodySmall,
                            ),
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
                          width: 18,
                          color: items[i].color,
                          borderRadius: BorderRadius.circular(999),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxAxisValue,
                            color: items[i].color.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _resolveAxisSteps(double width) {
    if (axisSteps > 0) {
      return axisSteps;
    }
    if (width >= 640) {
      return 6;
    }
    if (width >= 520) {
      return 5;
    }
    return 4;
  }

  double _resolveAxisInterval({
    required double maxItemValue,
    required int axisSteps,
  }) {
    if (maxItemValue <= 0) {
      return 1;
    }

    final rawInterval = maxItemValue / axisSteps;
    if (rawInterval <= 10) {
      return rawInterval.ceilToDouble();
    }

    final magnitude = math
        .pow(10, (math.log(rawInterval) / math.ln10).floor())
        .toDouble();
    final normalized = rawInterval / magnitude;

    if (normalized <= 1) {
      return magnitude;
    }
    if (normalized <= 2) {
      return 2 * magnitude;
    }
    if (normalized <= 4) {
      return 4 * magnitude;
    }
    if (normalized <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }
}
