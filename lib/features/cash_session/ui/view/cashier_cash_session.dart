import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_session_bottom_action_area.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/start_session_modal.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_session_details_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/close_session_modal.dart';

class CashSessionScreen extends ConsumerWidget {
  const CashSessionScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final isSmall = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              centerTitle: false,
              title: const Text('Cash Session'),
              automaticallyImplyLeading: false,
              leading: isSmall
                  ? AppBackButton(
                      icon: Icons.home_outlined,
                      tooltip: 'Home',
                      onPressed: () => context.go(AppRoute.portal.path),
                    )
                  : null,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sessionState.error != null)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      UserErrorMessage.build(
                        context: 'Failed to load cash session',
                        error: sessionState.error,
                      ),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    final bool canCloseSession = isSessionOpen;
    final bool isBusy = sessionState.isLoading;
    final String statusLabel = switch (sessionState.sessionStatus) {
      SessionStatus.notStarted => 'No active session',
      SessionStatus.open => 'Session open',
      SessionStatus.closed => 'Session closed',
    };

    return CashSessionBottomActionArea(
      isSessionOpen: isSessionOpen,
      message: statusLabel,
      onPressed: isBusy
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                isScrollControlled:
                    true, // Allows the modal to have a custom height
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (modalContext) {
                  if (canCloseSession) {
                    return CloseSessionModal(
                      onSessionClosed: (usd, khr, note) {
                        Navigator.of(modalContext).pop();
                        notifier.closeSession(
                          countedUsd: usd,
                          countedKhr: khr,
                          note: note,
                        );
                      },
                    );
                  } else {
                    return StartSessionModal(
                      onSessionStarted: (usdAmount, khrAmount, note) {
                        Navigator.of(modalContext).pop();
                        notifier.startSession(
                          usdAmount: usdAmount,
                          khrAmount: khrAmount,
                          note: note,
                        );
                      },
                    );
                  }
                },
              );
            },
    );
  }

  List<Widget> _buildClosedSessionView(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashSessionViewModelProvider);
    final registerName = state.registerName ?? 'Register';
    return [
      _buildRegisterSelector(ref),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('No active session for $registerName'),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildOpenSessionView(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final isSessionClosed = sessionState.sessionStatus == SessionStatus.closed;
    return [
      _buildRegisterSelector(ref),
      const SizedBox(height: 12),
      ExpansionTile(
        title: const Text('Cash Session'),
        initiallyExpanded: true,
        children: [
          CashSessionDetailsCard(
            openFloatUsd: sessionState.openFloatUsd,
            openFloatKhr: sessionState.openFloatKhr,
            startTime: sessionState.startTime ?? DateTime.now(),
            endTime: sessionState.endTime,
            status: isSessionClosed ? 'Closed' : 'Open',
          ),
        ],
      ),
    ];
  }

  Widget _buildRegisterSelector(WidgetRef ref) {
    final state = ref.watch(cashSessionViewModelProvider);
    final notifier = ref.read(cashSessionViewModelProvider.notifier);
    if (state.registers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: const Text('No registers available'),
      );
    }
    final currentId = state.registerId ?? state.registers.first.id;
    return DropdownButtonFormField<String>(
      key: ValueKey(currentId),
      initialValue: currentId,
      decoration: const InputDecoration(
        labelText: 'Register',
        border: OutlineInputBorder(),
      ),
      items: state.registers
          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
          .toList(),
      onChanged: state.isLoading
          ? null
          : (value) {
              if (value != null && value != state.registerId) {
                notifier.load(registerId: value);
              }
            },
    );
  }
}
