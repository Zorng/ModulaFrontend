import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_error_message.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/session_overview_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/session_action_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/current_session_summary_card.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/session_sales_section.dart';

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
            ? _buildWideLayout(context, sessionState, notifier, isSessionOpen)
            : _buildMobileLayout(
                context,
                sessionState,
                notifier,
                isSessionOpen,
              ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    CashSessionState sessionState,
    CashSessionViewModel notifier,
    bool isSessionOpen,
  ) {
    final showSummary = _showsSummary(sessionState);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (sessionState.error != null) _buildErrorBanner(sessionState),
        const SessionOverviewCard(),
        const SizedBox(height: 16),
        SessionActionCard(sessionState: sessionState, notifier: notifier),
        if (showSummary) ...[
          const SizedBox(height: 16),
          const CurrentSessionSummaryCard(),
        ],
        const SizedBox(height: 16),
        SessionSalesSection(
          sessionStatus: sessionState.sessionStatus,
          sales: sessionState.sales,
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    CashSessionState sessionState,
    CashSessionViewModel notifier,
    bool isSessionOpen,
  ) {
    final showSummary = _showsSummary(sessionState);
    final isNotStarted = sessionState.sessionStatus == SessionStatus.notStarted;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        if (sessionState.error != null) _buildErrorBanner(sessionState),
        if (showSummary && isNotStarted)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SessionOverviewCard(),
                      SizedBox(height: 24),
                      Expanded(
                        child: CurrentSessionSummaryCard(
                          stretchPlaceholder: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: SessionActionCard(
                    sessionState: sessionState,
                    notifier: notifier,
                  ),
                ),
              ],
            ),
          )
        else if (showSummary)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 3,
                child: Column(
                  children: [
                    SessionOverviewCard(),
                    SizedBox(height: 24),
                    CurrentSessionSummaryCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: SessionActionCard(
                  sessionState: sessionState,
                  notifier: notifier,
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 3, child: SessionOverviewCard()),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: SessionActionCard(
                  sessionState: sessionState,
                  notifier: notifier,
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        SessionSalesSection(
          sessionStatus: sessionState.sessionStatus,
          sales: sessionState.sales,
        ),
      ],
    );
  }

  bool _showsSummary(CashSessionState sessionState) {
    return sessionState.isOwnedByCurrentUser ||
        sessionState.sessionStatus == SessionStatus.notStarted;
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
}
