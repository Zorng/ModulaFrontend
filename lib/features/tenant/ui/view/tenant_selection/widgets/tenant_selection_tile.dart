import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';

class TenantSelectionTile extends StatelessWidget {
  const TenantSelectionTile({
    super.key,
    required this.membership,
    this.onTap,
    this.enabled = true,
  });

  final TenantMembership membership;
  final VoidCallback? onTap;
  final bool enabled;

  // Placeholder fields — wire up when data is available
  String? get tenantImageUrl => null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tenantName = membership.tenantName.trim().isEmpty
        ? membership.tenantId
        : membership.tenantName.trim();
    final role = membership.role.trim().isEmpty ? 'Member' : membership.role;
    final initial = tenantName.substring(0, 1).toUpperCase();

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _TenantAvatar(
                imageUrl: tenantImageUrl,
                initial: initial,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _RoleBadge(
                      role: role,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: enabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantAvatar extends StatelessWidget {
  const _TenantAvatar({
    required this.imageUrl,
    required this.initial,
    required this.colorScheme,
    required this.textTheme,
  });

  final String? imageUrl;
  final String initial;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initial,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.role,
    required this.colorScheme,
    required this.textTheme,
  });

  final String role;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
