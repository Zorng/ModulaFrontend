import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/widgets/order_detail_summary_row.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({
    super.key,
    required this.orderNumber,
    this.showBack = true,
  });

  final String orderNumber;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final policyState = ref.watch(policyNotifierProvider);
    final connectivityStatus = ref.watch(appConnectivityStatusProvider);
    final order = orders.firstWhere(
      (o) => o.number == orderNumber,
      orElse: () => Order(
        id: orderNumber,
        saleId: orderNumber,
        number: orderNumber,
        status: 'unknown',
        ticketStatus: 'UNKNOWN',
        placedAt: DateTime.now(),
        orderType: 'take_away',
        paymentMethod: 'cash',
        totalUsd: 0,
        totalKhr: 0,
        tenderCurrency: 'usd',
        tenderAmount: 0,
        changeAmount: 0,
        lines: const [],
      ),
    );
    final manualClaimPolicyEnabled =
        policyState.branchPolicy.saleAllowManualExternalPaymentClaim;
    final showManualClaimSection =
        order.isLocalOutageOrder && order.isManualClaimOutageOrder;
    final showOfflineCashSettlementSection =
        order.isAwaitingOutageSettlement && !order.isManualClaimOutageOrder;
    final canRecordLocalManualClaim =
        showManualClaimSection &&
        !order.hasManualExternalPaymentClaimRecorded &&
        order.localOutageMaterializedOrderId == null &&
        manualClaimPolicyEnabled;
    final canFinalizeLocalCashOrder =
        showOfflineCashSettlementSection &&
        connectivityStatus != AppConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        leading: showBack
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text('Order No. ${order.number}'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    if (order.openTicketId != null) ...[
                      OrderDetailSummaryRow(
                        label: 'Open Ticket',
                        value: order.openTicketId!,
                      ),
                      const Divider(),
                    ],
                    OrderDetailSummaryRow(
                      label: 'Type',
                      value: orderDetailOrderTypeLabel(order.orderType),
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Placed',
                      value: orderDetailFormatTime(order.placedAt.toLocal()),
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Payment Method',
                      value: _paymentMethodLabel(order),
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Current Status',
                      value: orderDetailStatusLabel(order.status),
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Ticket Status',
                      value: order.ticketStatus,
                    ),
                  ],
                ),
              ),
            ),
            if (order.isLocalOutageOrder) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.withValues(alpha: 0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _outageRecoveryMessage(order),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (showManualClaimSection) ...[
              const SizedBox(height: 16),
              Text(
                'Manual KHQR Claim',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.hasManualExternalPaymentClaimRecorded
                            ? 'Manual KHQR claim details are stored locally. This order remains locked for manager review once it is materialized online.'
                            : manualClaimPolicyEnabled
                            ? 'Use this fallback when the customer already paid through KHQR during outage, but the backend could not verify it live.'
                            : 'Manual external-payment claim fallback is disabled for this branch.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (order.hasManualExternalPaymentClaimRecorded) ...[
                        const SizedBox(height: 12),
                        OrderDetailSummaryRow(
                          label: 'Claimed method',
                          value:
                              order.localOutageClaimedPaymentMethod ?? 'KHQR',
                        ),
                        const Divider(),
                        OrderDetailSummaryRow(
                          label: 'Claimed amount',
                          value: _formatTenderAmount(
                            amount:
                                order.localOutageClaimedTenderAmount ??
                                order.tenderAmount,
                            tenderCurrency: order.tenderCurrency,
                          ),
                        ),
                        if ((order.localOutageCustomerReference ?? '')
                            .isNotEmpty) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Customer reference',
                            value: order.localOutageCustomerReference!,
                          ),
                        ],
                        if ((order.localOutageProofImageUrl ?? '')
                            .isNotEmpty) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Proof image URL',
                            value: order.localOutageProofImageUrl!,
                          ),
                        ],
                        if ((order.localOutageNote ?? '').isNotEmpty) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Note',
                            value: order.localOutageNote!,
                          ),
                        ],
                        if (order.localOutageClaimRecordedAt != null) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Recorded',
                            value: orderDetailFormatTime(
                              order.localOutageClaimRecordedAt!,
                            ),
                          ),
                        ],
                      ] else if (canRecordLocalManualClaim) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              _recordManualClaim(context, ref, order),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Record Manual Claim'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (showOfflineCashSettlementSection) ...[
              const SizedBox(height: 16),
              Text(
                'Cash Recovery',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canFinalizeLocalCashOrder
                            ? 'This cash payment was captured during outage. Finalize it online now to create the real sale record and clear the outage order.'
                            : 'This cash payment was captured during outage. Reconnect to finalize it online and clear the outage order.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: canFinalizeLocalCashOrder
                            ? () => _finalizeLocalOutageCashOrder(
                                context,
                                ref,
                                order,
                              )
                            : null,
                        icon: const Icon(Icons.point_of_sale_outlined),
                        label: const Text('Finalize Captured Cash Order'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (order.isSettleableOpenTicket) ...[
              const SizedBox(height: 16),
              Text(
                'Open Ticket Settlement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !policyState.branchPolicy.saleAllowPayLater
                            ? 'New pay-later tickets are disabled by policy, but this existing unpaid ticket can still be settled.'
                            : 'This existing unpaid ticket can be settled directly from here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _settleOpenTicket(
                                context,
                                ref,
                                order,
                                tenderCurrency: 'USD',
                              ),
                              child: Text(
                                'Collect USD \$${order.totalUsd.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _settleOpenTicket(
                                context,
                                ref,
                                order,
                                tenderCurrency: 'KHR',
                              ),
                              child: Text(
                                'Collect KHR ${order.totalKhr.toStringAsFixed(0)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Order Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: order.lines.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final line = order.lines[index];
                  final modifierText = line.modifiers.isEmpty
                      ? 'No modifiers'
                      : line.modifiers.join(', ');
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${line.quantity}x',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              modifierText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (order.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  order.isOpenTicket
                      ? 'Line-level ticket details are not available in this view yet. Settlement is still supported.'
                      : 'No item lines available.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Text('Payment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    OrderDetailSummaryRow(
                      label: 'Grand Total',
                      value: '\$${order.totalUsd.toStringAsFixed(2)}',
                      subValue: 'KHR ${order.totalKhr.toStringAsFixed(0)}',
                    ),
                    if (order.hasManualExternalPaymentClaimRecorded) ...[
                      const Divider(),
                      OrderDetailSummaryRow(
                        label: 'Claimed amount',
                        value: _formatTenderAmount(
                          amount:
                              order.localOutageClaimedTenderAmount ??
                              order.tenderAmount,
                          tenderCurrency: order.tenderCurrency,
                        ),
                      ),
                    ] else if (!order.isManualClaimOutageOrder) ...[
                      const Divider(),
                      OrderDetailSummaryRow(
                        label: 'Received amount',
                        value: _formatTenderAmount(
                          amount: order.tenderAmount,
                          tenderCurrency: order.tenderCurrency,
                        ),
                      ),
                      const Divider(),
                      OrderDetailSummaryRow(
                        label: 'Change',
                        value: _formatTenderAmount(
                          amount: order.changeAmount,
                          tenderCurrency: order.tenderCurrency,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(Order order) {
    if (order.hasManualExternalPaymentClaimRecorded) {
      return 'Manual KHQR claim pending review';
    }
    if (order.isManualClaimOutageOrder) {
      return 'Manual KHQR claim (offline capture)';
    }
    if (order.isLocalOutageOrder) {
      return 'Cash (offline capture)';
    }
    if (order.paymentMethod == 'qr') return 'QR / Transfer';
    if (order.paymentMethod == 'unpaid') return 'Pending collection';
    return 'Cash';
  }

  String _outageRecoveryMessage(Order order) {
    if (order.hasManualExternalPaymentClaimRecorded) {
      return 'A manual KHQR payment claim is recorded locally. This order remains open until a manager reviews it after online recovery.';
    }
    if (order.isManualClaimOutageOrder) {
      return order.localOutageMaterializedOrderId == null
          ? 'This order was captured offline for the manual KHQR fallback. Record proof details here, then continue review when the backend order exists.'
          : 'This manual-claim outage order is materialized online and still awaiting review.';
    }
    return order.localOutageMaterializedOrderId == null
        ? 'This order was captured offline and is still awaiting online settlement.'
        : 'This outage-captured order is now materialized online and still awaiting settlement.';
  }

  String _formatTenderAmount({
    required double amount,
    required String tenderCurrency,
  }) {
    if (tenderCurrency.toLowerCase() == 'khr') {
      return 'KHR ${amount.toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  Future<void> _recordManualClaim(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final initialAmount = order.tenderCurrency.toLowerCase() == 'khr'
        ? order.totalKhr.toStringAsFixed(0)
        : order.totalUsd.toStringAsFixed(2);
    final amountController = TextEditingController(text: initialAmount);
    final proofUrlController = TextEditingController();
    final referenceController = TextEditingController();
    final noteController = TextEditingController();

    try {
      final draft = await showDialog<_ManualClaimDraft>(
        context: context,
        builder: (dialogContext) {
          String? validationMessage;
          return StatefulBuilder(
            builder: (dialogContext, setModalState) {
              return AlertDialog(
                title: const Text('Record Manual KHQR Claim'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This stores the manual KHQR claim locally on the outage order. Final approval still happens later when the order is reviewed online.',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'Claimed amount (${order.tenderCurrency.toUpperCase()})',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: proofUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Proof image URL',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Customer reference (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                      if (validationMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          validationMessage!,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(
                        amountController.text.trim(),
                      );
                      if (amount == null || amount <= 0) {
                        setModalState(() {
                          validationMessage =
                              'Enter a valid claimed amount before saving.';
                        });
                        return;
                      }
                      if (proofUrlController.text.trim().isEmpty) {
                        setModalState(() {
                          validationMessage =
                              'Proof image URL is required before saving.';
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop(
                        _ManualClaimDraft(
                          claimedTenderAmount: amount,
                          proofImageUrl: proofUrlController.text.trim(),
                          customerReference: referenceController.text.trim(),
                          note: noteController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save Claim'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (draft == null) return;

      await ref
          .read(ordersProvider.notifier)
          .recordLocalManualExternalPaymentClaim(
            order,
            claimedTenderAmount: draft.claimedTenderAmount,
            proofImageUrl: draft.proofImageUrl,
            customerReference: draft.customerReference,
            note: draft.note,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual KHQR claim recorded on the outage order.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to record manual claim',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _finalizeLocalOutageCashOrder(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final draft = await _promptCashSettlementDraft(context, order);
    if (draft == null) return;
    try {
      await ref
          .read(ordersProvider.notifier)
          .finalizeLocalOutageCashOrder(
            order,
            cashReceivedAmount: draft.cashReceivedAmount,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captured cash order finalized online.')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to finalize captured cash order',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<_CashSettlementDraft?> _promptCashSettlementDraft(
    BuildContext context,
    Order order,
  ) async {
    final defaultAmount = order.tenderAmount > 0
        ? order.tenderAmount
        : (order.tenderCurrency.toLowerCase() == 'khr'
              ? order.totalKhr
              : order.totalUsd);
    final amountController = TextEditingController(
      text: order.tenderCurrency.toLowerCase() == 'khr'
          ? defaultAmount.toStringAsFixed(0)
          : defaultAmount.toStringAsFixed(2),
    );

    try {
      return await showDialog<_CashSettlementDraft>(
        context: context,
        builder: (dialogContext) {
          String? validationMessage;
          return StatefulBuilder(
            builder: (dialogContext, setModalState) {
              return AlertDialog(
                title: const Text('Finalize Captured Cash Order'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm the cash received so this offline-captured order can be finalized online.',
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            'Cash received (${order.tenderCurrency.toUpperCase()})',
                      ),
                    ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        validationMessage!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(
                        amountController.text.trim(),
                      );
                      if (amount == null || amount <= 0) {
                        setModalState(() {
                          validationMessage =
                              'Enter a valid cash amount before finalizing.';
                        });
                        return;
                      }
                      Navigator.of(
                        dialogContext,
                      ).pop(_CashSettlementDraft(cashReceivedAmount: amount));
                    },
                    child: const Text('Finalize'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      amountController.dispose();
    }
  }

  Future<void> _settleOpenTicket(
    BuildContext context,
    WidgetRef ref,
    Order order, {
    required String tenderCurrency,
  }) async {
    try {
      await ref
          .read(ordersProvider.notifier)
          .settleOpenTicket(order, tenderCurrency: tenderCurrency);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tenderCurrency == 'KHR'
                ? 'Open ticket settled in KHR.'
                : 'Open ticket settled in USD.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to settle open ticket',
              error: e,
            ),
          ),
        ),
      );
    }
  }
}

class _ManualClaimDraft {
  const _ManualClaimDraft({
    required this.claimedTenderAmount,
    required this.proofImageUrl,
    required this.customerReference,
    required this.note,
  });

  final double claimedTenderAmount;
  final String proofImageUrl;
  final String customerReference;
  final String note;
}

class _CashSettlementDraft {
  const _CashSettlementDraft({required this.cashReceivedAmount});

  final double cashReceivedAmount;
}
