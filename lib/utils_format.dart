import 'package:intl/intl.dart' as intl;


final _marketCapFormat = intl.NumberFormat.simpleCurrency(name: 'USD', decimalDigits: 0);

String formatMarketCap(double marketCap) => '${_marketCapFormat.format(marketCap / (1000000.0))}M';

