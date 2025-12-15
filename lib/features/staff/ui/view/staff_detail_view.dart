import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form_view.dart';

class StaffDetailView extends StatefulWidget {
  const StaffDetailView({super.key, required this.staff});

  final Staff staff;

  @override
  State<StaffDetailView> createState() => _StaffDetailViewState();
}

class _StaffDetailViewState extends State<StaffDetailView> {
  late Staff _currentStaff;

  @override
  void initState() {
    super.initState();
    _currentStaff = widget.staff;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(_currentStaff),
        ),
        title: const Text('Staff Details'),
        actions: [
          CupertinoButton(
            child: const Text('Edit'),
            onPressed: () async {
              final updatedStaff = await Navigator.of(context).push<Staff>(
                CupertinoPageRoute(
                  builder: (context) => StaffFormView(staff: _currentStaff),
                ),
              );

              if (updatedStaff != null) {
                setState(() {
                  _currentStaff = updatedStaff;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User Name', _currentStaff.userName),
            _buildDetailRow('Gender', _currentStaff.gender),
            _buildDetailRow('Phone Number', _currentStaff.phoneNumber),
            _buildDetailRow('Email', _currentStaff.email),
            _buildDetailRow('Role', _currentStaff.role),
            _buildDetailRow('Branch', _currentStaff.branch),
            _buildDetailRow('Status', _currentStaff.isActive ? 'Active' : 'Inactive'),
            // TODO: Add display for schedule details
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}