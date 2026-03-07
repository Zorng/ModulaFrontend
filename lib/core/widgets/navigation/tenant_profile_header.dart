import 'package:flutter/material.dart';

class TenantProfileHeader extends StatelessWidget {
  const TenantProfileHeader({
    super.key,
    required this.tenantName,
    required this.branchName,
    required this.initial,
    this.onBackPressed,
    this.backTooltip,
    this.onTap,
  });

  final String tenantName;
  final String branchName;
  final String initial;
  final VoidCallback? onBackPressed;
  final String? backTooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onBackPressed != null) ...[
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back),
            tooltip: backTooltip ?? 'Back',
          ),
          const SizedBox(width: 4),
        ],
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

    if (onTap == null) return content;

    return Tooltip(
      message: 'Switch tenant',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: content,
          ),
        ),
      ),
    );
  }
}
