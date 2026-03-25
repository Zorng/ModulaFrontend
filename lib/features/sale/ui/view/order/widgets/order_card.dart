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
    this.actions = const <OrderCardAction>[],
    this.compact = false,
    this.statusLabelBuilder = _defaultStatusLabel,
    this.statusColorBuilder = _defaultStatusColor,
    this.statusTextColorBuilder = _defaultStatusTextColor,
  });

  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;
  final List<OrderCardAction> actions;
  final bool compact;
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
    final theme = Theme.of(context);
    final previewLines = compact ? 2 : 3;
    final visibleLines = order.lines.take(previewLines).toList(growable: false);
    final remainingLineCount = order.lines.length - visibleLines.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        color: theme.colorScheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
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
                          orderCardTitle(order.number),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _orderSubtitle(order),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    PopupMenuButton<OrderCardAction>(
                      tooltip: 'Order actions',
                      onSelected: (action) => action.onSelected(),
                      itemBuilder: (context) => [
                        for (final action in actions)
                          PopupMenuItem<OrderCardAction>(
                            value: action,
                            child: Row(
                              children: [
                                Icon(action.icon, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    action.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _OrderMetaChip(
                    icon: Icons.schedule_outlined,
                    label: formatOrderTime(order.placedAt.toLocal()),
                  ),
                  _OrderMetaChip(
                    icon: Icons.receipt_long_outlined,
                    label: orderTypeLabel(order.orderType),
                  ),
                  _OrderMetaChip(
                    icon: Icons.shopping_bag_outlined,
                    label:
                        '${order.lines.length} item${order.lines.length == 1 ? '' : 's'}',
                  ),
                ],
              ),
              if (_helperCopy(order) != null) ...[
                const SizedBox(height: 6),
                Text(
                  _helperCopy(order)!,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order (${order.lines.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < visibleLines.length; i++) ...[
                      if (i > 0) const Divider(height: 12),
                      OrderLineRow(line: visibleLines[i]),
                    ],
                    if (remainingLineCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'See $remainingLineCount more',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _OrderStatusPill(
                    label: statusLabelBuilder(order),
                    backgroundColor: statusColorBuilder(order),
                    foregroundColor: statusTextColorBuilder(order),
                    onTap: onStatusTap,
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                  Text(
                    '\$${order.totalUsd.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderCardAction {
  const OrderCardAction({
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
}

class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: foregroundColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

class _OrderMetaChip extends StatelessWidget {
  const _OrderMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _orderSubtitle(Order order) {
  if (order.hasPendingRemoteManualPaymentClaim) {
    return 'External payment claim awaiting review';
  }
  if (order.isQueueBackedOfflineCashOrder) {
    return 'Offline-captured order syncing back to the server';
  }
  if (order.isLocalOutageOrder) {
    return 'Local recovery order';
  }
  return 'Fulfillment queue';
}

String? _helperCopy(Order order) {
  if (order.isSettleableOpenTicket) {
    return 'Pay-later ticket still awaiting settlement. Fulfillment can continue while payment stays open.';
  }
  if (order.hasPendingRemoteManualPaymentClaim) {
    return 'Manual payment claim submitted. Open detail to review the claim and continue manager approval.';
  }
  if (!order.isLocalOutageOrder) return null;
  if (order.hasRejectedManualExternalPaymentClaim) {
    return 'Manual KHQR claim was rejected. Review and resubmit if needed.';
  }
  if (order.hasSubmittedManualExternalPaymentClaim) {
    return 'Manual KHQR claim submitted. Awaiting manager review.';
  }
  if (order.hasManualExternalPaymentClaimRecorded) {
    return 'Manual KHQR payment claimed locally. Submit online to continue review.';
  }
  if (order.isManualClaimOutageOrder) {
    return 'Offline-captured order awaiting manual KHQR proof.';
  }
  if (order.hasOfflineCashReplayFailure) {
    return 'Offline cash checkout could not sync automatically. Review the sync error before retrying.';
  }
  if (order.isOfflineCashReplayInProgress) {
    return 'Offline cash checkout is syncing now.';
  }
  if (order.isQueueBackedOfflineCashOrder) {
    return 'Offline cash checkout is queued for sync and will materialize when replay succeeds.';
  }
  if (order.isAwaitingOutageSettlement) {
    return 'Offline-captured order awaiting legacy online settlement.';
  }
  return 'Offline outage order in recovery.';
}
