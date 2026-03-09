import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

class SessionSalesSection extends StatelessWidget {
  const SessionSalesSection({
    super.key,
    required this.sessionStatus,
    required this.sales,
  });

  final SessionStatus sessionStatus;
  final List<CashSessionSale> sales;

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
              'Session Sales',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Sales recorded during the active cash session.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (!_hasSession)
              const _EmptyState(
                message: 'Open a cash session to start tracking sales.',
              )
            else if (sales.isEmpty)
              const _EmptyState(
                message: 'No sales have been recorded for this session yet.',
              )
            else if (isWide)
              _WideSalesTable(sales: sales)
            else ...[
              for (final sale in sales)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SaleListCard(sale: sale),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WideSalesTable extends StatelessWidget {
  const _WideSalesTable({required this.sales});

  final List<CashSessionSale> sales;

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
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Cashier')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('USD')),
                DataColumn(label: Text('KHR')),
              ],
              rows: sales.map((sale) {
                return DataRow(
                  cells: [
                    DataCell(Text(_formatTime(sale.finalizedAt))),
                    DataCell(_StatusPill(status: sale.status)),
                    DataCell(Text(_cashierLabel(sale.cashierName))),
                    DataCell(Text(_titleCase(sale.paymentMethod))),
                    DataCell(Text(_titleCase(sale.saleType))),
                    DataCell(Text('${sale.totalItems}')),
                    DataCell(Text(_usd(sale.grandTotalUsd))),
                    DataCell(Text(_khr(sale.grandTotalKhr))),
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

class _SaleListCard extends StatelessWidget {
  const _SaleListCard({required this.sale});

  final CashSessionSale sale;

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
                  _cashierLabel(sale.cashierName),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatTime(sale.finalizedAt),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPill(status: sale.status),
              Text(_titleCase(sale.paymentMethod)),
              Text(_titleCase(sale.saleType)),
              Text('${sale.totalItems} item${sale.totalItems == 1 ? '' : 's'}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('USD ${_usd(sale.grandTotalUsd)}')),
              Expanded(child: Text('KHR ${_khr(sale.grandTotalKhr)}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = CashSessionSaleStatuses.normalize(status);
    final (background, foreground) = switch (normalized) {
      CashSessionSaleStatuses.voided => (
        const Color(0xFFFFF5F2),
        const Color(0xFFED533C),
      ),
      CashSessionSaleStatuses.voidPending => (
        const Color(0xFFFFF7E8),
        const Color(0xFFC37B00),
      ),
      _ => (const Color(0xFFEAF7F0), const Color(0xFF2E8B57)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _titleCase(normalized),
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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

String _formatTime(DateTime? time) {
  if (time == null) return '--:--';
  return DateFormat('hh:mm a').format(time.toLocal());
}

String _cashierLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Unknown cashier' : trimmed;
}

String _titleCase(String value) {
  final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) return '--';
  return normalized
      .split(' ')
      .where((segment) => segment.isNotEmpty)
      .map((segment) => '${segment[0].toUpperCase()}${segment.substring(1)}')
      .join(' ');
}

String _usd(double value) => value.toStringAsFixed(2);

String _khr(double value) => NumberFormat('#,##0').format(value);
