import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/responsive_detail_modal.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_card.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_filters_bar.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_status_bottom_sheet.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/void_request_queue_view.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  static const _fulfillmentStatuses = [
    'pending',
    'in_prep',
    'ready',
    'delivered',
    'cancelled',
  ];

  String _selectedStatus = _fulfillmentStatuses.first;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveWorkspace();
    });
  }

  Future<void> _loadActiveWorkspace() {
    final workspaceTab = ref.read(fulfillmentWorkspaceTabProvider);
    return _loadWorkspace(workspaceTab);
  }

  Future<void> _loadWorkspace(FulfillmentWorkspaceTab workspaceTab) {
    final notifier = ref.read(ordersProvider.notifier);
    switch (workspaceTab) {
      case FulfillmentWorkspaceTab.kitchen:
        return notifier.load(date: _selectedDate);
      case FulfillmentWorkspaceTab.voidRequests:
        return Future.value();
      case FulfillmentWorkspaceTab.externalClaims:
        return notifier.load(
          date: _selectedDate,
          view: orderManualClaimReviewView,
        );
    }
  }

  List<FulfillmentWorkspaceTab> _workspaceTabsForRole(AuthRole role) {
    if (isVoidReviewerAuthRole(role)) {
      return const [
        FulfillmentWorkspaceTab.kitchen,
        FulfillmentWorkspaceTab.voidRequests,
      ];
    }
    return const [FulfillmentWorkspaceTab.kitchen];
  }

  String _tabLabel(FulfillmentWorkspaceTab tab) {
    switch (tab) {
      case FulfillmentWorkspaceTab.kitchen:
        return 'Kitchen';
      case FulfillmentWorkspaceTab.voidRequests:
        return 'Void Requests';
      case FulfillmentWorkspaceTab.externalClaims:
        return 'Deferred Claims';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadActiveWorkspace();
    }
  }

  void _openStatusSheet(Order order) {
    final notifier = ref.read(ordersProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => OrderStatusBottomSheet(
        initialStatus: order.status,
        onSubmit: (status) => notifier.updateStatus(order.identityKey, status),
      ),
    );
  }

  void _openOrderDetail(Order order) {
    showResponsiveDetailModal<void>(
      context: context,
      builder: (modalContext) =>
          OrderDetailPage(orderIdentityKey: order.identityKey, showBack: false),
    );
  }

  Future<void> _openRequestVoid(Order order) async {
    final saleId = order.finalizedSaleId;
    if (saleId.isEmpty) return;
    final reason = await showResponsiveDetailModal<String>(
      context: context,
      builder: (_) => _RequestVoidReasonSheet(order: order),
    );
    if (reason == null || reason.trim().isEmpty) return;

    final repo = ref.read(saleRepositoryProvider);
    try {
      await repo.requestSaleVoid(
        SaleRequestVoidCommand(
          saleId: saleId,
          reason: reason.trim(),
          clientOpId:
              'sale-void-request-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Void request submitted')));
      await _loadActiveWorkspace();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to request void',
              error: error,
            ),
          ),
        ),
      );
    }
  }

  List<OrderCardAction> _buildCardActions(
    Order order,
    FulfillmentWorkspaceTab workspaceTab,
    AuthRole currentRole,
  ) {
    final actions = <OrderCardAction>[];
    if (workspaceTab == FulfillmentWorkspaceTab.externalClaims) {
      actions.add(
        OrderCardAction(
          label: 'Review detail',
          icon: Icons.open_in_new_outlined,
          onSelected: () => _openOrderDetail(order),
        ),
      );
    }
    if (workspaceTab == FulfillmentWorkspaceTab.kitchen &&
        isBranchOperatorAuthRole(currentRole) &&
        order.canOpenVoidWorkflow) {
      actions.add(
        OrderCardAction(
          label: 'Request void',
          icon: Icons.do_not_disturb_on_outlined,
          onSelected: () => _openRequestVoid(order),
        ),
      );
    }
    if (workspaceTab == FulfillmentWorkspaceTab.kitchen &&
        !order.isLocalOutageOrder) {
      actions.add(
        OrderCardAction(
          label: 'Update fulfillment status',
          icon: Icons.pending_actions_outlined,
          onSelected: () => _openStatusSheet(order),
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = resolveSessionAuthRole(
      ref.watch(loginControllerProvider).session,
    );
    final workspaceTabs = _workspaceTabsForRole(currentRole);
    final requestedWorkspaceTab = ref.watch(fulfillmentWorkspaceTabProvider);
    final workspaceTab = workspaceTabs.contains(requestedWorkspaceTab)
        ? requestedWorkspaceTab
        : FulfillmentWorkspaceTab.kitchen;
    if (workspaceTab != requestedWorkspaceTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(fulfillmentWorkspaceTabProvider.notifier).setTab(workspaceTab);
      });
    }

    final orders = ref.watch(ordersProvider);
    final kitchenOrders = orders
        .where((order) => order.ticketStatus.trim().toUpperCase() == 'PAID')
        .where((order) => !order.isExternalPaymentClaimOrder)
        .toList(growable: false);
    final kitchenStatusCounts = <String, int>{
      for (final status in _fulfillmentStatuses)
        status: kitchenOrders.where((order) => order.status == status).length,
    };
    final filtered = switch (workspaceTab) {
      FulfillmentWorkspaceTab.kitchen =>
        kitchenOrders
            .where((order) => order.status == _selectedStatus)
            .toList(growable: false),
      FulfillmentWorkspaceTab.voidRequests => const <Order>[],
      FulfillmentWorkspaceTab.externalClaims =>
        orders
            .where((order) => order.isExternalPaymentClaimOrder)
            .toList(growable: false),
    };

    return DefaultTabController(
      key: ValueKey(workspaceTab),
      length: workspaceTabs.length,
      initialIndex: workspaceTabs.indexOf(workspaceTab),
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TabBar(
                tabs: [
                  for (final tab in workspaceTabs) Tab(text: _tabLabel(tab)),
                ],
                onTap: (index) async {
                  final nextTab = workspaceTabs[index];
                  ref
                      .read(fulfillmentWorkspaceTabProvider.notifier)
                      .setTab(nextTab);
                  await _loadWorkspace(nextTab);
                },
              ),
            ),
            if (workspaceTab == FulfillmentWorkspaceTab.kitchen)
              OrderFiltersBar(
                selectedDate: _selectedDate,
                onPickDate: _pickDate,
                statuses: _fulfillmentStatuses,
                statusCounts: kitchenStatusCounts,
                selectedStatus: _selectedStatus,
                onStatusChanged: (status) =>
                    setState(() => _selectedStatus = status),
                statusLabelBuilder: orderFulfillmentStatusLabel,
              )
            else if (workspaceTab == FulfillmentWorkspaceTab.voidRequests)
              const SizedBox(height: 12)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(formatOrderDate(_selectedDate)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: switch (workspaceTab) {
                FulfillmentWorkspaceTab.voidRequests =>
                  const VoidRequestQueueView(),
                FulfillmentWorkspaceTab.kitchen ||
                FulfillmentWorkspaceTab.externalClaims =>
                  filtered.isEmpty
                      ? Center(
                          child: Text(
                            workspaceTab == FulfillmentWorkspaceTab.kitchen
                                ? 'No fulfillment work'
                                : 'No deferred claim items',
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isLarge = AppBreakpoints.isLarge(
                              constraints.maxWidth,
                            );
                            final contentPadding = EdgeInsets.fromLTRB(
                              16,
                              workspaceTab == FulfillmentWorkspaceTab.kitchen
                                  ? 4
                                  : 8,
                              16,
                              16,
                            );
                            if (workspaceTab ==
                                    FulfillmentWorkspaceTab.kitchen &&
                                isLarge) {
                              return GridView.builder(
                                padding: contentPadding,
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 360,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      mainAxisExtent: 318,
                                    ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final order = filtered[index];
                                  return OrderCard(
                                    order: order,
                                    onTap: () => _openOrderDetail(order),
                                    onStatusTap: !order.isLocalOutageOrder
                                        ? () => _openStatusSheet(order)
                                        : null,
                                    actions: _buildCardActions(
                                      order,
                                      workspaceTab,
                                      currentRole,
                                    ),
                                    statusLabelBuilder: (order) =>
                                        orderFulfillmentStatusLabel(
                                          order.status,
                                        ),
                                    statusColorBuilder: (order) =>
                                        orderStatusColor(order.status),
                                    statusTextColorBuilder: (order) =>
                                        orderStatusTextColor(order.status),
                                  );
                                },
                              );
                            }
                            return ListView.separated(
                              padding: contentPadding,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final order = filtered[index];
                                return OrderCard(
                                  order: order,
                                  compact: true,
                                  onTap: () => _openOrderDetail(order),
                                  onStatusTap:
                                      workspaceTab ==
                                              FulfillmentWorkspaceTab.kitchen &&
                                          !order.isLocalOutageOrder
                                      ? () => _openStatusSheet(order)
                                      : null,
                                  actions: _buildCardActions(
                                    order,
                                    workspaceTab,
                                    currentRole,
                                  ),
                                  statusLabelBuilder:
                                      workspaceTab ==
                                          FulfillmentWorkspaceTab.kitchen
                                      ? (order) => orderFulfillmentStatusLabel(
                                          order.status,
                                        )
                                      : (
                                          order,
                                        ) => externalPaymentClaimStatusLabel(
                                          order.externalPaymentClaimStatusKey,
                                        ),
                                  statusColorBuilder:
                                      workspaceTab ==
                                          FulfillmentWorkspaceTab.kitchen
                                      ? (order) =>
                                            orderStatusColor(order.status)
                                      : (
                                          order,
                                        ) => externalPaymentClaimStatusColor(
                                          order.externalPaymentClaimStatusKey,
                                        ),
                                  statusTextColorBuilder:
                                      workspaceTab ==
                                          FulfillmentWorkspaceTab.kitchen
                                      ? (order) =>
                                            orderStatusTextColor(order.status)
                                      : (
                                          order,
                                        ) => externalPaymentClaimStatusTextColor(
                                          order.externalPaymentClaimStatusKey,
                                        ),
                                );
                              },
                            );
                          },
                        ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestVoidReasonSheet extends StatefulWidget {
  const _RequestVoidReasonSheet({required this.order});

  final Order order;

  @override
  State<_RequestVoidReasonSheet> createState() =>
      _RequestVoidReasonSheetState();
}

class _RequestVoidReasonSheetState extends State<_RequestVoidReasonSheet> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = _reasonController.text.trim();
    final order = widget.order;
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                              'Request void',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submit this finalized sale for branch review. The sale will only be voided after approval.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close request form',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RequestVoidSummaryRow(
                    label: 'Ticket',
                    value: orderCardTitle(order.number),
                  ),
                  _RequestVoidSummaryRow(
                    label: 'Sale ID',
                    value: order.finalizedSaleId,
                  ),
                  _RequestVoidSummaryRow(
                    label: 'Total',
                    value: '\$${order.totalUsd.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reason',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    autofocus: true,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText:
                          'Explain why this finalized sale needs to be voided',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: reason.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(reason),
                      child: const Text('Submit request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestVoidSummaryRow extends StatelessWidget {
  const _RequestVoidSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
