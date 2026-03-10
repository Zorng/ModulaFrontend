import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_error_message.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_movement_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_movement_context_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/manual_movement_history_section.dart';

class CashMovementPage extends ConsumerWidget {
  const CashMovementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final notifier = ref.read(cashSessionViewModelProvider.notifier);
    final isSessionOpen = sessionState.sessionStatus == SessionStatus.open;

    // Use screen width to determine navigation rail presence
    final screenWidth = MediaQuery.of(context).size.width;
    final hasNavigationRail = AppBreakpoints.isLarge(screenWidth);

    Future<CashMovementSubmitResult> handleMovementAdded(
      String type,
      double usdAmount,
      double khrAmount,
      String reason,
    ) async {
      if (!isSessionOpen) {
        return const CashMovementSubmitResult.failure(
          'Open a cash session to add a movement.',
        );
      }
      if (!sessionState.canRecordMovementType(type)) {
        return const CashMovementSubmitResult.failure(
          'You do not have permission to record this movement type.',
        );
      }
      await notifier.addCashMovement(
        type,
        usdAmount,
        khrAmount,
        reason: reason,
      );

      final latestState = ref.read(cashSessionViewModelProvider);
      if (latestState.error != null) {
        return CashMovementSubmitResult.failure(
          mapCashSessionErrorMessage(
            context: 'Unable to add cash movement',
            errorCode: latestState.errorCode,
            error: latestState.error,
          ),
        );
      }

      return const CashMovementSubmitResult.success();
    }

    return SafeArea(
      child: hasNavigationRail
          ? _buildWideLayout(sessionState, handleMovementAdded)
          : _buildMobileLayout(sessionState, handleMovementAdded),
    );
  }

  Widget _buildMobileLayout(
    CashSessionState sessionState,
    CashMovementSubmitCallback onMovementAdded,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sessionState.error != null) _buildErrorCard(sessionState),
        CashMovementCard(onAddCashMovement: onMovementAdded),
        const SizedBox(height: 16),
        ManualMovementHistorySection(movements: sessionState.movements),
      ],
    );
  }

  Widget _buildWideLayout(
    CashSessionState sessionState,
    CashMovementSubmitCallback onMovementAdded,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (sessionState.error != null) _buildErrorCard(sessionState),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: CashMovementCard(
                isWide: true,
                onAddCashMovement: onMovementAdded,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: CashMovementContextCard(sessionState: sessionState),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ManualMovementHistorySection(movements: sessionState.movements),
      ],
    );
  }

  Widget _buildErrorCard(CashSessionState sessionState) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          mapCashSessionErrorMessage(
            context: 'Unable to load cash session',
            errorCode: sessionState.errorCode,
            error: sessionState.error,
          ),
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }
}
