import 'package:flutter/material.dart';

class ReportingSectionCard extends StatelessWidget {
  const ReportingSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!)],
      ],
    );

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useStackedHeader =
                action != null && constraints.maxWidth < 520;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (action == null)
                  titleBlock
                else if (useStackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleBlock, const SizedBox(height: 12), action!],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 12),
                      action!,
                    ],
                  ),
                const SizedBox(height: 16),
                child,
              ],
            );
          },
        ),
      ),
    );
  }
}
