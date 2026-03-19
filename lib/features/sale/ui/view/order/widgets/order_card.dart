import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_line_row.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onStatusTap,
    this.statusLabelBuilder = _defaultStatusLabel,
    this.statusColorBuilder = _defaultStatusColor,
    this.statusTextColorBuilder = _defaultStatusTextColor,
  });

  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;
  final String Function(Order order) statusLabelBuilder;
  final Color Function(Order order) statusColorBuilder;
  final Color Function(Order order) statusTextColorBuilder;

  static String _defaultStatusLabel(Order order) {
    return orderFulfillmentStatusLabel(order.status);
  }

  static Color _defaultStatusColor(Order order) {
    return orderStatusColor(order.status);
  }

  static Color _defaultStatusTextColor(Order order) {
    return orderStatusTextColor(order.status);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order No. ${order.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColorBuilder(order),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: GestureDetector(
                      onTap: onStatusTap,
                      child: Text(
                        statusLabelBuilder(order),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: statusTextColorBuilder(order)),
                      ),
                    ),
                  ),
                ],
              ),
              if (order.isSettleableOpenTicket) ...[
                const SizedBox(height: 6),
                Text(
                  'Pay-later ticket still awaiting settlement. Fulfillment can continue while payment stays open.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else if (order.hasPendingRemoteManualPaymentClaim) ...[
                const SizedBox(height: 6),
                Text(
                  'Manual payment claim submitted. Open detail to review the claim and continue manager approval.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else if (order.isLocalOutageOrder) ...[
                const SizedBox(height: 6),
                Text(
                  order.hasRejectedManualExternalPaymentClaim
                      ? 'Manual KHQR claim was rejected. Review and resubmit if needed.'
                      : order.hasSubmittedManualExternalPaymentClaim
                      ? 'Manual KHQR claim submitted. Awaiting manager review.'
                      : order.hasManualExternalPaymentClaimRecorded
                      ? 'Manual KHQR payment claimed locally. Submit online to continue review.'
                      : order.isManualClaimOutageOrder
                      ? 'Offline-captured order awaiting manual KHQR proof.'
                      : order.hasOfflineCashReplayFailure
                      ? 'Offline cash checkout could not sync automatically. Review the sync error before retrying.'
                      : order.isOfflineCashReplayInProgress
                      ? 'Offline cash checkout is syncing now.'
                      : order.isQueueBackedOfflineCashOrder
                      ? 'Offline cash checkout is queued for sync and will materialize when replay succeeds.'
                      : order.isAwaitingOutageSettlement
                      ? 'Offline-captured order awaiting legacy online settlement.'
                      : 'Offline outage order in recovery.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    formatOrderTime(order.placedAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    orderTypeLabel(order.orderType),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  for (var i = 0; i < order.lines.length; i++) ...[
                    if (i > 0) const Divider(height: 12),
                    OrderLineRow(line: order.lines[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
