import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// A reusable widget for a labeled text field in the form.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.label,
    required this.placeholder,
    this.keyboardType,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.showVisibilityToggle = false,
    this.onToggleVisibility,
    this.helperText,
  });

  final String label;
  final String placeholder;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final bool showVisibilityToggle;
  final VoidCallback? onToggleVisibility;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F7FA) : Colors.white,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            hintText: placeholder,
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            suffixIcon: showVisibilityToggle
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: readOnly
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: readOnly
                  ? BorderSide.none
                  : BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
