import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_utils.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/widgets/order_detail_summary_row.dart';

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
    final order = orders.firstWhere(
      (o) => o.number == orderNumber,
      orElse: () => Order(
        id: orderNumber,
        number: orderNumber,
        status: 'unknown',
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
            Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
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
                      value: order.paymentMethod == 'qr' ? 'QR / Transfer' : 'Cash',
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Current Status',
                      value: orderDetailStatusLabel(order.status),
                    ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: order.lines.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final line = order.lines[index];
                  final modifierText =
                      line.modifiers.isEmpty ? 'No modifiers' : line.modifiers.join(', ');
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
            const SizedBox(height: 16),
            Text('Payment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    OrderDetailSummaryRow(
                      label: 'Grand Total',
                      value: '\$${order.totalUsd.toStringAsFixed(2)}',
                      subValue: 'KHR ${order.totalKhr.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Received amount',
                      value: order.tenderCurrency == 'usd'
                          ? '\$${order.tenderAmount.toStringAsFixed(2)}'
                          : 'KHR ${order.tenderAmount.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    OrderDetailSummaryRow(
                      label: 'Change',
                      value: order.tenderCurrency == 'usd'
                          ? '\$${order.changeAmount.toStringAsFixed(2)}'
                          : 'KHR ${order.changeAmount.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
