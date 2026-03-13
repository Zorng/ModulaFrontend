import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

class SessionOverviewCard extends ConsumerWidget {
  const SessionOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(authActiveBranchProvider);
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final theme = Theme.of(context);
    final branchName = branch?.name ?? 'No Branch';
    final openedByPill = _openedByPill(sessionState);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              branchName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _MetaPill(
              label: 'Opened by',
              value: openedByPill.value,
              textColor: openedByPill.textColor,
              backgroundColor: openedByPill.backgroundColor,
              borderColor: openedByPill.borderColor,
            ),
          ],
        ),
      ),
    );
  }

  _PillState _openedByPill(CashSessionState sessionState) {
    if (sessionState.hasOpenSession && sessionState.isOwnedByCurrentUser) {
      return _PillState(
        value: 'You at ${_formatDateTime(sessionState.startTime)}',
        textColor: const Color(0xFF047857),
        backgroundColor: const Color(0xFFECFDF5),
        borderColor: const Color(0xFFA7F3D0),
      );
    }

    if (sessionState.hasOpenSession && sessionState.isOccupiedByAnotherUser) {
      final owner = (sessionState.sessionOwnerLabel ?? '').trim();
      final ownerText = owner.isEmpty ? 'Another account' : owner;
      return _PillState(
        value: '$ownerText at ${_formatDateTime(sessionState.startTime)}',
        textColor: const Color(0xFF047857),
        backgroundColor: const Color(0xFFECFDF5),
        borderColor: const Color(0xFFA7F3D0),
      );
    }

    return const _PillState(
      value: 'Not opened',
      textColor: Color(0xFF475467),
      backgroundColor: Color(0xFFF2F4F7),
      borderColor: Color(0xFFD0D5DD),
    );
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('dd MMM yyyy, hh:mm a').format(value.toLocal());
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.value,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillState {
  const _PillState({
    required this.value,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String value;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
}
