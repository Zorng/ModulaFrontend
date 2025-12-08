import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A card that displays the details of an active cash session.
class CashSessionDetailsCard extends StatelessWidget {
  const CashSessionDetailsCard({
    super.key,
    required this.openFloatUsd,
    required this.openFloatKhr,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  final String openFloatUsd;
  final String openFloatKhr;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isClosed = status == 'Closed';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              label: 'Today',
              value: DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(label: 'Open Float (USD)', value: openFloatUsd),
            const SizedBox(height: 8),
            _buildInfoRow(label: 'Open Float (KHR)', value: openFloatKhr),
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'Start Cash Session',
              value: DateFormat('hh:mm a').format(startTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'End Cash Session',
              value: endTime != null ? DateFormat('hh:mm a').format(endTime!) : '--:--',
            ),
            const SizedBox(height: 8),
            _buildStatusDisplay(
              label: 'Current Status',
              statusText: status,
              statusTextColor:
                  isClosed ? const Color(0xFFED533C) : const Color(0xFF529E86),
              statusBackgroundColor:
                  isClosed ? const Color(0xFFFFF5F2) : const Color(0xFFE3F8ED),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.black)),
      ],
    );
  }

  Widget _buildStatusDisplay({
    required String label,
    required String statusText,
    required Color statusTextColor,
    required Color statusBackgroundColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            statusText,
            style: TextStyle(
                color: statusTextColor,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}