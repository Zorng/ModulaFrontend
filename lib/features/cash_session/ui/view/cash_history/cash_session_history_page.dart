import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_card.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_date_picker_row.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/z_report_viewmodel.dart';

class CashSessionHistoryPage extends ConsumerWidget {
  const CashSessionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zReportProvider);
    final notifier = ref.read(zReportProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Review closed session summaries for the selected date.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ZReportDatePickerRow(
              date: state.date,
              onPick: (value) => notifier.setDate(value),
            ),
            const SizedBox(height: 12),
            ZReportCard(
              state: state,
              onGenerate: notifier.generate,
              onReload: notifier.generate,
              canReload: notifier.canReload,
            ),
          ],
        ),
      ),
    );
  }
}
