import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/reporting/domain/models/z_report.dart';

class ClosedSessionSummaryCard extends StatelessWidget {
  const ClosedSessionSummaryCard({
    super.key,
    required this.detailAsync,
    this.showTitle = true,
  });

  final AsyncValue<ZReportDetail> detailAsync;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: error),
          data: (detail) =>
              _DetailContent(detail: detail, showTitle: showTitle),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail, required this.showTitle});

  final ZReportDetail detail;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Closed Session Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
        ],
        _SummaryGrid(detail: detail),
        const SizedBox(height: 16),
        _MetaRows(detail: detail),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.detail});

  final ZReportDetail detail;

  @override
  Widget build(BuildContext context) {
    final tiles = <_SummaryTileData>[
      _SummaryTileData(
        label: 'Opening Float',
        usd: detail.openingFloatUsd,
        khr: detail.openingFloatKhr,
      ),
      _SummaryTileData(
        label: 'Expected Cash',
        usd: detail.expectedCashUsd,
        khr: detail.expectedCashKhr,
      ),
      _SummaryTileData(
        label: 'Counted Cash',
        usd: detail.countedCashUsd,
        khr: detail.countedCashKhr,
      ),
      _SummaryTileData(
        label: 'Variance',
        usd: detail.varianceUsd,
        khr: detail.varianceKhr,
        emphasizeVariance: true,
      ),
      _SummaryTileData(
        label: 'KHQR Sales',
        usd: detail.totalSalesKhqrUsd,
        khr: detail.totalSalesKhqrKhr,
      ),
      _SummaryTileData(
        label: 'Cash Sales',
        usd: detail.totalSalesCashUsd,
        khr: detail.totalSalesCashKhr,
      ),
      _SummaryTileData(
        label: 'Paid In',
        usd: detail.totalPaidInUsd,
        khr: detail.totalPaidInKhr,
      ),
      _SummaryTileData(
        label: 'Paid Out',
        usd: detail.totalPaidOutUsd,
        khr: detail.totalPaidOutKhr,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isNarrow ? 1 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: isNarrow ? 108 : 104,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) => _SummaryTile(data: tiles[index]),
        );
      },
    );
  }
}

class _SummaryTileData {
  const _SummaryTileData({
    required this.label,
    required this.usd,
    required this.khr,
    this.emphasizeVariance = false,
  });

  final String label;
  final double usd;
  final double khr;
  final bool emphasizeVariance;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.data});

  final _SummaryTileData data;

  @override
  Widget build(BuildContext context) {
    final varianceColor = _varianceColor(data.usd, data.khr);
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: data.emphasizeVariance ? varianceColor : null,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(_formatMoney(data.usd, 'USD'), style: valueStyle),
          const SizedBox(height: 2),
          Text(_formatMoney(data.khr, 'KHR'), style: valueStyle),
        ],
      ),
    );
  }

  Color? _varianceColor(double usd, double khr) {
    final isNeutral = usd.abs() < 0.01 && khr.abs() < 0.01;
    if (isNeutral) return const Color(0xFF2E7D32);
    return usd < 0 || khr < 0
        ? const Color(0xFFC62828)
        : const Color(0xFFED6C02);
  }
}

class _MetaRows extends StatelessWidget {
  const _MetaRows({required this.detail});

  final ZReportDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetaRow(label: 'Opened by', value: detail.openedByName),
        _MetaRow(label: 'Closed by', value: detail.closedByName),
        _MetaRow(
          label: 'Close reason',
          value: _formatCloseReason(detail.closeReason),
        ),
      ],
    );
  }

  String _formatCloseReason(String value) {
    switch (value.trim().toUpperCase()) {
      case 'FORCE_CLOSE':
        return 'Force Close';
      case 'NORMAL_CLOSE':
        return 'Normal Close';
      default:
        return value.isEmpty ? '-' : value;
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            UserErrorMessage.build(
              context: 'Failed to load closed session summary',
              error: error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value, String currency) {
  final precision = currency == 'KHR' ? 0 : 2;
  return '${value.toStringAsFixed(precision)} $currency';
}
