import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/layout/bounded_content_frame.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/z_report_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_card.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_date_picker_row.dart';

class ZReportPage extends ConsumerWidget {
  const ZReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zReportProvider);
    final notifier = ref.read(zReportProvider.notifier);

    return BranchWorkspaceScaffold(
      title: 'Z Report',
      body: SafeArea(
        child: BoundedContentFrame(
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      ),
    );
  }
}
