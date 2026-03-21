import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/z_report_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_card.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_date_picker_row.dart';

class ZReportPage extends ConsumerWidget {
  const ZReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zReportProvider);
    final notifier = ref.read(zReportProvider.notifier);
    final isSmall = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isSmall
            ? AppBackButton(
                icon: Icons.home_outlined,
                tooltip: 'Home',
                onPressed: () => context.go(AppRoute.branchPortal.path),
              )
            : null,
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
