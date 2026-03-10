import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';

class CashSessionHistoryListTable extends StatelessWidget {
  const CashSessionHistoryListTable({
    super.key,
    required this.sessions,
    required this.onOpen,
  });

  final List<CashSessionHistoryEntry> sessions;
  final ValueChanged<CashSessionHistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTableTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              color: AppTableTheme.headerBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: _HeaderCell('Status')),
                  Expanded(flex: 3, child: _HeaderCell('Opened by')),
                  Expanded(flex: 3, child: _HeaderCell('Opened at')),
                  Expanded(flex: 3, child: _HeaderCell('Closed at')),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTableTheme.divider),
            Expanded(
              child: ListView.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTableTheme.divider),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _HistoryRow(
                    session: session,
                    onTap: () => onOpen(session),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session, required this.onTap});

  final CashSessionHistoryEntry session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(flex: 2, child: _StatusPill(status: session.status)),
              Expanded(
                flex: 3,
                child: _BodyCell(session.openedByName, alignEnd: false),
              ),
              Expanded(
                flex: 3,
                child: _BodyCell(
                  _formatDateTime(session.openedAt),
                  alignEnd: false,
                ),
              ),
              Expanded(
                flex: 3,
                child: _BodyCell(
                  _formatDateTime(session.closedAt),
                  alignEnd: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTableTheme.headerText);
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.value, {required this.alignEnd});

  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        value,
        style: AppTableTheme.cellText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = CashSessionStatuses.normalize(status);
    final isForceClosed = normalized == CashSessionStatuses.forceClosed;
    final decoration = isForceClosed
        ? AppTableTheme.dangerDecoration
        : AppTableTheme.healthyDecoration;
    final textStyle = isForceClosed
        ? AppTableTheme.dangerText
        : AppTableTheme.healthyText;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: decoration,
        child: Text(
          normalized == CashSessionStatuses.forceClosed
              ? 'Force Closed'
              : 'Closed',
          style: textStyle,
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}
