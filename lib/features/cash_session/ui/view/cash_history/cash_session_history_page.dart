import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_history/widgets/closed_session_summary_card.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_history/widgets/cash_session_history_list_table.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/widgets/z_report_date_picker_row.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_history_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_history_detail_provider.dart';

class CashSessionHistoryPage extends ConsumerStatefulWidget {
  const CashSessionHistoryPage({super.key});

  @override
  ConsumerState<CashSessionHistoryPage> createState() =>
      _CashSessionHistoryPageState();
}

class _CashSessionHistoryPageState
    extends ConsumerState<CashSessionHistoryPage> {
  bool _didTriggerInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didTriggerInitialLoad) return;
    _didTriggerInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(cashSessionHistoryControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final historyState = ref.watch(cashSessionHistoryControllerProvider);
    final historyNotifier = ref.read(
      cashSessionHistoryControllerProvider.notifier,
    );
    final sessionsAsync = historyState.sessions;

    if (!AppBreakpoints.isLarge(width)) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZReportDatePickerRow(
                date: historyState.date,
                onPick: historyNotifier.setDateFilter,
                label: 'Filter by date',
                isFilterApplied: historyState.isDateFilterApplied,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountBadge(count: historyState.sessionCount),
                  if (historyState.isDateFilterApplied)
                    OutlinedButton(
                      onPressed: historyNotifier.clearDateFilter,
                      child: const Text('Clear filter'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _HistoryMobileListPanel(
                  sessionsAsync: sessionsAsync,
                  emptyMessage: historyState.isDateFilterApplied
                      ? 'No closed sessions found for this date.'
                      : 'No closed sessions found.',
                  onRetry: historyNotifier.refresh,
                  showDate: !historyState.isDateFilterApplied,
                  onOpen: (session) => context.pushNamed(
                    AppRoute.cashHistoryDetail.name,
                    pathParameters: {'sessionId': session.id},
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _WideHistoryControls(
              date: historyState.date,
              isDateFilterApplied: historyState.isDateFilterApplied,
              count: historyState.sessionCount,
              canGoToPreviousPage: historyState.canGoToPreviousPage,
              canGoToNextPage: historyState.canGoToNextPage,
              onPickDate: historyNotifier.setDateFilter,
              onClearFilter: historyNotifier.clearDateFilter,
              onPreviousPage: historyNotifier.previousPage,
              onNextPage: historyNotifier.nextPage,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _HistoryListPanel(
                sessionsAsync: sessionsAsync,
                emptyMessage: historyState.isDateFilterApplied
                    ? 'No closed sessions found for this date.'
                    : 'No closed sessions found.',
                onRetry: historyNotifier.refresh,
                onOpen: (session) => _showWideHistoryDetail(context, session),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryListPanel extends StatelessWidget {
  const _HistoryListPanel({
    required this.sessionsAsync,
    required this.emptyMessage,
    required this.onRetry,
    required this.onOpen,
  });

  final AsyncValue<List<CashSessionHistoryEntry>> sessionsAsync;
  final String emptyMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<CashSessionHistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  UserErrorMessage.build(
                    context: 'Failed to load closed sessions',
                    error: error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(child: Text(emptyMessage));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Closed Sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: CashSessionHistoryListTable(
                    sessions: sessions,
                    onOpen: onOpen,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryMobileListPanel extends StatelessWidget {
  const _HistoryMobileListPanel({
    required this.sessionsAsync,
    required this.emptyMessage,
    required this.onRetry,
    required this.showDate,
    required this.onOpen,
  });

  final AsyncValue<List<CashSessionHistoryEntry>> sessionsAsync;
  final String emptyMessage;
  final Future<void> Function() onRetry;
  final bool showDate;
  final ValueChanged<CashSessionHistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              UserErrorMessage.build(
                context: 'Failed to load closed sessions',
                error: error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(child: Text(emptyMessage));
        }
        return ListView.separated(
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _HistoryMobileCard(
              session: session,
              showDate: showDate,
              onTap: () => onOpen(session),
            );
          },
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count sessions'),
    );
  }
}

class _WideHistoryControls extends StatelessWidget {
  const _WideHistoryControls({
    required this.date,
    required this.isDateFilterApplied,
    required this.count,
    required this.canGoToPreviousPage,
    required this.canGoToNextPage,
    required this.onPickDate,
    required this.onClearFilter,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final DateTime date;
  final bool isDateFilterApplied;
  final int count;
  final bool canGoToPreviousPage;
  final bool canGoToNextPage;
  final ValueChanged<DateTime> onPickDate;
  final Future<void> Function() onClearFilter;
  final Future<void> Function() onPreviousPage;
  final Future<void> Function() onNextPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ZReportDatePickerRow(
                date: date,
                onPick: onPickDate,
                label: 'Filter by date',
                isFilterApplied: isDateFilterApplied,
              ),
              if (isDateFilterApplied)
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: OutlinedButton(
                    onPressed: onClearFilter,
                    child: const Text('Clear filter'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CountBadge(count: count),
        const SizedBox(width: 12),
        _WidePager(
          canGoToPreviousPage: canGoToPreviousPage,
          canGoToNextPage: canGoToNextPage,
          onPreviousPage: onPreviousPage,
          onNextPage: onNextPage,
        ),
      ],
    );
  }
}

class _WidePager extends StatelessWidget {
  const _WidePager({
    required this.canGoToPreviousPage,
    required this.canGoToNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final bool canGoToPreviousPage;
  final bool canGoToNextPage;
  final Future<void> Function() onPreviousPage;
  final Future<void> Function() onNextPage;

  @override
  Widget build(BuildContext context) {
    final compactFilledStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final compactOutlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: canGoToPreviousPage ? onPreviousPage : null,
          style: compactOutlinedStyle,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const Text('Previous'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: canGoToNextPage ? onNextPage : null,
          style: compactFilledStyle,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

Future<void> _showWideHistoryDetail(
  BuildContext context,
  CashSessionHistoryEntry session,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final detailAsync = ref.watch(
            cashSessionHistoryDetailProvider(session.id),
          );
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 56,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880, maxHeight: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Closed Session Summary',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected session: ${session.id}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _HistoryInfoRow(
                                      label: 'Status',
                                      value: CashSessionStatuses.normalize(
                                        session.status,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _HistoryInfoRow(
                                      label: 'Opened by',
                                      value: session.openedByName,
                                    ),
                                    const SizedBox(height: 8),
                                    _HistoryInfoRow(
                                      label: 'Opened at',
                                      value: _formatDateTime(session.openedAt),
                                    ),
                                    const SizedBox(height: 8),
                                    _HistoryInfoRow(
                                      label: 'Closed at',
                                      value: _formatDateTime(session.closedAt),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClosedSessionSummaryCard(
                              detailAsync: detailAsync,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _HistoryMobileCard extends StatelessWidget {
  const _HistoryMobileCard({
    required this.session,
    required this.showDate,
    required this.onTap,
  });

  final CashSessionHistoryEntry session;
  final bool showDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(status: session.status),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 12),
              _HistoryInfoRow(label: 'Opened by', value: session.openedByName),
              const SizedBox(height: 8),
              _HistoryInfoRow(
                label: 'Opened at',
                value: _formatMobileDateTime(
                  session.openedAt,
                  showDate: showDate,
                ),
              ),
              const SizedBox(height: 8),
              _HistoryInfoRow(
                label: 'Closed at',
                value: _formatMobileDateTime(
                  session.closedAt,
                  showDate: showDate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}

String _formatMobileDateTime(DateTime? value, {required bool showDate}) {
  if (value == null) return '-';
  return showDate
      ? DateFormat('dd MMM · hh:mm a').format(value)
      : DateFormat('hh:mm a').format(value);
}

class _HistoryInfoRow extends StatelessWidget {
  const _HistoryInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = CashSessionStatuses.normalize(status);
    final isForceClosed = normalized == CashSessionStatuses.forceClosed;
    final background = isForceClosed
        ? const Color(0xFFFFF5F2)
        : const Color(0xFFE3F8ED);
    final foreground = isForceClosed
        ? const Color(0xFFED533C)
        : const Color(0xFF529E86);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized == CashSessionStatuses.forceClosed
            ? 'Force Closed'
            : 'Closed',
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
