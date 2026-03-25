import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/view_carts_formatters.dart';

class SaleDetailPage extends ConsumerStatefulWidget {
  const SaleDetailPage({
    super.key,
    required this.saleId,
    this.showBack = true,
  });

  final String saleId;
  final bool showBack;

  @override
  ConsumerState<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends ConsumerState<SaleDetailPage> {
  Future<_SaleDetailPageData>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.saleId.trim().isNotEmpty) {
      _future = _load();
    }
  }

  Future<_SaleDetailPageData> _load() async {
    final repo = ref.read(saleRepositoryProvider);
    final sale = await repo.getSaleDetail(saleId: widget.saleId.trim());
    final voidRequest = await repo.getSaleVoidRequest(
      saleId: widget.saleId.trim(),
    );
    return _SaleDetailPageData(sale: sale, voidRequest: voidRequest);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSaleId = widget.saleId.trim();
    if (normalizedSaleId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.showBack,
          centerTitle: false,
          title: const Text('Sale Detail'),
        ),
        body: const Center(child: Text('Sale ID is required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        centerTitle: false,
        title: const Text('Sale Detail'),
      ),
      body: FutureBuilder<_SaleDetailPageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      UserErrorMessage.build(
                        context: 'Failed to load sale',
                        error: snapshot.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final sale = data.sale;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SaleHeader(sale: sale),
              const SizedBox(height: 16),
              _DetailSectionCard(
                title: 'Overview',
                children: [
                  _DetailRow(label: 'Sale ID', value: sale.saleId),
                  if ((sale.orderId ?? '').trim().isNotEmpty)
                    _DetailRow(label: 'Order ID', value: sale.orderId!.trim()),
                  _DetailRow(label: 'Status', value: _labelize(sale.status)),
                  _DetailRow(
                    label: 'Fulfillment',
                    value: _labelize(sale.fulfillmentStatus),
                  ),
                  _DetailRow(
                    label: 'Sale type',
                    value: _labelize(sale.saleType),
                  ),
                  _DetailRow(
                    label: 'Payment method',
                    value: _paymentMethodLabel(sale.paymentMethod),
                  ),
                  _DetailRow(
                    label: 'Tender currency',
                    value: sale.tenderCurrency,
                  ),
                  _DetailRow(
                    label: 'Created',
                    value: _formatDateTime(sale.createdAt),
                  ),
                  _DetailRow(
                    label: 'Updated',
                    value: _formatDateTime(sale.updatedAt),
                  ),
                  if (sale.finalizedAt != null)
                    _DetailRow(
                      label: 'Finalized',
                      value: _formatDateTime(sale.finalizedAt!),
                    ),
                  if (sale.voidedAt != null)
                    _DetailRow(
                      label: 'Voided',
                      value: _formatDateTime(sale.voidedAt!),
                    ),
                  if ((sale.voidReason ?? '').trim().isNotEmpty)
                    _DetailRow(
                      label: 'Void reason',
                      value: sale.voidReason!.trim(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSectionCard(
                title: 'Totals',
                children: [
                  _DetailRow(
                    label: 'Subtotal (USD)',
                    value: viewCartsFormatUsd(sale.subtotalUsdExact),
                  ),
                  _DetailRow(
                    label: 'Subtotal (KHR)',
                    value: viewCartsFormatKhr(sale.subtotalKhrExact),
                  ),
                  _DetailRow(
                    label: 'Discount (USD)',
                    value: viewCartsFormatUsd(sale.discountUsdExact),
                  ),
                  _DetailRow(
                    label: 'Discount (KHR)',
                    value: viewCartsFormatKhr(sale.discountKhrExact),
                  ),
                  _DetailRow(
                    label: 'Tax (USD)',
                    value: viewCartsFormatUsd(sale.taxUsdExact),
                  ),
                  _DetailRow(
                    label: 'Tax (KHR)',
                    value: viewCartsFormatKhr(sale.taxKhrExact),
                  ),
                  _DetailRow(
                    label: 'Grand total (USD)',
                    value: viewCartsFormatUsd(sale.totalUsdExact),
                    emphasize: true,
                  ),
                  _DetailRow(
                    label: 'Grand total (KHR)',
                    value: viewCartsFormatKhr(sale.totalKhrExact),
                    emphasize: true,
                  ),
                ],
              ),
              if (_hasTenderData(sale)) ...[
                const SizedBox(height: 16),
                _DetailSectionCard(
                  title: 'Tender',
                  children: [
                    if (sale.cashReceivedUsd != null)
                      _DetailRow(
                        label: 'Cash received (USD)',
                        value: viewCartsFormatUsd(sale.cashReceivedUsd!),
                      ),
                    if (sale.cashReceivedKhr != null)
                      _DetailRow(
                        label: 'Cash received (KHR)',
                        value: viewCartsFormatKhr(sale.cashReceivedKhr!),
                      ),
                    if (sale.changeGivenUsd != null)
                      _DetailRow(
                        label: 'Change given (USD)',
                        value: viewCartsFormatUsd(sale.changeGivenUsd!),
                      ),
                    if (sale.changeGivenKhr != null)
                      _DetailRow(
                        label: 'Change given (KHR)',
                        value: viewCartsFormatKhr(sale.changeGivenKhr!),
                      ),
                  ],
                ),
              ],
              if (data.voidRequest != null) ...[
                const SizedBox(height: 16),
                _DetailSectionCard(
                  title: 'Void Request',
                  children: [
                    _DetailRow(
                      label: 'Request status',
                      value: _labelize(data.voidRequest!.status),
                    ),
                    _DetailRow(
                      label: 'Requested at',
                      value: _formatDateTime(data.voidRequest!.requestedAt),
                    ),
                    _DetailRow(
                      label: 'Reason',
                      value: data.voidRequest!.reason,
                    ),
                    if ((data.voidRequest!.reviewNote ?? '').trim().isNotEmpty)
                      _DetailRow(
                        label: 'Review note',
                        value: data.voidRequest!.reviewNote!.trim(),
                      ),
                    if (data.voidRequest!.reviewedAt != null)
                      _DetailRow(
                        label: 'Reviewed at',
                        value: _formatDateTime(data.voidRequest!.reviewedAt!),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (sale.lines.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No sale lines.'),
                  ),
                )
              else
                ...sale.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SaleLineCard(line: line),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SaleDetailPageData {
  const _SaleDetailPageData({
    required this.sale,
    required this.voidRequest,
  });

  final SaleDetailReadDto sale;
  final SaleVoidRequestReadDto? voidRequest;
}

class _SaleHeader extends StatelessWidget {
  const _SaleHeader({required this.sale});

  final SaleDetailReadDto sale;

  @override
  Widget build(BuildContext context) {
    final statusColor = viewCartsStateColor(sale.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sale Record',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labelize(sale.status),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sale.saleId,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

class _SaleLineCard extends StatelessWidget {
  const _SaleLineCard({required this.line});

  final SaleDetailLineDto line;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${line.quantity} × ${line.menuItemName}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (line.modifierLabels.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                line.modifierLabels.join(', '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _hasTenderData(SaleDetailReadDto sale) {
  return sale.cashReceivedUsd != null ||
      sale.cashReceivedKhr != null ||
      sale.changeGivenUsd != null ||
      sale.changeGivenKhr != null;
}

String _labelize(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .replaceAll('-', '_')
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _paymentMethodLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'KHQR':
      return 'KHQR';
    case 'CASH':
      return 'Cash';
    default:
      return _labelize(raw);
  }
}

String _formatDateTime(DateTime value) {
  return DateFormat('MMM d, y • h:mm a').format(value);
}
