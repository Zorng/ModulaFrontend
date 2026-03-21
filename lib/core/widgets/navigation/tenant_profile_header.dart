import 'package:flutter/material.dart';

class TenantProfileHeader extends StatelessWidget {
  const TenantProfileHeader({
    super.key,
    required this.tenantName,
    required this.branchName,
    required this.initial,
    this.onTap,
  });

  final String tenantName;
  final String branchName;
  final String initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(14);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tenantName, overflow: TextOverflow.ellipsis, maxLines: 1),
              Text(
                branchName,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );

    final decoratedContent = Ink(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: content,
      ),
    );

    if (onTap == null) return decoratedContent;

    return Tooltip(
      message: 'Switch tenant',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: decoratedContent,
        ),
      ),
    );
  }
}
