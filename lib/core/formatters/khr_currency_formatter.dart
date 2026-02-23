import 'package:intl/intl.dart';

final NumberFormat _khrFormatter = NumberFormat('#,##0', 'en_US');

String formatKhrAmount(num amount) => _khrFormatter.format(amount);
