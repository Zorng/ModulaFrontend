import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';

class ViewCartDetailLineTile extends StatelessWidget {
  const ViewCartDetailLineTile({
    super.key,
    required this.line,
  });

  final SaleLine line;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${line.quantity} × ${line.name}',
          style:
              Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (line.modifiers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line.modifiers.join(', '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

