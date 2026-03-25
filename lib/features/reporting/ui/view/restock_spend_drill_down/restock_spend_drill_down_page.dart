import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/restock_spend_drill_down_controller.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

class RestockSpendDrillDownPage extends ConsumerStatefulWidget {
  const RestockSpendDrillDownPage({super.key, required this.args});

  final RestockSpendDrillDownRouteArgs args;

  @override
  ConsumerState<RestockSpendDrillDownPage> createState() =>
      _RestockSpendDrillDownPageState();
}

class _RestockSpendDrillDownPageState
    extends ConsumerState<RestockSpendDrillDownPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchState = ref.read(branchControllerProvider);
      if (branchState.branches.isEmpty && !branchState.isLoading) {
        ref.read(branchControllerProvider.notifier).loadInitial();
      }
      ref
          .read(restockSpendDrillDownControllerProvider.notifier)
          .initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restockSpendDrillDownControllerProvider);
    final controller = ref.read(
      restockSpendDrillDownControllerProvider.notifier,
    );
    final items = state.report?.items ?? const <RestockSpendDrillDownItem>[];
    final access = ref.watch(reportingAccessContextProvider);
    final tenantBranches = ref.watch(
      branchControllerProvider.select((state) => state.branches),
    );
    final branchNames = <String, String>{
      for (final branch in tenantBranches) branch.branchId: branch.branchName,
      for (final branch in access?.branches ?? const []) branch.id: branch.name,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        title: const Text('Restock Details'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = constraints.maxWidth;
          final isCompact = pageWidth < 720;
          final horizontalPadding = pageWidth < 600 ? 16.0 : 20.0;
          final costFilter = InventoryDropdown<RestockSpendCostFilter>(
            initialValue: state.costFilter,
            entries: const [
              DropdownMenuEntry(
                value: RestockSpendCostFilter.all,
                label: 'All costs',
              ),
              DropdownMenuEntry(
                value: RestockSpendCostFilter.known,
                label: 'Known cost',
              ),
              DropdownMenuEntry(
                value: RestockSpendCostFilter.unknown,
                label: 'Unknown cost',
              ),
            ],
            onSelected: (value) async {
              if (value == null) return;
              await controller.setCostFilter(value);
            },
            leadingIcon: const Icon(Icons.tune_outlined, size: 18),
            fillColor: Colors.white,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              20,
            ),
            children: [
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RestockSpendDrillDownIntro(report: state.report),
                    const SizedBox(height: 16),
                    costFilter,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RestockSpendDrillDownIntro(report: state.report),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(width: 280, child: costFilter),
                  ],
                ),
              const SizedBox(height: 20),
              if (state.isLoading && state.report == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null && state.report == null)
                ReportingMessageStateView(
                  icon: Icons.inventory_2_outlined,
                  title: 'Restock details unavailable',
                  message: state.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: controller.refresh,
                )
              else if (items.isEmpty)
                const ReportingMessageStateView(
                  icon: Icons.inventory_2_outlined,
                  title: 'No restock records',
                  message: 'No restock entries match the current filters.',
                )
              else ...[
                for (var i = 0; i < items.length; i++) ...[
                  _RestockSpendRecordCard(
                    item: items[i],
                    branchName: _resolveBranchName(items[i], branchNames),
                  ),
                  if (i != items.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                if (state.report!.hasMore || state.isLoadingMore)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : controller.loadMore,
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Load more'),
                    ),
                  ),
                if (state.errorMessage != null && state.report != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  String? _resolveBranchName(
    RestockSpendDrillDownItem item,
    Map<String, String> branchNames,
  ) {
    final resolved = branchNames[item.branchId]?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }

    final routeBranchName = widget.args.branchName?.trim();
    final scopeBranchId = widget.args.scope.branchId?.trim();
    if (routeBranchName != null &&
        routeBranchName.isNotEmpty &&
        scopeBranchId != null &&
        scopeBranchId.isNotEmpty &&
        scopeBranchId == item.branchId.trim()) {
      return routeBranchName;
    }

    return null;
  }
}

class _RestockSpendDrillDownIntro extends StatelessWidget {
  const _RestockSpendDrillDownIntro({required this.report});

  final RestockSpendDrillDownReport? report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inspect incoming stock records for the selected reporting scope.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        if (report != null) ...[
          const SizedBox(height: 12),
          Text(
            _summaryLabel(report!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }
}

class _RestockSpendRecordCard extends StatelessWidget {
  const _RestockSpendRecordCard({required this.item, this.branchName});

  final RestockSpendDrillDownItem item;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKnownCost = item.purchaseCostUsd != null;
    final costLabel = hasKnownCost
        ? formatUsdAmount(item.purchaseCostUsd!)
        : null;
    final branchLabel = switch (branchName?.trim()) {
      final String value when value.isNotEmpty => value,
      _ => item.branchId,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.stockItemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatShortDateTime(item.receivedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _RestockMetaChip(label: 'Batch ${item.restockBatchId}'),
                    _RestockMetaChip(label: 'Branch $branchLabel'),
                    _RestockMetaChip(
                      label: 'Qty ${_formatQuantity(item.quantityInBaseUnit)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasKnownCost)
                    Text(
                      costLabel!,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    const _RestockMetaChip(label: 'Unknown cost'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestockMetaChip extends StatelessWidget {
  const _RestockMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475467),
        ),
      ),
    );
  }
}

String _summaryLabel(RestockSpendDrillDownReport report) {
  final shown = report.items.length;
  final total = report.total;
  return 'Showing $shown of $total records';
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return formatInteger(value);
  }
  return value.toStringAsFixed(2);
}
