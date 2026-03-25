import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/widgets/order_detail_summary_row.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({
    super.key,
    required this.orderIdentityKey,
    this.showBack = true,
  });

  final String orderIdentityKey;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final policyState = ref.watch(policyNotifierProvider);
    final connectivityStatus = ref.watch(appConnectivityStatusProvider);
    final currentRole = resolveSessionAuthRole(
      ref.watch(loginControllerProvider).session,
    );
    final order = orders.firstWhere(
      (o) => o.matchesIdentity(orderIdentityKey),
      orElse: () => Order(
        id: '',
        saleId: '',
        number: orderIdentityKey,
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
    final showManualClaimSection =
        order.isLocalOutageOrder && order.isManualClaimOutageOrder;
    final showOfflineCashReplaySection = order.isQueueBackedOfflineCashOrder;
    final showLegacyOfflineCashSettlementSection =
        order.isAwaitingOutageSettlement && !order.isManualClaimOutageOrder;
    final canRecordLocalManualClaim =
        showManualClaimSection &&
        !order.hasManualExternalPaymentClaimRecorded &&
        connectivityStatus != AppConnectivityStatus.offline;
    final canReviewSubmittedManualClaim =
        showManualClaimSection &&
        order.hasSubmittedManualExternalPaymentClaim &&
        connectivityStatus != AppConnectivityStatus.offline &&
        (currentRole == AuthRole.manager ||
            currentRole == AuthRole.admin ||
            currentRole == AuthRole.owner);
    final canFinalizeLocalCashOrder =
        showLegacyOfflineCashSettlementSection &&
        connectivityStatus != AppConnectivityStatus.offline;
    final capturedByDisplayName = (order.openedByDisplayName ?? '').trim();
    final submittedByDisplayName =
        (order.manualPaymentClaimRequestedByDisplayName ?? '').trim();
    final showManualClaimBottomSubmitAction =
        showManualClaimSection && !order.hasSubmittedManualExternalPaymentClaim;
    final canSubmitManualClaimFromBottom =
        order.hasManualExternalPaymentClaimRecorded &&
        connectivityStatus != AppConnectivityStatus.offline;
    final manualClaimBottomHint = !showManualClaimBottomSubmitAction
        ? null
        : connectivityStatus == AppConnectivityStatus.offline
        ? 'Reconnect first, then submit the claim online.'
        : order.hasManualExternalPaymentClaimRecorded
        ? 'Proof is saved locally. Submit the external payment claim when ready.'
        : 'Save claim proof first before submitting online.';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        leading: showBack
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text(orderDetailTitle(order.number)),
        centerTitle: false,
      ),
      bottomNavigationBar: showManualClaimBottomSubmitAction
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (manualClaimBottomHint != null) ...[
                      Text(
                        manualClaimBottomHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: canSubmitManualClaimFromBottom
                          ? () => _submitManualClaimOnline(context, ref, order)
                          : null,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Submit Claim Online'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          showManualClaimBottomSubmitAction ? 24 : 16,
        ),
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
                    if (order.orderId.isNotEmpty) ...[
                      OrderDetailSummaryRow(
                        label: order.isLocalOutageOrder
                            ? 'Backend Order ID'
                            : 'Order ID',
                        value: order.orderId,
                      ),
                      const Divider(),
                    ],
                    if (order.isOpenTicket &&
                        (order.openTicketId ?? '') != order.orderId) ...[
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
                    const Divider(),
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
                    ] else if (!order.isExternalPaymentClaimOrder) ...[
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
                    if (order.isExternalPaymentClaimOrder &&
                        capturedByDisplayName.isNotEmpty) ...[
                      const Divider(),
                      OrderDetailSummaryRow(
                        label: 'Captured by',
                        value: capturedByDisplayName,
                      ),
                    ],
                    if (order.isExternalPaymentClaimOrder &&
                        submittedByDisplayName.isNotEmpty) ...[
                      const Divider(),
                      OrderDetailSummaryRow(
                        label: 'Submitted by',
                        value: submittedByDisplayName,
                      ),
                    ],
                    if (order.isExternalPaymentClaimOrder &&
                        order.manualPaymentClaimRequestedAt != null) ...[
                      const Divider(),
                      OrderDetailSummaryRow(
                        label: 'Submitted at',
                        value: orderDetailFormatTime(
                          order.manualPaymentClaimRequestedAt!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
                'External Payment Claim',
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
                        order.hasRejectedManualExternalPaymentClaim
                            ? 'The last external payment claim was rejected. Review the note below, update the proof if needed, and resubmit online.'
                            : order.hasSubmittedManualExternalPaymentClaim
                            ? canReviewSubmittedManualClaim
                                  ? 'This external payment claim is submitted online and ready for review. Approve or reject it here.'
                                  : 'External payment claim is submitted online. This order is now waiting for manager review.'
                            : order.hasManualExternalPaymentClaimRecorded
                            ? 'Claim proof is saved locally. Submit it online explicitly when connectivity is available.'
                            : connectivityStatus ==
                                  AppConnectivityStatus.offline
                            ? 'This outage order is captured. Reconnect first, then add the customer proof and submit the external payment claim.'
                            : 'Add the customer payment proof here. Saving proof only stores it locally. Finalization still waits for explicit online claim submission and later review.',
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
                          Text(
                            'Proof image',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          ProductImagePicker(
                            onPickImage: () async {},
                            imageUrl: order.localOutageProofImageUrl,
                            readOnly: true,
                            size: const Size(220, 180),
                            placeholderLabel: 'Proof image',
                            showTapToChangeHint: false,
                          ),
                        ],
                        if ((order.localOutageNote ?? '').isNotEmpty) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Note',
                            value: order.localOutageNote!,
                          ),
                        ],
                        if (order.hasRejectedManualExternalPaymentClaim &&
                            (order.localOutageLastErrorMessage ?? '')
                                .trim()
                                .isNotEmpty) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Review note',
                            value: order.localOutageLastErrorMessage!,
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
                        if (order.hasSubmittedManualExternalPaymentClaim) ...[
                          const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Backend claim',
                            value: order.localOutageBackendClaimId!,
                          ),
                          if (order.localOutageClaimSubmittedAt != null) ...[
                            const Divider(),
                            OrderDetailSummaryRow(
                              label: 'Submitted online',
                              value: orderDetailFormatTime(
                                order.localOutageClaimSubmittedAt!,
                              ),
                            ),
                          ],
                          if (canReviewSubmittedManualClaim) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _reviewManualClaim(
                                      context,
                                      ref,
                                      order,
                                      approve: false,
                                    ),
                                    icon: const Icon(Icons.close_outlined),
                                    label: const Text('Reject Claim'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _reviewManualClaim(
                                      context,
                                      ref,
                                      order,
                                      approve: true,
                                    ),
                                    icon: const Icon(Icons.verified_outlined),
                                    label: const Text('Approve Claim'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Text(
                              'Manager, admin, or owner approval is required before this order can be finalized.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ] else if (canRecordLocalManualClaim) ...[
                        const SizedBox(height: 12),
                        _ManualClaimProofForm(order: order),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (showOfflineCashReplaySection) ...[
              const SizedBox(height: 16),
              Text(
                'Offline Cash Replay',
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
                        order.hasOfflineCashReplayFailure
                            ? 'This cash checkout could not be replayed automatically. Review the sync error below before retrying.'
                            : order.isOfflineCashReplayInProgress
                            ? 'This cash checkout is replaying through sync now. Keep the app online until the real order is materialized.'
                            : connectivityStatus ==
                                  AppConnectivityStatus.offline
                            ? 'This cash checkout is queued locally and will replay automatically when connectivity returns.'
                            : 'This cash checkout is queued locally and waiting for sync/push replay. Keep the app online until the real order and sale are materialized.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if ((order.localOutageLastErrorCode ?? '')
                              .trim()
                              .isNotEmpty ||
                          (order.localOutageLastErrorMessage ?? '')
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        if ((order.localOutageLastErrorCode ?? '')
                            .trim()
                            .isNotEmpty)
                          OrderDetailSummaryRow(
                            label: 'Last sync code',
                            value: order.localOutageLastErrorCode!,
                          ),
                        if ((order.localOutageLastErrorMessage ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          if ((order.localOutageLastErrorCode ?? '')
                              .trim()
                              .isNotEmpty)
                            const Divider(),
                          OrderDetailSummaryRow(
                            label: 'Last sync message',
                            value: order.localOutageLastErrorMessage!,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (showLegacyOfflineCashSettlementSection) ...[
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
                            ? 'This cash payment was captured during outage. Settle it online now to materialize the order and create the real sale record.'
                            : 'This cash payment was captured during outage. Reconnect to settle it online and clear the outage order.',
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
                        label: const Text('Settle Captured Cash Order'),
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
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(Order order) {
    if (order.hasRejectedManualExternalPaymentClaim) {
      return 'External payment claim rejected';
    }
    if (order.hasSubmittedManualExternalPaymentClaim) {
      return 'External payment claim pending review';
    }
    if (order.hasPendingRemoteManualPaymentClaim) {
      return 'Manual payment claim pending review';
    }
    if (order.hasManualExternalPaymentClaimRecorded) {
      return 'External payment claim proof attached';
    }
    if (order.isManualClaimOutageOrder) {
      return 'External payment claim (offline capture)';
    }
    if (order.isQueueBackedOfflineCashOrder) {
      return 'Cash (queued offline replay)';
    }
    if (order.isLocalOutageOrder) {
      return 'Cash (offline capture)';
    }
    if (order.paymentMethod == 'qr') return 'QR / Transfer';
    if (order.paymentMethod == 'unpaid') return 'Pending collection';
    return 'Cash';
  }

  String _outageRecoveryMessage(Order order) {
    if (order.hasRejectedManualExternalPaymentClaim) {
      final reviewNote = (order.localOutageLastErrorMessage ?? '').trim();
      if (reviewNote.isNotEmpty) {
        return 'The last external payment claim was rejected: $reviewNote';
      }
      return 'The last external payment claim was rejected. Review the proof and resubmit if needed.';
    }
    if (order.hasSubmittedManualExternalPaymentClaim) {
      return 'An external payment claim is submitted online. This order is now locked and awaiting manager review.';
    }
    if (order.hasManualExternalPaymentClaimRecorded) {
      return 'Claim proof is attached locally. Submit it online to continue the manager review flow.';
    }
    if (order.isManualClaimOutageOrder) {
      return order.localOutageMaterializedOrderId == null
          ? 'This order was captured offline for the external-payment fallback. Reconnect first, then add the proof and continue the claim flow.'
          : 'This external-claim outage order is materialized online. Submit the claim when the proof details are ready.';
    }
    if (order.hasOfflineCashReplayFailure) {
      final replayNote = (order.localOutageLastErrorMessage ?? '').trim();
      if (replayNote.isNotEmpty) {
        return 'This offline cash checkout could not be replayed automatically: $replayNote';
      }
      return 'This offline cash checkout could not be replayed automatically. Review the sync error and resolve it before retrying.';
    }
    if (order.isOfflineCashReplayInProgress) {
      return 'This offline cash checkout is currently replaying through sync/push.';
    }
    if (order.isQueueBackedOfflineCashOrder) {
      return 'This cash checkout was queued offline and will replay automatically when connectivity returns.';
    }
    return order.localOutageMaterializedOrderId == null
        ? 'This order was captured offline and is still awaiting legacy online settlement.'
        : 'This outage-captured order is now materialized online and still awaiting legacy settlement.';
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
        const SnackBar(content: Text('Captured cash order settled online.')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to settle captured cash order',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _submitManualClaimOnline(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    try {
      await ref
          .read(ordersProvider.notifier)
          .submitManualExternalPaymentClaim(order);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'External payment claim submitted online and is awaiting manager review.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to submit manual claim online',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _reviewManualClaim(
    BuildContext context,
    WidgetRef ref,
    Order order, {
    required bool approve,
  }) async {
    final note = await _promptReviewNote(
      context,
      approve: approve,
      order: order,
    );
    if (note == null) return;

    try {
      if (approve) {
        final result = await ref
            .read(ordersProvider.notifier)
            .approveSubmittedManualPaymentClaim(order, note: note);
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Claim Approved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The manual KHQR claim is approved and the sale is now finalized.',
                ),
                const SizedBox(height: 12),
                if ((result.receiptId ?? '').trim().isNotEmpty)
                  Text('Receipt #: ${result.receiptId}'),
                if ((result.saleId ?? '').trim().isNotEmpty)
                  Text('Sale ID: ${result.saleId}'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        Navigator.of(context).maybePop();
        return;
      }

      await ref
          .read(ordersProvider.notifier)
          .rejectSubmittedManualPaymentClaim(order, note: note);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Manual KHQR claim rejected. The order stays open for further action.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: approve
                  ? 'Failed to approve manual claim'
                  : 'Failed to reject manual claim',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<String?> _promptReviewNote(
    BuildContext context, {
    required bool approve,
    required Order order,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              approve
                  ? 'Approve External Payment Claim'
                  : 'Reject External Payment Claim',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approve
                      ? 'Add an optional review note before finalizing this claimed external payment.'
                      : 'Add a review note so staff knows why this external payment claim was rejected.',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: approve
                        ? 'Approval note (optional)'
                        : 'Rejection note',
                    hintText: approve
                        ? 'Verified against transfer proof'
                        : 'Proof is not sufficient',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  orderReferenceLabel(order.number),
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: Text(approve ? 'Approve' : 'Reject'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
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
                title: const Text('Settle Captured Cash Order'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm the cash received so this offline-captured order can be settled online.',
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

class _ManualClaimProofForm extends ConsumerStatefulWidget {
  const _ManualClaimProofForm({required this.order});

  final Order order;

  @override
  ConsumerState<_ManualClaimProofForm> createState() =>
      _ManualClaimProofFormState();
}

class _ManualClaimProofFormState extends ConsumerState<_ManualClaimProofForm> {
  late final TextEditingController _amountController;
  late final TextEditingController _customerReferenceController;
  late final TextEditingController _noteController;
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _validationMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.order.tenderCurrency.toLowerCase() == 'khr'
        ? widget.order.totalKhr
        : widget.order.totalUsd;
    _amountController = TextEditingController(
      text: widget.order.tenderCurrency.toLowerCase() == 'khr'
          ? initialAmount.toStringAsFixed(0)
          : initialAmount.toStringAsFixed(2),
    );
    _customerReferenceController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerReferenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Save proof first. Submission stays a separate online step after this.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                'Claimed amount (${widget.order.tenderCurrency.toUpperCase()})',
          ),
        ),
        const SizedBox(height: 12),
        Text('Payment proof', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ProductImagePicker(
          onPickImage: _pickProofImage,
          imageBytes: _selectedImageBytes,
          onClearLocalSelection: _selectedImageBytes == null
              ? null
              : () {
                  setState(() {
                    _selectedImageBytes = null;
                  });
                },
          placeholderLabel: 'Select proof image',
          placeholderIcon: Icons.add_photo_alternate_outlined,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customerReferenceController,
          decoration: const InputDecoration(
            labelText: 'Customer reference (optional)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        if (_validationMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _validationMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProof,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Saving...' : 'Save Proof'),
        ),
      ],
    );
  }

  Future<void> _pickProofImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        setState(() {
          _validationMessage =
              'Selected proof image is empty. Please pick another image.';
        });
        return;
      }
      setState(() {
        _selectedImageBytes = bytes;
        _validationMessage = null;
      });
    } catch (_) {
      setState(() {
        _validationMessage =
            'Image picker is not available right now. Restart the app after flutter pub get if needed.';
      });
    }
  }

  Future<void> _saveProof() async {
    final claimedTenderAmount = double.tryParse(_amountController.text.trim());
    if (claimedTenderAmount == null || claimedTenderAmount <= 0) {
      setState(() {
        _validationMessage = 'Enter a valid claimed amount before saving.';
      });
      return;
    }
    if (_selectedImageBytes == null || _selectedImageBytes!.isEmpty) {
      setState(() {
        _validationMessage =
            'Select the customer payment proof image before saving.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _validationMessage = null;
    });

    try {
      await ref
          .read(ordersProvider.notifier)
          .recordLocalManualExternalPaymentClaimWithUpload(
            widget.order,
            claimedTenderAmount: claimedTenderAmount,
            proofImageBytes: _selectedImageBytes!,
            customerReference: _customerReferenceController.text.trim(),
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'External payment claim proof saved locally. Submit it online when ready.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to save claim proof',
              error: e,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _CashSettlementDraft {
  const _CashSettlementDraft({required this.cashReceivedAmount});

  final double cashReceivedAmount;
}
