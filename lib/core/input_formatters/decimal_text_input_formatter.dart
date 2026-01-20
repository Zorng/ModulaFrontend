import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange = 2})
      : assert(decimalRange >= 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    var dotCount = 0;
    for (final codeUnit in text.codeUnits) {
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isDot = codeUnit == 46;
      if (!isDigit && !isDot) return oldValue;
      if (isDot) dotCount += 1;
      if (dotCount > 1) return oldValue;
    }

    if (text == '.') {
      return newValue.copyWith(
        text: '0.',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }

    if (text.startsWith('.')) {
      final adjusted = '0$text';
      final selection = newValue.selection;
      final base = selection.baseOffset < 0 ? adjusted.length : selection.baseOffset + 1;
      final extent =
          selection.extentOffset < 0 ? adjusted.length : selection.extentOffset + 1;
      return newValue.copyWith(
        text: adjusted,
        selection: TextSelection(
          baseOffset: base.clamp(0, adjusted.length),
          extentOffset: extent.clamp(0, adjusted.length),
        ),
      );
    }

    final dotIndex = text.indexOf('.');
    if (dotIndex == -1) return newValue;

    final fractionLength = text.length - dotIndex - 1;
    if (fractionLength > decimalRange) return oldValue;

    return newValue;
  }
}

