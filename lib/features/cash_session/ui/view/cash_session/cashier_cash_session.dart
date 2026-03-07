import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_error_message.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/session_overview_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/start_session_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_session_details_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/close_session_modal.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/force_close_session_modal.dart';

class CashSessionScreen extends ConsumerWidget {
  const CashSessionScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(cashSessionViewModelProvider);
    final notifier = ref.read(cashSessionViewModelProvider.notifier);

    // Use screen width to determine navigation rail presence
    final screenWidth = MediaQuery.of(context).size.width;
    final hasNavigationRail = AppBreakpoints.isLarge(screenWidth);

    final isSessionOpen = sessionState.sessionStatus == SessionStatus.open;
    final isSessionClosed =
        sessionState.sessionStatus == SessionStatus.closed ||
        sessionState.sessionStatus == SessionStatus.forceClosed;
    final isNoSession = sessionState.sessionStatus == SessionStatus.notStarted;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              centerTitle: false,
              title: const Text('Cash Session'),
              automaticallyImplyLeading: false,
              leading: hasNavigationRail
                  ? null
                  : AppBackButton(
                      icon: Icons.home_outlined,
                      tooltip: 'Home',
                      onPressed: () => context.go(AppRoute.portal.path),
                    ),
            )
          : null,
      body: SafeArea(
        child: hasNavigationRail
            ? _buildWideLayout(
                context,
                sessionState,
                notifier,
                isNoSession,
                isSessionOpen,
                isSessionClosed,
              )
            : _buildMobileLayout(
                context,
                sessionState,
                notifier,
                isNoSession,
                isSessionOpen,
                isSessionClosed,
              ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    CashSessionState sessionState,
    CashSessionViewModel notifier,
    bool isNoSession,
    bool isSessionOpen,
    bool isSessionClosed,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (sessionState.error != null) _buildErrorBanner(sessionState),
        const SessionOverviewCard(),
        const SizedBox(height: 16),
        if (isNoSession)
          _buildStartSessionCard(context, notifier)
        else if (isSessionOpen || isSessionClosed)
          ..._buildSessionDetailsSection(
            context,
            sessionState,
            notifier,
            isSessionOpen,
            isSessionClosed,
          ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    CashSessionState sessionState,
    CashSessionViewModel notifier,
    bool isNoSession,
    bool isSessionOpen,
    bool isSessionClosed,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        if (sessionState.error != null) _buildErrorBanner(sessionState),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Session Overview
            Expanded(
              flex: 1,
              child: const SessionOverviewCard(),
            ),
            const SizedBox(width: 24),
            // Right column: Start Session or Session Details
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  if (isNoSession)
                    _buildStartSessionCard(context, notifier)
                  else if (isSessionOpen || isSessionClosed)
                    ..._buildSessionDetailsSection(
                      context,
                      sessionState,
                      notifier,
                      isSessionOpen,
                      isSessionClosed,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner(CashSessionState sessionState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mapCashSessionErrorMessage(
                context: 'Failed to load cash session',
                errorCode: sessionState.errorCode,
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
    );
  }

  Widget _buildStartSessionCard(
    BuildContext context,
    CashSessionViewModel notifier,
  ) {
    return StartSessionCard(
      onSessionStarted: (usd, khr, note) {
        notifier.startSession(usdAmount: usd, khrAmount: khr, note: note);
      },
    );
  }

  List<Widget> _buildSessionDetailsSection(
    BuildContext context,
    CashSessionState sessionState,
    CashSessionViewModel notifier,
    bool isSessionOpen,
    bool isSessionClosed,
  ) {
    return [
      CashSessionDetailsCard(
        openFloatUsd: sessionState.openFloatUsd,
        openFloatKhr: sessionState.openFloatKhr,
        startTime: sessionState.startTime ?? DateTime.now(),
        endTime: sessionState.endTime,
        status: switch (sessionState.sessionStatus) {
          SessionStatus.forceClosed => 'Force Closed',
          SessionStatus.closed => 'Closed',
          _ => 'Open',
        },
      ),
      const SizedBox(height: 16),
      if (isSessionOpen)
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: sessionState.isLoading
                    ? null
                    : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (modalContext) {
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
                          },
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFED533C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close Cash Session'),
              ),
            ),
            if (sessionState.canForceClose) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: sessionState.isLoading
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (modalContext) {
                              return ForceCloseSessionModal(
                                onForceClosed: (usd, khr, reason, note) {
                                  Navigator.of(modalContext).pop();
                                  notifier.forceCloseSession(
                                    countedUsd: usd,
                                    countedKhr: khr,
                                    reason: reason,
                                    note: note,
                                  );
                                },
                              );
                            },
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFB45309)),
                  ),
                  child: const Text('Force Close Session'),
                ),
              ),
            ],
          ],
        ),
    ];
  }
}
