import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
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
    final isSmall = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: isSmall
                  ? AppBackButton(
                      icon: Icons.home_outlined,
                      tooltip: 'Home',
                      onPressed: () => context.go(AppRoute.portal.path),
                    )
                  : null,
              title: const Align(
                alignment: Alignment.centerLeft,
                child: Text('X Report'),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAdmin) ...[
                XReportFilterRow(filters: filters),
                const SizedBox(height: 12),
              ],
              if (cashState.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: entriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        'Unable to load X reports.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Center(
                          child: Text(
                            'No X reports available for this selection.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
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
      ),
    );
  }
}
