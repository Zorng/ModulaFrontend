import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
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

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      12,
                    ),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RestockSpendDrillDownIntro(report: state.report),
                              const SizedBox(height: 16),
                              InventoryDropdown<RestockSpendCostFilter>(
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
                                leadingIcon: const Icon(
                                  Icons.tune_outlined,
                                  size: 18,
                                ),
                                fillColor: Colors.white,
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _RestockSpendDrillDownIntro(
                                  report: state.report,
                                ),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 280,
                                child:
                                    InventoryDropdown<RestockSpendCostFilter>(
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
                                      leadingIcon: const Icon(
                                        Icons.tune_outlined,
                                        size: 18,
                                      ),
                                      fillColor: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state.isLoading && state.report == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.errorMessage != null &&
                            state.report == null) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: ReportingMessageStateView(
                                icon: Icons.inventory_2_outlined,
                                title: 'Restock details unavailable',
                                message: state.errorMessage!,
                                actionLabel: 'Retry',
                                onAction: controller.refresh,
                              ),
                            ),
                          );
                        }

                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: const ReportingMessageStateView(
                                icon: Icons.inventory_2_outlined,
                                title: 'No restock records',
                                message:
                                    'No restock entries match the current filters.',
                              ),
                            ),
                          );
                        }

                        return ListView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            20,
                          ),
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              _RestockSpendRecordCard(item: items[i]),
                              if (i != items.length - 1)
                                const SizedBox(height: 12),
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
                            if (state.errorMessage != null &&
                                state.report != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                state.errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
  const _RestockSpendRecordCard({required this.item});

  final RestockSpendDrillDownItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final costLabel = item.purchaseCostUsd == null
        ? 'Unknown'
        : formatUsdAmount(item.purchaseCostUsd!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.stockItemName,
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Restock ${item.restockBatchId}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          );

          final costText = Text(
            costLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isCompact ? TextAlign.left : TextAlign.right,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                titleBlock,
                const SizedBox(height: 12),
                costText,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    Flexible(child: costText),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Qty ${_formatQuantity(item.quantityInBaseUnit)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Branch ${item.branchId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatShortDateTime(item.receivedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
