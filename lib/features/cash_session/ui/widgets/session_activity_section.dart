import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

class SessionActivitySection extends StatelessWidget {
  const SessionActivitySection({
    super.key,
    required this.sessionStatus,
    required this.movements,
  });

  final SessionStatus sessionStatus;
  final List<CashMovement> movements;

  bool get _hasSession => sessionStatus != SessionStatus.notStarted;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Operational ledger activity recorded for this cash session.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (!_hasSession)
              _EmptyState(
                message: 'Open a cash session to start tracking activity.',
              )
            else if (movements.isEmpty)
              _EmptyState(
                message: 'No activity has been recorded for this session yet.',
              )
            else if (isWide)
              _WideActivityTable(movements: movements)
            else ...[
              for (final movement in movements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityListCard(movement: movement),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WideActivityTable extends StatelessWidget {
  const _WideActivityTable({required this.movements});

  final List<CashMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTableTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 96,
            ),
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(
                AppTableTheme.headerBackground,
              ),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              headingTextStyle: AppTableTheme.headerText,
              dataTextStyle: AppTableTheme.cellText,
              dividerThickness: 0.6,
              columns: const [
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Source')),
                DataColumn(label: Text('Details')),
                DataColumn(label: Text('USD')),
                DataColumn(label: Text('KHR')),
              ],
              rows: movements.map((movement) {
                return DataRow(
                  cells: [
                    DataCell(Text(_formatTime(movement.occurredAt))),
                    DataCell(Text(_movementLabel(movement.movementType))),
                    DataCell(Text(_sourceLabel(movement.sourceRefType))),
                    DataCell(Text(_detailsLabel(movement))),
                    DataCell(Text(_usd(movement.amountUsd))),
                    DataCell(Text(_khr(movement.amountKhr))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityListCard extends StatelessWidget {
  const _ActivityListCard({required this.movement});

  final CashMovement movement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _movementLabel(movement.movementType),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatTime(movement.occurredAt),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _detailsLabel(movement),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('USD ${_usd(movement.amountUsd)}')),
              Expanded(child: Text('KHR ${_khr(movement.amountKhr)}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
      ),
    );
  }
}

String _movementLabel(String type) {
  return switch (type) {
    CashMovementTypes.saleIn => 'Sale In',
    CashMovementTypes.refundCash => 'Refund',
    CashMovementTypes.manualIn => 'Paid In',
    CashMovementTypes.manualOut => 'Paid Out',
    CashMovementTypes.adjustment => 'Adjustment',
    _ => type,
  };
}

String _sourceLabel(String type) {
  return switch (type.trim().toUpperCase()) {
    'SALE' => 'Sale',
    'VOID' => 'Void',
    'MANUAL' => 'Manual',
    _ => type,
  };
}

String _detailsLabel(CashMovement movement) {
  final reason = (movement.reason ?? '').trim();
  if (reason.isNotEmpty) return reason;
  final sourceRefId = (movement.sourceRefId ?? '').trim();
  if (sourceRefId.isNotEmpty) return sourceRefId;
  return _sourceLabel(movement.sourceRefType);
}

String _formatTime(DateTime? time) {
  if (time == null) return '--:--';
  return DateFormat('hh:mm a').format(time.toLocal());
}

String _usd(double value) => value.toStringAsFixed(2);

String _khr(double value) => NumberFormat('#,##0').format(value);
