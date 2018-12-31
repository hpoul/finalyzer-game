import 'package:intl/intl.dart' as intl;
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math' as math;

final _marketCapFormat = intl.NumberFormat.simpleCurrency(name: 'USD', decimalDigits: 0);

String formatMarketCap(double marketCap) => '${_marketCapFormat.format(marketCap / (1000000.0))}M';

class FormatUtil {
  final intl.DateFormat _dateFormat = intl.DateFormat.yMd();
  final Duration absoluteDateThreshold = Duration(days: 1);

  String formatRelativeFuzzy(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff > absoluteDateThreshold) {
      return _dateFormat.format(date);
    }
    return timeago.format(date);
  }
}

double trimToRange({double min, double max, double value}) {
  return math.min(max, math.max(min, value));
}
