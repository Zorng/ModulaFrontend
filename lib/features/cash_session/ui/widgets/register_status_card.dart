import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for DateFormat

/// A legacy status card for cash-session flows.
///
/// This is a placeholder implementation and will be connected to a
/// Riverpod provider to display real data.
class RegisterStatusCard extends StatelessWidget {
  const RegisterStatusCard({
    super.key,
    required this.status,
    required this.statusColor,
    required this.backgroundColor,
  });

  /// The status text to display (e.g., 'Checked In', 'Checked Out').
  final String status;

  /// The color of the status text.
  final Color statusColor;

  /// The background color of the status badge.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
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
              labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              valueStyle: const TextStyle(fontSize: 13, color: Colors.black),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'Shift Hours',
              value: '09:00 AM - 03:00 PM', // Placeholder, will come from state
              labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              valueStyle: const TextStyle(fontSize: 13, color: Colors.black),
            ),
            const SizedBox(height: 8),
            _buildStatusDisplay(
              label: 'Current Status',
              statusText: status,
              labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              statusTextColor: statusColor,
              statusBackgroundColor: backgroundColor,
            ),
            // Additional details like 'Opening Float' and 'Expected Cash' will be added here later.
          ],
        ),
      ),
    );
  }

  /// Helper to build a row with a label on the left and a value on the right.
  Widget _buildInfoRow({
    required String label,
    required String value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  /// Helper to build the 'Current Status' row with special styling for the status text.
  Widget _buildStatusDisplay({
    required String label,
    required String statusText,
    TextStyle? labelStyle,
    required Color statusTextColor,
    required Color statusBackgroundColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
