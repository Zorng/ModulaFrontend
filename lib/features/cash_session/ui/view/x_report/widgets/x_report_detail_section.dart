import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/x_report_utils.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/widgets/x_report_detail_row.dart';

class XReportDetailSection extends ConsumerWidget {
  const XReportDetailSection({super.key, required this.entry});

  final XReportEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(xReportDetailProvider(entry));

    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Unable to load report details.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Text(
            'No detail available.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final rows = [
          XReportDetailRow(
            label: 'Opening float (USD)',
            value: xReportFormatMoney(detail.openingFloatUsd, 'USD'),
          ),
          XReportDetailRow(
            label: 'Opening float (KHR)',
            value: xReportFormatMoney(detail.openingFloatKhr, 'KHR'),
          ),
          XReportDetailRow(
            label: 'Sales cash (USD)',
            value: xReportFormatMoney(detail.totalSalesCashUsd, 'USD'),
          ),
          XReportDetailRow(
            label: 'Sales cash (KHR)',
            value: xReportFormatMoney(detail.totalSalesCashKhr, 'KHR'),
          ),
          XReportDetailRow(
            label: 'Paid in (USD)',
            value: xReportFormatMoney(detail.totalPaidInUsd, 'USD'),
          ),
          XReportDetailRow(
            label: 'Paid in (KHR)',
            value: xReportFormatMoney(detail.totalPaidInKhr, 'KHR'),
          ),
          XReportDetailRow(
            label: 'Paid out (USD)',
            value: xReportFormatMoney(detail.totalPaidOutUsd, 'USD'),
          ),
          XReportDetailRow(
            label: 'Paid out (KHR)',
            value: xReportFormatMoney(detail.totalPaidOutKhr, 'KHR'),
          ),
          XReportDetailRow(
            label: 'Expected cash (USD)',
            value: xReportFormatMoney(detail.expectedCashUsd, 'USD'),
          ),
          XReportDetailRow(
            label: 'Expected cash (KHR)',
            value: xReportFormatMoney(detail.expectedCashKhr, 'KHR'),
          ),
        ];
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

