import 'package:flutter/material.dart';

InputDecoration authRecoveryInputDecoration({
  required String labelText,
  required String hintText,
  required bool useFramedInputs,
  Widget? suffixIcon,
}) {
  final base = InputDecoration(
    labelText: useFramedInputs ? null : labelText,
    hintText: useFramedInputs ? hintText : null,
    suffixIcon: suffixIcon,
  );

  if (!useFramedInputs) return base;

  return base.copyWith(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFED533C), width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}
