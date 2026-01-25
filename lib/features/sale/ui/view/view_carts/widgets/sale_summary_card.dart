import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/view_carts_formatters.dart';

class SaleSummaryCard extends StatelessWidget {
  const SaleSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
    this.onVoid,
  });

  final SaleSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onVoid;

  @override
  Widget build(BuildContext context) {
    final stateColor = viewCartsStateColor(summary.state);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  GestureDetector(
                    onTap: onVoid,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        viewCartsStateLabel(summary.state),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: stateColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary.lines
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${line.quantity} × ${line.name}'
                          '${line.modifiers.isNotEmpty ? ' (${line.modifiers.join(', ')})' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
