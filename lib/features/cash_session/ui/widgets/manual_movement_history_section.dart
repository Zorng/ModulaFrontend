import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';

class ManualMovementHistorySection extends StatelessWidget {
  const ManualMovementHistorySection({super.key, required this.movements});

  final List<CashMovement> movements;

  @override
  Widget build(BuildContext context) {
    final manualMovements = movements
        .where(
          (movement) =>
              movement.movementType == CashMovementTypes.manualIn ||
              movement.movementType == CashMovementTypes.manualOut ||
              movement.movementType == CashMovementTypes.adjustment,
        )
        .toList(growable: false);
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
              'Recent Manual Movements',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Recent paid in, paid out, and adjustment entries.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (manualMovements.isEmpty)
              const _EmptyState(message: 'No manual movements recorded yet.')
            else if (isWide)
              _WideMovementTable(movements: manualMovements)
            else ...[
              for (final movement in manualMovements.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MovementListCard(movement: movement),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WideMovementTable extends StatelessWidget {
  const _WideMovementTable({required this.movements});

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
              headingTextStyle: AppTableTheme.headerText,
              dataTextStyle: AppTableTheme.cellText,
              columns: const [
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('USD')),
                DataColumn(label: Text('KHR')),
              ],
              rows: movements.take(10).map((movement) {
                return DataRow(
                  cells: [
                    DataCell(Text(_formatTime(movement.occurredAt))),
                    DataCell(Text(_movementLabel(movement.movementType))),
                    DataCell(Text(_reason(movement))),
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

class _MovementListCard extends StatelessWidget {
  const _MovementListCard({required this.movement});

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
            _reason(movement),
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
    CashMovementTypes.manualIn => 'Paid In',
    CashMovementTypes.manualOut => 'Paid Out',
    CashMovementTypes.adjustment => 'Adjustment',
    _ => type,
  };
}

String _reason(CashMovement movement) {
  final reason = (movement.reason ?? '').trim();
  return reason.isEmpty ? 'Manual movement' : reason;
}

String _formatTime(DateTime? time) {
  if (time == null) return '--:--';
  return DateFormat('hh:mm a').format(time.toLocal());
}

String _usd(double value) => value.toStringAsFixed(2);

String _khr(double value) => NumberFormat('#,##0').format(value);
