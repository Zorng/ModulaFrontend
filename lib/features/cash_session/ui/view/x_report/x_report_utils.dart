import 'package:intl/intl.dart';

String xReportFormatTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('hh:mm a').format(value.toLocal());
}

String xReportFormatMoney(double value, String currency) {
  return '${value.toStringAsFixed(2)} $currency';
}

