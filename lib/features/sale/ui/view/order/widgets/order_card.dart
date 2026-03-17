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
  });

  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;

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
                      color: orderStatusColor(order.status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: GestureDetector(
                      onTap: onStatusTap,
                      child: Text(
                        orderStatusLabel(order.status),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: orderStatusTextColor(order.status),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              if (order.isSettleableOpenTicket) ...[
                const SizedBox(height: 6),
                Text(
                  'Unpaid open ticket. Settlement remains available even when new pay-later orders are disabled.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else if (order.isLocalOutageOrder) ...[
                const SizedBox(height: 6),
                Text(
                  order.hasManualExternalPaymentClaimRecorded
                      ? 'Manual KHQR payment claimed. Awaiting manager review.'
                      : order.isManualClaimOutageOrder
                      ? 'Offline-captured order awaiting manual KHQR proof.'
                      : order.isAwaitingOutageSettlement
                      ? 'Offline-captured order awaiting online settlement.'
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
