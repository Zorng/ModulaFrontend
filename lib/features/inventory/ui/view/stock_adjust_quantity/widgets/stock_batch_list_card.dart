import 'package:flutter/material.dart';

import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';

class StockBatchListCard extends StatelessWidget {
  const StockBatchListCard({
    super.key,
    required this.batches,
    required this.selectedId,
    required this.item,
    required this.onSelected,
  });

  final List<StockBatch> batches;
  final String? selectedId;
  final StockItem item;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batches',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < batches.length; i++) ...[
              _BatchTile(
                batch: batches[i],
                isSelected: batches[i].id == selectedId,
                item: item,
                onTap: () => onSelected(batches[i].id),
              ),
              if (i < batches.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({
    required this.batch,
    required this.isSelected,
    required this.item,
    required this.onTap,
  });

  final StockBatch batch;
  final bool isSelected;
  final StockItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Restock date: ${batch.receivedDate}'),
          Text('Expiry date: ${batch.expiryDate ?? 'No expiry'}'),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          StockQuantityFormatter(
            baseQty: batch.onHand,
            pieceSize: item.pieceSize,
            baseUnit: item.baseUnit,
          ).format(),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, size: 16) : null,
      onTap: onTap,
    );
  }
}

