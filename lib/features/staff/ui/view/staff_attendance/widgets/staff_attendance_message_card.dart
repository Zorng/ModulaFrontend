import 'package:flutter/material.dart';

class StaffAttendanceMessageCard extends StatelessWidget {
  const StaffAttendanceMessageCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}
