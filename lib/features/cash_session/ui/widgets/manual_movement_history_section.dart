import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';

class ManualMovementHistorySection extends StatefulWidget {
  const ManualMovementHistorySection({super.key, required this.movements});

  final List<CashMovement> movements;

  @override
  State<ManualMovementHistorySection> createState() =>
      _ManualMovementHistorySectionState();
}

class _ManualMovementHistorySectionState
    extends State<ManualMovementHistorySection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final manualMovements =
        widget.movements
            .where(
              (movement) =>
                  movement.movementType == CashMovementTypes.manualIn ||
                  movement.movementType == CashMovementTypes.manualOut ||
                  movement.movementType == CashMovementTypes.adjustment,
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aTime =
                a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

    final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);
    final defaultVisibleCount = isWide ? 10 : 8;
    final hasMore = manualMovements.length > defaultVisibleCount;
    final visibleMovements = _showAll || !hasMore
        ? manualMovements
        : manualMovements.take(defaultVisibleCount).toList(growable: false);
    final subtitle = manualMovements.isEmpty
        ? 'Recent paid in, paid out, and adjustment entries.'
        : _showAll || !hasMore
        ? 'Showing all ${manualMovements.length} manual movements.'
        : 'Showing the latest ${visibleMovements.length} of ${manualMovements.length} manual movements.';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Manual Movements',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (manualMovements.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _CountBadge(count: manualMovements.length),
                ],
              ],
            ),
            if (hasMore) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                  child: Text(
                    _showAll
                        ? 'View less'
                        : 'View all (${manualMovements.length})',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (manualMovements.isEmpty)
              const _EmptyState(message: 'No manual movements recorded yet.')
            else if (isWide)
              _WideMovementTable(movements: visibleMovements)
            else
              Column(
                children: [
                  for (var index = 0; index < visibleMovements.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleMovements.length - 1 ? 0 : 12,
                      ),
                      child: _MovementListCard(
                        movement: visibleMovements[index],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$count entries',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

class _WideMovementTable extends StatelessWidget {
  static const _timeColumnWidth = 92.0;
  static const _typeColumnWidth = 75.0;
  static const _amountColumnWidth = 100.0;
  static const _reasonColumnWidth = 340.0;

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
              horizontalMargin: 18,
              columnSpacing: 12,
              columns: const [
                DataColumn(
                  label: SizedBox(width: _timeColumnWidth, child: Text('Time')),
                ),
                DataColumn(
                  label: SizedBox(width: _typeColumnWidth, child: Text('Type')),
                ),
                DataColumn(
                  label: SizedBox(width: _amountColumnWidth, child: Text('USD')),
                ),
                DataColumn(
                  label: SizedBox(width: _amountColumnWidth, child: Text('KHR')),
                ),
                DataColumn(
                  label: SizedBox(
                    width: _reasonColumnWidth,
                    child: Text('Reason'),
                  ),
                ),
              ],
              rows: movements.map((movement) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: _timeColumnWidth,
                        child: Text(
                          _formatTime(movement.occurredAt),
                          style: AppTableTheme.cellText.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: _typeColumnWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _MovementTypeBadge(
                            type: movement.movementType,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: _amountColumnWidth,
                        child: Text(
                          _usd(movement.amountUsd),
                          style: AppTableTheme.cellText.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: _amountColumnWidth,
                        child: Text(
                          _khr(movement.amountKhr),
                          style: AppTableTheme.cellText.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: _reasonColumnWidth,
                        child: Text(
                          _reason(movement),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
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
    final textTheme = Theme.of(context).textTheme;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MovementTypeBadge(type: movement.movementType),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatTime(movement.occurredAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _reason(movement),
            style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AmountLine(
                  label: 'USD',
                  value: _usd(movement.amountUsd),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AmountLine(
                  label: 'KHR',
                  value: _khr(movement.amountKhr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementTypeBadge extends StatelessWidget {
  const _MovementTypeBadge({required this.type, this.compact = false});

  final String type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tone = _movementTone(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Text(
        _movementLabel(type),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tone.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
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

class _MovementTone {
  const _MovementTone({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

_MovementTone _movementTone(String type) {
  return switch (type) {
    CashMovementTypes.manualIn => const _MovementTone(
      background: Color(0xFFEAFBF2),
      border: Color(0xFFB7F0CD),
      foreground: Color(0xFF18794E),
    ),
    CashMovementTypes.manualOut => const _MovementTone(
      background: Color(0xFFFFF1EC),
      border: Color(0xFFFEC9B6),
      foreground: Color(0xFFC2410C),
    ),
    CashMovementTypes.adjustment => const _MovementTone(
      background: Color(0xFFFFF9E8),
      border: Color(0xFFFDE68A),
      foreground: Color(0xFFB45309),
    ),
    _ => const _MovementTone(
      background: Color(0xFFF8FAFC),
      border: Color(0xFFE2E8F0),
      foreground: Color(0xFF475569),
    ),
  };
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
