import 'package:flutter/material.dart';

class AppTableTheme {
  // Container
  static const Color background = Color(0xFFFFFFFF);

  // Header
  static const Color headerBackground = Color(0xFFF6F6F6);
  static const Color divider = Color(0xFFE7E7E7);

  // Text
  static const TextStyle headerText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2B2B2B),
  );

  static const TextStyle cellText = TextStyle(
    fontSize: 14,
    color: Color(0xFF393838),
  );

  // Category pill
  static const BoxDecoration categoryPillDecoration = BoxDecoration(
    color: Color(0xFFF6F6F6),
    borderRadius: BorderRadius.all(Radius.circular(50)),
  );

  static const TextStyle categoryPillText = TextStyle(
    fontSize: 13,
    color: Color(0xFF696969),
  );

  // Status pill – healthy
  static const BoxDecoration healthyDecoration = BoxDecoration(
    color: Color(0xFFE3F8ED),
    borderRadius: BorderRadius.all(Radius.circular(50)),
  );

  static const TextStyle healthyText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF529E86),
  );

  // Status pill – out of stock
  static const BoxDecoration dangerDecoration = BoxDecoration(
    color: Color(0xFFFFF5F2),
    borderRadius: BorderRadius.all(Radius.circular(50)),
  );

  static const TextStyle dangerText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFFED533C),
  );

  // Action button
  static const ButtonStyle actionButtonStyle = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Color(0xFF393838)),
    foregroundColor: WidgetStatePropertyAll(Colors.white),
    elevation: WidgetStatePropertyAll(0),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
}
