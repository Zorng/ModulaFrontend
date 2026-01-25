import 'package:flutter/material.dart';

class OrderDetailSummaryRow extends StatelessWidget {
  const OrderDetailSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
  });

  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

