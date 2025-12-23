import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';

class XReportPage extends ConsumerWidget {
  const XReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(loginControllerProvider).user;
    final role = user?.role.trim().toLowerCase() ?? '';
    final isAdmin = role == 'admin';
    final cashState = ref.watch(cashSessionViewModelProvider);
    final entriesAsync = ref.watch(xReportEntriesProvider);
    final filters = ref.watch(xReportFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('X Report'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAdmin) ...[
                _FilterRow(filters: filters),
                const SizedBox(height: 12),
              ],
              if (cashState.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: entriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        'Unable to load X reports.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Center(
                          child: Text(
                            'No X reports available for this selection.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _XReportCard(entry: entries[index]);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.filters});

  final XReportFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: filters.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  ref.read(xReportFiltersProvider.notifier).setDate(picked);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(DateFormat('yyyy-MM-dd').format(filters.date)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<XReportStatusFilter>(
                value: filters.status,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: XReportStatusFilter.all,
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: XReportStatusFilter.open,
                    child: Text('Open'),
                  ),
                  DropdownMenuItem(
                    value: XReportStatusFilter.closed,
                    child: Text('Closed'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(xReportFiltersProvider.notifier).setStatus(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _XReportCard extends ConsumerWidget {
  const _XReportCard({required this.entry});

  final XReportEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = this.entry;
    final expanded = ref.watch(
      xReportExpandedProvider.select((set) => set.contains(entry.id)),
    );
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Status', entry.status),
            const SizedBox(height: 8),
            _infoRow('Name', entry.ownerName),
            const SizedBox(height: 8),
            _infoRow('Open at', _formatTime(entry.openedAt)),
            const SizedBox(height: 8),
            _infoRow('Closed at', _formatTime(entry.closedAt)),
            if (expanded) ...[
              const Divider(height: 16),
              _XReportDetailSection(entry: entry),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: () {
                  ref.read(xReportExpandedProvider.notifier).toggle(entry.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('hh:mm a').format(value.toLocal());
  }
}

class _XReportDetailSection extends ConsumerWidget {
  const _XReportDetailSection({required this.entry});

  final XReportEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(xReportDetailProvider(entry));

    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Unable to load report details.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Text(
            'No detail available.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final rows = [
          _DetailRow('Opening float (USD)', _formatMoney(detail.openingFloatUsd, 'USD')),
          _DetailRow('Opening float (KHR)', _formatMoney(detail.openingFloatKhr, 'KHR')),
          _DetailRow('Sales cash (USD)', _formatMoney(detail.totalSalesCashUsd, 'USD')),
          _DetailRow('Sales cash (KHR)', _formatMoney(detail.totalSalesCashKhr, 'KHR')),
          _DetailRow('Paid in (USD)', _formatMoney(detail.totalPaidInUsd, 'USD')),
          _DetailRow('Paid in (KHR)', _formatMoney(detail.totalPaidInKhr, 'KHR')),
          _DetailRow('Paid out (USD)', _formatMoney(detail.totalPaidOutUsd, 'USD')),
          _DetailRow('Paid out (KHR)', _formatMoney(detail.totalPaidOutKhr, 'KHR')),
          _DetailRow('Expected cash (USD)', _formatMoney(detail.expectedCashUsd, 'USD')),
          _DetailRow('Expected cash (KHR)', _formatMoney(detail.expectedCashKhr, 'KHR')),
        ];
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  String _formatMoney(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
