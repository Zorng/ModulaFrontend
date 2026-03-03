import 'package:flutter/material.dart';

class TenantProfileHeader extends StatelessWidget {
  const TenantProfileHeader({
    super.key,
    required this.tenantName,
    required this.branchName,
    required this.initial,
    this.onBackPressed,
  });

  final String tenantName;
  final String branchName;
  final String initial;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onBackPressed != null) ...[
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to branches',
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
  }
}
