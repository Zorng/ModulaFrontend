import 'package:flutter/material.dart';

class PortalFeatureCard extends StatelessWidget {
  const PortalFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.badgeText,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;
    final trimmedBadge = badgeText?.trim();
    final showBadge = trimmedBadge != null && trimmedBadge.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: isDisabled ? 0.06 : 0.1,
                ),
                child: Icon(
                  icon,
                  color: isDisabled
                      ? theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        )
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDisabled
                      ? theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        )
                      : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showBadge) ...[
                const SizedBox(height: 4),
                Text(
                  trimmedBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

