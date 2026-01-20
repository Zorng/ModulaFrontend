import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StaffFormActions extends StatelessWidget {
  const StaffFormActions({
    super.key,
    required this.isEditing,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.grey.shade200,
          onPressed: onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        const SizedBox(width: 16),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onPressed: onSubmit,
          child: Text(isEditing ? 'Save Changes' : 'Add New Staff'),
        ),
      ],
    );
  }
}

