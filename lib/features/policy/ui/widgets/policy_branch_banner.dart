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
    final warningBackground = warningColor.withValues(alpha: 0.08);
    final warningBorder = warningColor.withValues(alpha: 0.2);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSubtle ? 12 : 16,
        vertical: isSubtle ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: isSubtle
            ? colorScheme.surfaceContainerHighest
            : warningBackground,
        borderRadius: BorderRadius.circular(isSubtle ? 8 : 12),
        border: Border.all(
          color: isSubtle ? colorScheme.outlineVariant : warningBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: isSubtle ? 18 : 20,
            color: isSubtle ? colorScheme.onSurfaceVariant : warningColor,
          ),
          SizedBox(width: isSubtle ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style:
                        (isSubtle
                                ? Theme.of(context).textTheme.bodySmall
                                : Theme.of(context).textTheme.bodyMedium)
                            ?.copyWith(
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
                const SizedBox(height: 4),
                Text(
                  'All changes on this page will only apply to the $branchName branch. Other branches will not be affected.',
                  style:
                      (isSubtle
                              ? Theme.of(context).textTheme.bodySmall
                              : Theme.of(context).textTheme.bodySmall)
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                ),
              ],
            ),
          ),
  
        ],
      ),
    );
  }
}
