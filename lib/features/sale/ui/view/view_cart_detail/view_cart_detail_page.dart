import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/view_carts_formatters.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/widgets/view_cart_detail_line_tile.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/widgets/view_cart_detail_status_chip.dart';

class ViewCartDetailPage extends StatelessWidget {
  const ViewCartDetailPage({
    super.key,
    required this.summary,
    this.onVoid,
    this.showBack = true,
  });

  final SaleSummary summary;
  final Future<bool> Function()? onVoid;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final color = viewCartsStateColor(summary.state);
    final metadataStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        leading: showBack
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        centerTitle: false,
        title: const Text('Cart Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sale #${summary.id}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ViewCartDetailStatusChip(
                  label: viewCartsStateLabel(summary.state),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'Created ${viewCartsFormatDate(summary.createdAt)} at '
                  '${viewCartsFormatTime(summary.createdAt)}',
                  style: metadataStyle,
                ),
                Text(
                  'Updated ${viewCartsFormatDate(summary.updatedAt)} at '
                  '${viewCartsFormatTime(summary.updatedAt)}',
                  style: metadataStyle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ViewCartDetailInfoCard(
              children: [
                _ViewCartDetailInfoRow(
                  label: 'Payment method',
                  value: viewCartsPaymentMethodLabel(summary.paymentMethod),
                ),
                _ViewCartDetailInfoRow(
                  label: 'Tender currency',
                  value: viewCartsTenderCurrencyLabel(summary.tenderCurrency),
                ),
                _ViewCartDetailInfoRow(
                  label: 'Fulfillment',
                  value: viewCartsFulfillmentLabel(summary.fulfillmentStatus),
                ),
                _ViewCartDetailInfoRow(
                  label: 'Total (USD)',
                  value: viewCartsFormatUsd(summary.totalUsdExact),
                ),
                _ViewCartDetailInfoRow(
                  label: 'Total (KHR)',
                  value: viewCartsFormatKhr(summary.totalKhrExact),
                ),
                if (summary.cashReceivedUsd != null)
                  _ViewCartDetailInfoRow(
                    label: 'Cash received (USD)',
                    value: viewCartsFormatUsd(summary.cashReceivedUsd!),
                  ),
                if (summary.cashReceivedKhr != null)
                  _ViewCartDetailInfoRow(
                    label: 'Cash received (KHR)',
                    value: viewCartsFormatKhr(summary.cashReceivedKhr!),
                  ),
                if (summary.changeGivenUsd != null)
                  _ViewCartDetailInfoRow(
                    label: 'Change given (USD)',
                    value: viewCartsFormatUsd(summary.changeGivenUsd!),
                  ),
                if (summary.changeGivenKhr != null)
                  _ViewCartDetailInfoRow(
                    label: 'Change given (KHR)',
                    value: viewCartsFormatKhr(summary.changeGivenKhr!),
                  ),
              ],
            ),
            if (summary.state.trim().toUpperCase() == 'VOID_PENDING') ...[
              const SizedBox(height: 16),
              const _ViewCartDetailNotice(
                text: 'This sale is waiting for the void workflow to complete.',
              ),
            ],
            if (summary.state.trim().toUpperCase() == 'VOIDED') ...[
              const SizedBox(height: 16),
              const _ViewCartDetailNotice(
                text: 'This sale has already been voided.',
              ),
            ],
            const SizedBox(height: 16),
            Text('Items', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...summary.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ViewCartDetailLineTile(line: line),
              ),
            ),
            if (onVoid != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final didVoid = await onVoid!.call();
                  if (didVoid && context.mounted) {
                    Navigator.of(context).maybePop();
                  }
                },
                child: const Text('Void Sale'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewCartDetailInfoCard extends StatelessWidget {
  const _ViewCartDetailInfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }
}

class _ViewCartDetailInfoRow extends StatelessWidget {
  const _ViewCartDetailInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ViewCartDetailNotice extends StatelessWidget {
  const _ViewCartDetailNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(text),
    );
  }
}
