import 'package:flutter/services.dart';

/// Formats integer KHR input with thousands separators while typing.
/// Example: 4000 -> 4,000
class KhrTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final normalized = digitsOnly.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = _withCommas(normalized);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }

  String _withCommas(String digits) {
    final reversed = <String>[];
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      reversed.add(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        reversed.add(',');
      }
    }
    return reversed.reversed.join();
  }
}
