import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/navigation/responsive_detail_modal.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_card.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_filters_bar.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_status_bottom_sheet.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  static const _workspaceTabs = [
    FulfillmentWorkspaceTab.kitchen,
    FulfillmentWorkspaceTab.externalClaims,
  ];
  static const _fulfillmentStatuses = [
    'pending',
    'in_prep',
    'ready',
    'delivered',
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
    final notifier = ref.read(ordersProvider.notifier);
    switch (workspaceTab) {
      case FulfillmentWorkspaceTab.kitchen:
        return notifier.load(date: _selectedDate);
      case FulfillmentWorkspaceTab.externalClaims:
        return notifier.load(date: _selectedDate, status: 'open', view: null);
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

  @override
  Widget build(BuildContext context) {
    final workspaceTab = ref.watch(fulfillmentWorkspaceTabProvider);
    final orders = ref.watch(ordersProvider);
    final filtered = switch (workspaceTab) {
      FulfillmentWorkspaceTab.kitchen =>
        orders
            .where((order) => order.ticketStatus.trim().toUpperCase() == 'PAID')
            .where((order) => !order.isExternalPaymentClaimOrder)
            .where((order) => order.status == _selectedStatus)
            .toList(),
      FulfillmentWorkspaceTab.externalClaims =>
        orders.where((order) => order.isExternalPaymentClaimOrder).toList(),
    };

    return DefaultTabController(
      key: ValueKey(workspaceTab),
      length: _workspaceTabs.length,
      initialIndex: workspaceTab.index,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TabBar(
                tabs: const [
                  Tab(text: 'Kitchen'),
                  Tab(text: 'External Claims'),
                ],
                onTap: (index) async {
                  final nextTab = _workspaceTabs[index];
                  ref
                      .read(fulfillmentWorkspaceTabProvider.notifier)
                      .setTab(nextTab);
                  await _loadActiveWorkspace();
                },
              ),
            ),
            if (workspaceTab == FulfillmentWorkspaceTab.kitchen)
              OrderFiltersBar(
                selectedDate: _selectedDate,
                onPickDate: _pickDate,
                statuses: _fulfillmentStatuses,
                selectedStatus: _selectedStatus,
                onStatusChanged: (status) =>
                    setState(() => _selectedStatus = status),
                statusLabelBuilder: orderFulfillmentStatusLabel,
              )
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
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        workspaceTab == FulfillmentWorkspaceTab.kitchen
                            ? 'No fulfillment work'
                            : 'No external payment claims',
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return OrderCard(
                          order: order,
                          onTap: () {
                            showResponsiveDetailModal<void>(
                              context: context,
                              builder: (modalContext) => OrderDetailPage(
                                orderIdentityKey: order.identityKey,
                                showBack: false,
                              ),
                            );
                          },
                          onStatusTap:
                              workspaceTab == FulfillmentWorkspaceTab.kitchen &&
                                  !order.isLocalOutageOrder
                              ? () => _openStatusSheet(order)
                              : null,
                          statusLabelBuilder:
                              workspaceTab == FulfillmentWorkspaceTab.kitchen
                              ? (order) =>
                                    orderFulfillmentStatusLabel(order.status)
                              : (order) => externalPaymentClaimStatusLabel(
                                  order.externalPaymentClaimStatusKey,
                                ),
                          statusColorBuilder:
                              workspaceTab == FulfillmentWorkspaceTab.kitchen
                              ? (order) => orderStatusColor(order.status)
                              : (order) => externalPaymentClaimStatusColor(
                                  order.externalPaymentClaimStatusKey,
                                ),
                          statusTextColorBuilder:
                              workspaceTab == FulfillmentWorkspaceTab.kitchen
                              ? (order) => orderStatusTextColor(order.status)
                              : (order) => externalPaymentClaimStatusTextColor(
                                  order.externalPaymentClaimStatusKey,
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
