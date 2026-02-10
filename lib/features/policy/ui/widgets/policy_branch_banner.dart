import 'package:flutter/material.dart';

class PolicyBranchBanner extends StatelessWidget {
  const PolicyBranchBanner({
    super.key,
    required this.branchName,
    this.isSubtle = false,
  });

  final String branchName;
  final bool isSubtle;

  @override
  Widget build(BuildContext context) {
    const warningColor = Color(0xFFFF6B35);
    final colorScheme = Theme.of(context).colorScheme;

    // Subtle variant for mobile
    if (isSubtle) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'Editing: '),
                    TextSpan(
                      text: branchName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const TextSpan(text: ' Branch'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Regular variant for widescreen
    final warningBackground = warningColor.withValues(alpha: 0.08);
    final warningBorder = warningColor.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'Configuring Policy for '),
                      TextSpan(
                        text: branchName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const TextSpan(text: ' Branch'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All changes on this page will only apply to the $branchName branch. Other branches will not be affected.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }
}
