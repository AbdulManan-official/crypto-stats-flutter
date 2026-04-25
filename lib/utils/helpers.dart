import 'package:intl/intl.dart';

String formatCompact(num value) {
  return NumberFormat.compact().format(value);
}