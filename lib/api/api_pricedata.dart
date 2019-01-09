import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/logging.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

class ApiPriceData {
  final ApiCaller _apiCaller;

  ApiPriceData(this._apiCaller);

  static _isoDate(DateTime date) {
    final str = date.toIso8601String();
    return str.substring(0, str.indexOf('T'));
  }

  Future<EodStockDataResponse> getEodStockData({List<String> symbols, @required DateTime start, @required DateTime end, String currency = 'USD'}) {
    final format = DateFormat.yMd();
    return _apiCaller
        .get(EodStockData(currency, _isoDate(end), 7, _isoDate(start), symbols))
        .catchError(LoggingUtil.futureCatchErrorLog('error fetching eod data'));
  }
}
