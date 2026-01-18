import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/z_report_viewmodel.dart';

class ZReportPage extends ConsumerWidget {
  const ZReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zReportProvider);
    final notifier = ref.read(zReportProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Z Report'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DatePickerRow(
                date: state.date,
                onPick: (value) => notifier.setDate(value),
              ),
              const SizedBox(height: 12),
              _ZReportCard(
                state: state,
                onGenerate: notifier.generate,
                onReload: notifier.generate,
                canReload: notifier.canReload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({required this.date, required this.onPick});

  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            onPick(picked);
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(DateFormat('yyyy-MM-dd').format(date)),
        ),
      ],
    );
  }
}

class _ZReportCard extends StatelessWidget {
  const _ZReportCard({
    required this.state,
    required this.onGenerate,
    required this.onReload,
    required this.canReload,
  });

  final ZReportState state;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onReload;
  final bool canReload;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Z Report Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (summary != null)
                  IconButton(
                    tooltip: canReload ? 'Reload' : 'Rate limit reached',
                    onPressed: canReload ? onReload : null,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else if (summary == null)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onGenerate,
                      child: const Text('Generate Z report'),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      UserErrorMessage.build(
                        context: 'Failed to generate Z report',
                        error: state.error,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              )
            else
              Column(
                children: [
                  if (state.error != null) ...[
                    Text(
                      UserErrorMessage.build(
                        context: 'Failed to load Z report',
                        error: state.error,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _detailRow(
                    'Date',
                    DateFormat('yyyy-MM-dd').format(summary.date),
                  ),
                  _detailRow('Sessions', summary.sessionCount.toString()),
                  _detailRow(
                    'Opening float (USD)',
                    _formatMoney(summary.openingFloatUsd, 'USD'),
                  ),
                  _detailRow(
                    'Opening float (KHR)',
                    _formatMoney(summary.openingFloatKhr, 'KHR'),
                  ),
                  _detailRow(
                    'Sales cash (USD)',
                    _formatMoney(summary.totalSalesCashUsd, 'USD'),
                  ),
                  _detailRow(
                    'Sales cash (KHR)',
                    _formatMoney(summary.totalSalesCashKhr, 'KHR'),
                  ),
                  _detailRow(
                    'Paid in (USD)',
                    _formatMoney(summary.totalPaidInUsd, 'USD'),
                  ),
                  _detailRow(
                    'Paid in (KHR)',
                    _formatMoney(summary.totalPaidInKhr, 'KHR'),
                  ),
                  _detailRow(
                    'Paid out (USD)',
                    _formatMoney(summary.totalPaidOutUsd, 'USD'),
                  ),
                  _detailRow(
                    'Paid out (KHR)',
                    _formatMoney(summary.totalPaidOutKhr, 'KHR'),
                  ),
                  _detailRow(
                    'Expected cash (USD)',
                    _formatMoney(summary.expectedCashUsd, 'USD'),
                  ),
                  _detailRow(
                    'Expected cash (KHR)',
                    _formatMoney(summary.expectedCashKhr, 'KHR'),
                  ),
                ],
              ),
            if (!canReload && summary != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reload limit reached. Try again in a minute.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }
}
