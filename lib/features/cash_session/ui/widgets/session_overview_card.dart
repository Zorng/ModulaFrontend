import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

/// A card that displays session overview information including branch and session status.
class SessionOverviewCard extends ConsumerWidget {
  const SessionOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final branch = ref.watch(authActiveBranchProvider);
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final branchName = branch?.name ?? 'No Branch';
    final (statusText, statusColor) = switch (sessionState.sessionStatus) {
      SessionStatus.open => ('Active', const Color(0xFF10B981)),
      SessionStatus.closed => ('Closed', const Color(0xFFED533C)),
      SessionStatus.forceClosed => ('Force Closed', const Color(0xFFB45309)),
      SessionStatus.notStarted => ('No Active Session', Colors.grey),
    };

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session overview',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              label: 'Branch',
              value: branchName,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              label: 'Session Status',
              statusText: statusText,
              statusColor: statusColor,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String statusText,
    required Color statusColor,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
