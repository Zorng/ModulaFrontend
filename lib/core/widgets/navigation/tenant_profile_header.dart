import 'package:flutter/material.dart';

class TenantProfileHeader extends StatelessWidget {
  const TenantProfileHeader({
    super.key,
    required this.tenantName,
    required this.branchName,
    required this.initial,
  });

  final String tenantName;
  final String branchName;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tenantName),
            Text(
              branchName,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }
}
