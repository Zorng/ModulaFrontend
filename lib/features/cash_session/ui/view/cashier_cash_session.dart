import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/register_status_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_session_bottom_action_area.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/start_session_modal.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_session_details_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_movement_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/add_cash_movement_modal.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/close_session_modal.dart';

class CashierCashSessionScreen extends ConsumerWidget {
  const CashierCashSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Session'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: sessionState.sessionStatus != SessionStatus.notStarted
                  ? _buildOpenSessionView(context, ref)
                  : _buildClosedSessionView(context, ref),
            ),
          ),
          _buildBottomActionArea(context, ref),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final notifier = ref.read(cashSessionViewModelProvider.notifier);

    final bool isSessionOpen = sessionState.sessionStatus == SessionStatus.open;
    final bool canCloseSession = isSessionOpen && sessionState.hasCashMovement;
    final bool isSessionClosed = sessionState.sessionStatus == SessionStatus.closed;

    return CashSessionBottomActionArea(
      isSessionOpen: isSessionOpen,
      onPressed: (isSessionOpen && !canCloseSession) || isSessionClosed
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Allows the modal to have a custom height
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (modalContext) {
                  if (canCloseSession) {
                    return CloseSessionModal(onSessionClosed: () {
                      Navigator.of(modalContext).pop();
                      notifier.closeSession();
                    });
                  } else {
                    return StartSessionModal(
                      onSessionStarted: (usdAmount, khrAmount) {
                        Navigator.of(modalContext).pop();
                        notifier.startSession(usdAmount, khrAmount);
                      },
                    );
                  }
                },
              );
            },
    );
  }

  List<Widget> _buildClosedSessionView(BuildContext context, WidgetRef ref) {
    return [
      const Text(
        'Attendence Status',
        style: TextStyle(
            fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      // Use the dynamic card with default values for the initial view.
      RegisterStatusCard(
        status: 'Checked In',
        statusColor: const Color(0xFF529E86),
        backgroundColor: const Color(0xFFE3F8ED),
      ),
    ];
  }

  List<Widget> _buildOpenSessionView(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final notifier = ref.read(cashSessionViewModelProvider.notifier);
    final isSessionClosed = sessionState.sessionStatus == SessionStatus.closed;
    return [
      ExpansionTile(
        title: const Text('Attendance Status'),
        initiallyExpanded: true,
        children: [
          RegisterStatusCard(
            status: isSessionClosed ? 'Checked Out' : 'Checked In',
            statusColor:
                isSessionClosed ? const Color(0xFFED533C) : const Color(0xFF529E86),
            backgroundColor:
                isSessionClosed ? const Color(0xFFFFF5F2) : const Color(0xFFE3F8ED),
          )
        ],
      ),
      ExpansionTile(
          title: const Text('Cash Session'),
          initiallyExpanded: true,
          children: [
            CashSessionDetailsCard(
                openFloatUsd: sessionState.openFloatUsd,
                openFloatKhr: sessionState.openFloatKhr,
                startTime: sessionState.startTime ?? DateTime.now(),
                endTime: sessionState.endTime,
                status: isSessionClosed ? 'Closed' : 'Open'),
          ]),
      const SizedBox(height: 16),
      const Text(
        'Cash Movement',
        style: TextStyle(
            fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      CashMovementCard(
        paidIn: sessionState.totalPaidIn,
        paidOut: sessionState.totalPaidOut,
        onAddCashMovement: isSessionClosed
            ? null // Disable button if session is closed
            : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Essential for keyboard handling
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (modalContext) {
                    return AddCashMovementModal(
                      onMovementAdded: (type, usdAmount, khrAmount) {
                        Navigator.of(modalContext).pop();
                        notifier.addCashMovement(type, usdAmount, khrAmount);
                      },
                    );
                  },
                );
              },
      ),
    ];
  }
}