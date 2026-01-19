import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';

class XReportFilterRow extends ConsumerWidget {
  const XReportFilterRow({super.key, required this.filters});

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

