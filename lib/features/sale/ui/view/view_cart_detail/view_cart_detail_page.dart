import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/view_carts_formatters.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/widgets/view_cart_detail_line_tile.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/widgets/view_cart_detail_status_chip.dart';

class ViewCartDetailPage extends StatelessWidget {
  const ViewCartDetailPage({super.key, required this.summary});

  final SaleSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = viewCartsStateColor(summary.state);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text('Cart Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  viewCartsFormatTime(summary.createdAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ViewCartDetailStatusChip(
                  label: viewCartsStateLabel(summary.state),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...summary.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ViewCartDetailLineTile(line: line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

