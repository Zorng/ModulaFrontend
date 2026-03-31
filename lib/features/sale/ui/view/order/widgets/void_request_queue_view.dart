import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

class VoidRequestQueueView extends ConsumerStatefulWidget {
  const VoidRequestQueueView({
    super.key,
    this.initialStatus = 'PENDING',
    this.onOpenSaleDetail,
  });

  final String initialStatus;
  final ValueChanged<String>? onOpenSaleDetail;

  @override
  ConsumerState<VoidRequestQueueView> createState() =>
      _VoidRequestQueueViewState();
}

class _VoidRequestQueueViewState extends ConsumerState<VoidRequestQueueView> {
  static const _statuses = <String>['PENDING', 'APPROVED', 'REJECTED', 'ALL'];

  late String _selectedStatus;
  late Future<SaleVoidRequestQueuePageDto> _future;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _resolveInitialStatus(widget.initialStatus);
    _future = _loadQueue();
  }

  String _resolveInitialStatus(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (_statuses.contains(normalized)) return normalized;
    return 'PENDING';
  }

  Future<SaleVoidRequestQueuePageDto> _loadQueue() {
    return Future(() {
      final repo = ref.read(saleRepositoryProvider);
      return repo.getSaleVoidRequests(
        SaleVoidRequestQueueQueryDto(
          status: _selectedStatus,
          limit: 50,
          offset: 0,
        ),
      );
    });
  }

  void _reload() {
    setState(() {
      _future = _loadQueue();
    });
  }

  void _openSaleDetail(String saleId) {
    final callback = widget.onOpenSaleDetail;
    if (callback != null) {
      callback(saleId);
      return;
    }
    context.pushNamed(
      AppRoute.saleDetail.name,
      pathParameters: {'saleId': saleId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Void Requests',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Review pending and historical sale void requests.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in _statuses)
                    ChoiceChip(
                      label: Text(_statusFilterLabel(status)),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        if (!selected || _selectedStatus == status) return;
                        setState(() {
                          _selectedStatus = status;
                          _future = _loadQueue();
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<SaleVoidRequestQueuePageDto>(
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
                            context: 'Failed to load void requests',
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

              final page =
                  snapshot.data ??
                  const SaleVoidRequestQueuePageDto(
                    items: <SaleVoidRequestQueueItemDto>[],
                    limit: 50,
                    offset: 0,
                    total: 0,
                    hasMore: false,
                  );
              if (page.items.isEmpty) {
                return Center(
                  child: Text(_emptyLabelForStatus(_selectedStatus)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: page.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = page.items[index];
                  return _VoidRequestQueueCard(
                    item: item,
                    onTap: () => _openSaleDetail(item.saleId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VoidRequestQueueCard extends StatelessWidget {
  const _VoidRequestQueueCard({required this.item, required this.onTap});

  final SaleVoidRequestQueueItemDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requester = (item.requestedByDisplayName ?? '').trim().isNotEmpty
        ? item.requestedByDisplayName!.trim()
        : item.requestedByAccountId;
    final branchName = (item.branchName ?? '').trim();
    final metaColor = theme.colorScheme.onSurfaceVariant;
    final receiptNumber = (item.receiptNumber ?? '').trim();
    final title = receiptNumber.isNotEmpty
        ? 'Receipt $receiptNumber'
        : 'Finalized Sale';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
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
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested by $requester',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: metaColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _QueueStatusPill(
                    label: _labelize(item.voidRequestStatus),
                    backgroundColor: _requestStatusColor(
                      item.voidRequestStatus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _QueueMetaChip(
                    icon: Icons.schedule_outlined,
                    label: _formatDateTime(item.requestedAt),
                  ),
                  if (branchName.isNotEmpty)
                    _QueueMetaChip(
                      icon: Icons.storefront_outlined,
                      label: branchName,
                    ),
                  _QueueMetaChip(
                    icon: Icons.payments_outlined,
                    label: _labelize(item.paymentMethod),
                  ),
                  if ((item.fulfillmentStatus ?? '').trim().isNotEmpty)
                    _QueueMetaChip(
                      icon: Icons.local_shipping_outlined,
                      label: _labelize(item.fulfillmentStatus!),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(item.reason, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              Row(
                children: [
                  _QueueStatusPill(
                    label: _labelize(item.saleStatus),
                    backgroundColor: _saleStatusColor(item.saleStatus),
                  ),
                  const Spacer(),
                  Text(
                    _formatTotals(item),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueMetaChip extends StatelessWidget {
  const _QueueMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueStatusPill extends StatelessWidget {
  const _QueueStatusPill({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusFilterLabel(String status) {
  switch (status) {
    case 'ALL':
      return 'All';
    default:
      return _labelize(status);
  }
}

String _emptyLabelForStatus(String status) {
  switch (status) {
    case 'APPROVED':
      return 'No approved void requests';
    case 'REJECTED':
      return 'No rejected void requests';
    case 'ALL':
      return 'No void requests';
    case 'PENDING':
    default:
      return 'No pending void requests';
  }
}

String _labelize(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .replaceAll('-', '_')
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

Color _requestStatusColor(String status) {
  switch (status.trim().toUpperCase()) {
    case 'APPROVED':
      return Colors.green.shade600;
    case 'REJECTED':
      return Colors.red.shade600;
    case 'PENDING':
    default:
      return Colors.orange.shade700;
  }
}

Color _saleStatusColor(String status) {
  switch (status.trim().toUpperCase()) {
    case 'VOIDED':
      return Colors.red.shade700;
    case 'VOID_PENDING':
      return Colors.deepOrange.shade700;
    case 'PENDING':
      return Colors.amber.shade800;
    case 'FINALIZED':
      return Colors.green.shade700;
    default:
      return Colors.blueGrey.shade600;
  }
}

String _formatDateTime(DateTime value) {
  return DateFormat('MMM d, y • h:mm a').format(value);
}

String _formatTotals(SaleVoidRequestQueueItemDto item) {
  final usd = item.grandTotalUsd.toStringAsFixed(2);
  final khr = item.grandTotalKhr.toStringAsFixed(0);
  return '\$$usd • KHR $khr';
}
