import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/x_report_utils.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/widgets/x_report_detail_section.dart';

class XReportCard extends ConsumerWidget {
  const XReportCard({super.key, required this.entry});

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
            _infoRow('Open at', xReportFormatTime(entry.openedAt)),
            const SizedBox(height: 8),
            _infoRow('Closed at', xReportFormatTime(entry.closedAt)),
            if (expanded) ...[
              const Divider(height: 16),
              XReportDetailSection(entry: entry),
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
}

