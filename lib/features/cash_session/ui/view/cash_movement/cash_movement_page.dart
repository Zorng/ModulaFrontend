import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/add_cash_movement_modal.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_movement_card.dart';

class CashMovementPage extends ConsumerWidget {
  const CashMovementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final notifier = ref.read(cashSessionViewModelProvider.notifier);
    final isSessionOpen = sessionState.sessionStatus == SessionStatus.open;
    final paidIn = sessionState.totalPaidIn;
    final paidOut = sessionState.totalPaidOut;

    void openMovementModal() {
      if (!isSessionOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open a cash session to add a movement.'),
          ),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (modalContext) {
          return AddCashMovementModal(
            onMovementAdded: (type, usdAmount, khrAmount, reason) {
              Navigator.of(modalContext).pop();
              notifier.addCashMovement(
                type,
                usdAmount,
                khrAmount,
                reason: reason,
              );
            },
          );
        },
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (sessionState.error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  sessionState.error ?? 'Unable to load cash session.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          CashMovementCard(
            onAddCashMovement: openMovementModal,
            paidIn: paidIn,
            paidOut: paidOut,
          ),
        ],
      ),
    );
  }
}
