import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/current_session_summary_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/reporting/domain/models/x_report.dart';

class CurrentSessionSummaryCard extends ConsumerWidget {
  const CurrentSessionSummaryCard({super.key, this.stretchPlaceholder = false});

  final bool stretchPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final summaryAsync = ref.watch(currentSessionSummaryProvider);
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Live totals for the active cash session.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (sessionState.sessionStatus != SessionStatus.open)
              if (stretchPlaceholder)
                const Expanded(
                  child: _SummaryEmptyState(
                    message:
                        'No active session yet. Summary becomes available after a session is opened.',
                    expandToFill: true,
                  ),
                )
              else
                const _SummaryEmptyState(
                  message:
                      'No active session yet. Summary becomes available after a session is opened.',
                )
            else
              summaryAsync.when(
                data: (summary) {
                  if (summary == null) {
                    return const _SummaryEmptyState(
                      message: 'Summary is unavailable for this session.',
                    );
                  }
                  return _SummaryMetricGrid(summary: summary);
                },
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const _SummaryEmptyState(
                  message: 'Current session summary is unavailable right now.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricGrid extends StatelessWidget {
  const _SummaryMetricGrid({required this.summary});

  final XReportDetail summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData.dual(
        label: 'Opening Float',
        usdValue: _formatUsd(summary.openingFloatUsd),
        khrValue: _formatKhr(summary.openingFloatKhr),
      ),
      _MetricData.dual(
        label: 'Expected Cash',
        usdValue: _formatUsd(summary.expectedCashUsd),
        khrValue: _formatKhr(summary.expectedCashKhr),
        emphasized: true,
      ),
      _MetricData.dual(
        label: 'KHQR Sales',
        usdValue: _formatUsd(summary.totalSalesKhqrUsd),
        khrValue: _formatKhr(summary.totalSalesKhqrKhr),
      ),
      _MetricData.dual(
        label: 'Cash Sales',
        usdValue: _formatUsd(summary.totalSalesCashUsd),
        khrValue: _formatKhr(summary.totalSalesCashKhr),
      ),
      _MetricData.dual(
        label: 'Paid In',
        usdValue: _formatUsd(summary.totalPaidInUsd),
        khrValue: _formatKhr(summary.totalPaidInKhr),
      ),
      _MetricData.dual(
        label: 'Paid Out',
        usdValue: _formatUsd(summary.totalPaidOutUsd),
        khrValue: _formatKhr(summary.totalPaidOutKhr),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 300;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }

  static String _formatUsd(double value) =>
      NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(value);

  static String _formatKhr(double value) => NumberFormat.currency(
    symbol: '៛',
    decimalDigits: 0,
    customPattern: '#,##0 ¤',
  ).format(value);
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final accent = metric.emphasized
        ? const Color(0xFFFEF3F2)
        : const Color(0xFFF8FAFC);
    final border = metric.emphasized
        ? const Color(0xFFFECACA)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.black54,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.usdValue,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            metric.khrValue,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 12.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData.dual({
    required this.label,
    required this.usdValue,
    required this.khrValue,
    this.emphasized = false,
  });

  final String label;
  final String usdValue;
  final String khrValue;
  final bool emphasized;
}

class _SummaryEmptyState extends StatelessWidget {
  const _SummaryEmptyState({required this.message, this.expandToFill = false});

  final String message;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: expandToFill ? 0 : 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
