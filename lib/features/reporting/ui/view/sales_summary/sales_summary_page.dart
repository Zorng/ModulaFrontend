import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/sales_summary_controller.dart';
import 'package:modular_pos/features/reporting/ui/widgets/charts/reporting_bar_chart.dart';
import 'package:modular_pos/features/reporting/ui/widgets/charts/reporting_donut_chart.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_stat_card.dart';

class SalesSummaryPage extends ConsumerStatefulWidget {
  const SalesSummaryPage({super.key});

  @override
  ConsumerState<SalesSummaryPage> createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends ConsumerState<SalesSummaryPage> {
  static const _palette = <Color>[
    Color(0xFF0F766E),
    Color(0xFFD97706),
    Color(0xFF1D4ED8),
    Color(0xFFBE123C),
    Color(0xFF7C3AED),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(salesSummaryControllerProvider);
      if (state.report == null && !state.isLoading) {
        ref.read(salesSummaryControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesSummaryControllerProvider);
    final controller = ref.read(salesSummaryControllerProvider.notifier);
    final access = ref.watch(reportingAccessContextProvider);
    final report = state.report;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildFilterSection(context, state, access),
          const SizedBox(height: 16),
          if (state.isLoading && report == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null && report == null)
            ReportingSectionCard(
              title: 'Sales Reporting',
              subtitle: state.errorCode,
              child: ReportingMessageStateView(
                icon: Icons.error_outline,
                title: 'Unable to load sales summary',
                message: state.errorMessage!,
                actionLabel: 'Retry',
                onAction: controller.load,
              ),
            )
          else if (report == null)
            ReportingSectionCard(
              title: 'Sales Reporting',
              child: ReportingMessageStateView(
                icon: Icons.insert_chart_outlined,
                title: 'No sales summary loaded',
                message: 'Use the filters above to load the sales summary.',
                actionLabel: 'Load',
                onAction: controller.load,
              ),
            )
          else ...[
            _buildScopeBanner(context, report.scope),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildInlineWarning(
                context,
                state.errorMessage!,
                state.errorCode,
              ),
            ],
            const SizedBox(height: 16),
            _buildKpiGrid(context, report),
            const SizedBox(height: 16),
            ReportingSectionCard(
              title: 'Payment Breakdown',
              subtitle: 'Confirmed totals by payment method',
              child: ReportingDonutChart(
                segments: report.paymentBreakdown
                    .asMap()
                    .entries
                    .map((entry) {
                      final item = entry.value;
                      return ReportingDonutChartSegment(
                        label: formatSalesPaymentMethodLabel(
                          item.paymentMethod,
                        ),
                        value: item.totalUsd,
                        color: _palette[entry.key % _palette.length],
                        legendValue: formatUsdAmount(item.totalUsd),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            ReportingSectionCard(
              title: 'Cash Tender Breakdown',
              subtitle: 'Cash transactions split by tender currency',
              child: ReportingBarChart(
                items: report.cashTenderBreakdown
                    .asMap()
                    .entries
                    .map((entry) {
                      final item = entry.value;
                      return ReportingBarChartItem(
                        label: formatSalesTenderCurrencyLabel(
                          item.tenderCurrency,
                        ),
                        value: item.totalTenderAmount,
                        color: _palette[entry.key % _palette.length],
                        legendValue:
                            item.tenderCurrency == SalesTenderCurrency.khr
                            ? formatKhrAmountLabel(item.totalTenderAmount)
                            : formatUsdAmount(item.totalTenderAmount),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            ReportingSectionCard(
              title: 'Sale Type Breakdown',
              subtitle: 'Confirmed totals by order type',
              child: ReportingBarChart(
                items: report.saleTypeBreakdown
                    .asMap()
                    .entries
                    .map((entry) {
                      final item = entry.value;
                      return ReportingBarChartItem(
                        label: formatSalesTypeLabel(item.saleType),
                        value: item.totalUsd,
                        color: _palette[entry.key % _palette.length],
                        legendValue: '${item.transactionCount} tx',
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            ReportingSectionCard(
              title: 'Top Items',
              subtitle: 'Highest-selling menu items in the selected scope',
              child: Column(
                children: [
                  for (final item in report.topItems)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${report.topItems.indexOf(item) + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(item.itemNameSnapshot),
                      subtitle: Text(
                        '${formatInteger(item.quantity)} items sold',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatUsdAmount(item.revenueUsd),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            formatKhrAmountLabel(item.revenueKhr),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ReportingSectionCard(
              title: 'Category Breakdown',
              subtitle: 'Revenue contribution by item category',
              child: ReportingBarChart(
                items: report.categoryBreakdown
                    .asMap()
                    .entries
                    .map((entry) {
                      final item = entry.value;
                      return ReportingBarChartItem(
                        label: item.categoryNameSnapshot,
                        value: item.revenueUsd,
                        color: _palette[entry.key % _palette.length],
                        legendValue: formatUsdAmount(item.revenueUsd),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            ReportingSectionCard(
              title: 'Exceptions',
              subtitle:
                  'Visible void-related exceptions outside confirmed totals',
              action: FilledButton.icon(
                onPressed: access == null
                    ? null
                    : () => context.push(
                        AppRoute.reportingSalesDrillDown.path,
                        extra: SalesDrillDownRouteArgs(
                          scope: state.toScopeQuery(
                            fallbackBranchId: access.fallbackBranchId,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('View details'),
              ),
              child: Column(
                children: [
                  ReportingStatCard(
                    label: 'Void pending',
                    value: formatInteger(report.exceptions.voidPending.count),
                    subtitle:
                        '${formatUsdAmount(report.exceptions.voidPending.totalUsd)} • ${formatKhrAmountLabel(report.exceptions.voidPending.totalKhr)}',
                    accentColor: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 12),
                  ReportingStatCard(
                    label: 'Voided',
                    value: formatInteger(report.exceptions.voided.count),
                    subtitle:
                        '${formatUsdAmount(report.exceptions.voided.totalUsd)} • ${formatKhrAmountLabel(report.exceptions.voided.totalKhr)}',
                    accentColor: Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    SalesSummaryState state,
    ReportingAccessContext? access,
  ) {
    final controller = ref.read(salesSummaryControllerProvider.notifier);

    return ReportingSectionCard(
      title: 'Sales Filters',
      subtitle: 'This page owns its own scope and time filters.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<ReportTimeWindow>(
                  initialValue: state.window,
                  decoration: const InputDecoration(
                    labelText: 'Window',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportTimeWindow.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(formatReportWindowLabel(value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    controller.setWindow(value);
                  },
                ),
              ),
              if (state.canUseAllBranches)
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<ReportBranchScope>(
                    initialValue: state.branchScope,
                    decoration: const InputDecoration(
                      labelText: 'Branch scope',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReportBranchScope.branch,
                        child: Text('Branch'),
                      ),
                      DropdownMenuItem(
                        value: ReportBranchScope.allBranches,
                        child: Text('All branches'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      controller.setBranchScope(value);
                    },
                  ),
                ),
              if (state.branchScope == ReportBranchScope.branch)
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: state.branchId,
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      border: OutlineInputBorder(),
                    ),
                    items: state.branches
                        .map(
                          (branch) => DropdownMenuItem(
                            value: branch.id,
                            child: Text(branch.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => controller.setBranchId(value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickDateRange(context),
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              state.window == ReportTimeWindow.custom
                  ? formatReportDateRange(state.selectedDateRange)
                  : 'Pick custom range',
            ),
          ),
          if (access != null && !access.canUseAllBranches) ...[
            const SizedBox(height: 12),
            Text(
              'Manager scope is locked to the current branch.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScopeBanner(BuildContext context, ReportScope scope) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatReportScopeSummary(scope),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineWarning(
    BuildContext context,
    String message,
    String? code,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(child: Text(code == null ? message : '$message ($code)')),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, SalesSummaryReport report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980
            ? 4
            : width >= 640
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 3.2 : 1.45,
          children: [
            ReportingStatCard(
              label: 'Revenue',
              value: formatUsdCompact(report.confirmed.totalGrandUsd),
              subtitle: formatKhrAmountLabel(report.confirmed.totalGrandKhr),
              accentColor: const Color(0xFF0F766E),
            ),
            ReportingStatCard(
              label: 'Transactions',
              value: formatInteger(report.confirmed.transactionCount),
              subtitle: 'Finalized sales only',
              accentColor: const Color(0xFF1D4ED8),
            ),
            ReportingStatCard(
              label: 'Avg ticket',
              value: formatUsdAmount(report.confirmed.averageTicketUsd ?? 0),
              subtitle: report.confirmed.averageTicketKhr == null
                  ? 'KHR unavailable'
                  : formatKhrAmountLabel(report.confirmed.averageTicketKhr!),
              accentColor: const Color(0xFFD97706),
            ),
            ReportingStatCard(
              label: 'Items sold',
              value: formatInteger(report.confirmed.totalItemsSold),
              subtitle:
                  '${formatUsdAmount(report.confirmed.totalDiscountUsd)} discount',
              accentColor: const Color(0xFFBE123C),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final state = ref.read(salesSummaryControllerProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange: state.selectedDateRange,
      helpText: 'Select custom range',
      saveText: 'Apply',
    );
    if (picked == null) return;
    await ref
        .read(salesSummaryControllerProvider.notifier)
        .setDateRange(picked);
  }
}
