import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/layout/bounded_content_frame.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/widgets/x_report_filter_row.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/widgets/x_report_card.dart';

class XReportPage extends ConsumerWidget {
  const XReportPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(loginControllerProvider).user;
    final role = user?.role.trim().toLowerCase() ?? '';
    final isAdmin = role == 'admin';
    final cashState = ref.watch(cashSessionViewModelProvider);
    final entriesAsync = ref.watch(xReportEntriesProvider);
    final filters = ref.watch(xReportFiltersProvider);

    final content = SafeArea(
      child: BoundedContentFrame(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin) ...[
              XReportFilterRow(filters: filters),
              const SizedBox(height: 12),
            ],
            if (cashState.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: entriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Unable to load session summaries.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'No session summaries available for this selection.',
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return XReportCard(entry: entries[index]);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    if (!showAppBar) {
      return content;
    }

    return BranchWorkspaceScaffold(title: 'Session Summaries', body: content);
  }
}
