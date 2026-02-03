import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StaffFormActions extends StatelessWidget {
  const StaffFormActions({
    super.key,
    required this.isEditing,
    required this.onCancel,
    required this.onSubmit,
    this.isSubmitting = false,
    this.isFormValid = true,
  });

  final bool isEditing;
  final Future<void> Function() onCancel;
  final Future<void> Function() onSubmit;
  final bool isSubmitting;
  final bool isFormValid;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.grey.shade200,
          onPressed: isSubmitting ? null : onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
        ),
        const SizedBox(width: 16),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onPressed: (isSubmitting || !isFormValid) ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save Changes' : 'Add New Staff'),
        ),
      ],
    );
  }
}
