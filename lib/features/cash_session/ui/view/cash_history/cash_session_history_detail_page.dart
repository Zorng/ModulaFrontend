import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_history/widgets/closed_session_summary_card.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_history_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_history_detail_provider.dart';

class CashSessionHistoryDetailPage extends ConsumerWidget {
  const CashSessionHistoryDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(cashSessionHistoryControllerProvider);
    final detailAsync = ref.watch(cashSessionHistoryDetailProvider(sessionId));
    CashSessionHistoryEntry? session;
    final list = historyState.sessions.asData?.value;
    if (list != null) {
      for (final entry in list) {
        if (entry.id == sessionId) {
          session = entry;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Closed Session Summary'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                      Text(
                        'Selected session: $sessionId',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _DetailInfoRow(
                        label: 'Status',
                        value: session == null
                            ? '-'
                            : CashSessionStatuses.normalize(session.status),
                      ),
                      const SizedBox(height: 8),
                      _DetailInfoRow(
                        label: 'Opened by',
                        value: session?.openedByName ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _DetailInfoRow(
                        label: 'Opened at',
                        value: _formatDateTime(session?.openedAt),
                      ),
                      const SizedBox(height: 8),
                      _DetailInfoRow(
                        label: 'Closed at',
                        value: _formatDateTime(session?.closedAt),
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
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({required this.label, required this.value});

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
