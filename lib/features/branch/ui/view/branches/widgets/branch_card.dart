import 'package:flutter/material.dart';
import 'package:modular_pos/features/branch/domain/models/branch.dart';

/// Branch card widget - displays branch info in a card
class BranchCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback? onTap;

  const BranchCard({
    super.key,
    required this.branch,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (branch.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        branch.address!,
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 35),
              _StatusChip(
                status: branch.status,
                isActive: branch.isActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isActive;

  const _StatusChip({
    required this.status,
    required this.isActive,
  });

  String _formatStatus(String status) {
    final lower = status.toLowerCase().replaceAll('_', ' ');
    if (lower.isEmpty) return lower;
    return lower[0].toUpperCase() + lower.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive
        ? const Color(0xFFD4F4DD)
        : const Color(0xFFFFE0E0); 

    final textColor = isActive
        ? const Color(0xFF2E7D32)  
        : const Color(0xFFD32F2F); 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatStatus(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
      ),
    );
  }
}
