import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/sales_drill_down_controller.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

class SalesDrillDownPage extends ConsumerStatefulWidget {
  const SalesDrillDownPage({super.key, required this.args});

  final SalesDrillDownRouteArgs args;

  @override
  ConsumerState<SalesDrillDownPage> createState() => _SalesDrillDownPageState();
}

class _SalesDrillDownPageState extends ConsumerState<SalesDrillDownPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(salesDrillDownControllerProvider.notifier)
          .initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesDrillDownControllerProvider);
    final controller = ref.read(salesDrillDownControllerProvider.notifier);
    final report = state.report;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        title: const Text('Sales Details'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ReportingSectionCard(
              title: 'Drill-down Filters',
              subtitle: 'Detail list filters for the current sales scope.',
              child: DropdownButtonFormField<SalesDrillDownStatusFilter>(
                initialValue: state.statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: SalesDrillDownStatusFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_statusFilterLabel(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  controller.setStatusFilter(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && report == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.errorMessage != null && report == null)
              ReportingSectionCard(
                title: 'Sales Details',
                subtitle: state.errorCode,
                child: ReportingMessageStateView(
                  icon: Icons.error_outline,
                  title: 'Unable to load drill-down list',
                  message: state.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: controller.refresh,
                ),
              )
            else if (report == null || report.items.isEmpty)
              ReportingSectionCard(
                title: 'Sales Details',
                child: ReportingMessageStateView(
                  icon: Icons.list_alt_outlined,
                  title: 'No sales found',
                  message:
                      'No records matched the current status filter for the selected reporting scope.',
                ),
              )
            else ...[
              ReportingSectionCard(
                title: 'Scope',
                child: Text(formatReportScopeSummary(report.scope)),
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null) ...[
                _InlineWarning(
                  message: state.errorCode == null
                      ? state.errorMessage!
                      : '${state.errorMessage!} (${state.errorCode})',
                ),
                const SizedBox(height: 16),
              ],
              for (final item in report.items) ...[
                _SalesRecordCard(item: item),
                const SizedBox(height: 12),
              ],
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (report.hasMore)
                OutlinedButton.icon(
                  onPressed: controller.loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalesRecordCard extends StatelessWidget {
  const _SalesRecordCard({required this.item});

  final SalesDrillDownItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.saleId,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatSalesTypeLabel(item.saleType)} • ${formatSalesPaymentMethodLabel(item.paymentMethod)} • ${formatSalesRecordStatusLabel(item.status)}',
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatUsdAmount(item.grandTotalUsd),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatKhrAmountLabel(item.grandTotalKhr),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Items',
                  value: formatInteger(item.totalItems),
                ),
                _MetricChip(label: 'VAT', value: formatUsdAmount(item.vatUsd)),
                _MetricChip(
                  label: 'Discount',
                  value: formatUsdAmount(item.discountUsd),
                ),
                _MetricChip(
                  label: 'Finalized',
                  value: formatShortDateTime(item.finalizedAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.grey.shade100,
      ),
      child: Text('$label: $value'),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _statusFilterLabel(SalesDrillDownStatusFilter value) {
  switch (value) {
    case SalesDrillDownStatusFilter.all:
      return 'All';
    case SalesDrillDownStatusFilter.finalized:
      return 'Finalized';
    case SalesDrillDownStatusFilter.voidPending:
      return 'Void pending';
    case SalesDrillDownStatusFilter.voided:
      return 'Voided';
  }
}
