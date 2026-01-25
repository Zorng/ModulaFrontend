import 'package:flutter/material.dart';

class SaleCartPaymentCard extends StatelessWidget {
  const SaleCartPaymentCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onSelected,
    this.body,
  });

  final String title;
  final bool selected;
  final VoidCallback? onSelected;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelected != null;
    return GestureDetector(
      onTap: onSelected,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<bool>(
                groupValue: selected ? true : null,
                onChanged: (_) {
                  if (enabled) {
                    onSelected!();
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Radio<bool>(value: true, enabled: enabled),
                  ],
                ),
              ),
              if (body != null) ...[const SizedBox(height: 8), body!],
            ],
          ),
        ),
      ),
    );
  }
}
