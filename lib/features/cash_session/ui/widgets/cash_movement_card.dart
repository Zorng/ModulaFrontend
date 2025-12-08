import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A card for displaying cash movement summary and actions.
class CashMovementCard extends StatelessWidget {
  const CashMovementCard({
    super.key,
    required this.onAddCashMovement,
    required this.paidIn,
    required this.paidOut,
  });

  final VoidCallback? onAddCashMovement;
  final double paidIn;
  final double paidOut;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");

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
            _buildInfoRow(
                label: 'Today Paid In', value: currencyFormatter.format(paidIn)),
            const SizedBox(height: 8),
            _buildInfoRow(
                label: 'Today Paid Out', value: currencyFormatter.format(paidOut)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED533C),
                  foregroundColor: Colors.white,
                ),
                onPressed: onAddCashMovement,
                child: const Text('Add Cash Movement',
                    style: TextStyle(fontSize: 16)),
              ),
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
}