import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_movement_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/session_overview_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/guidelines_card.dart';

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

    void handleMovementAdded(
      String type,
      double usdAmount,
      double khrAmount,
      String reason,
    ) {
      if (!isSessionOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open a cash session to add a movement.'),
          ),
        );
        return;
      }
      notifier.addCashMovement(
        type,
        usdAmount,
        khrAmount,
        reason: reason,
      );
    }

    return SafeArea(
      child: hasNavigationRail
          ? _buildWideLayout(sessionState, handleMovementAdded)
          : _buildMobileLayout(sessionState, handleMovementAdded),
    );
  }

  Widget _buildMobileLayout(
    CashSessionState sessionState,
    void Function(String, double, double, String) onMovementAdded,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sessionState.error != null) _buildErrorCard(sessionState),
        const SessionOverviewCard(),
        const SizedBox(height: 16),
        const GuidelinesCard(),
        const SizedBox(height: 16),
        CashMovementCard(onAddCashMovement: onMovementAdded),
      ],
    );
  }

  Widget _buildWideLayout(
    CashSessionState sessionState,
    void Function(String, double, double, String) onMovementAdded,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (sessionState.error != null) _buildErrorCard(sessionState),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Session Overview and Guidelines
            Expanded(
              flex: 1,
              child: Column(
                children: const [
                  SessionOverviewCard(),
                  SizedBox(height: 16),
                  GuidelinesCard(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right column: Cash Movement Card
            Expanded(
              flex: 1,
              child: CashMovementCard(onAddCashMovement: onMovementAdded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard(CashSessionState sessionState) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          sessionState.error ?? 'Unable to load cash session.',
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }
}
