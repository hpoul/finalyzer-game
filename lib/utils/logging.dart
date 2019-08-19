import 'package:anlage_app_game/utils/analytics.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

final _logger = Logger('app.anlage.game.utils.logging');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(PrintAppender().logListener());
  Logger.root.onRecord.listen((LogRecord rec) {
    if (rec.stackTrace != null) {
      if (rec.level >= Level.WARNING) {
        AnalyticsUtils.instance.analytics.logEvent(
          name: 'logerror',
          parameters: <String, dynamic>{'message': rec.message, 'stack': rec.stackTrace},
          silent: true,
        );
      }
    } else if (rec.level >= Level.SEVERE) {
      AnalyticsUtils.instance.analytics.logEvent(
          name: 'logerror',
          parameters: <String, dynamic>{'message': rec.message, 'stack': StackTrace.current.toString()});
//      FlutterCrashlytics().logException(Exception('SEVERE LOG ${rec.message}'), StackTrace.current);
    }
  });
}

class LoggingUtil {
  static Function futureCatchErrorLog(String message) {
    return (dynamic error, StackTrace stackTrace) {
      _logger.warning('Error during future: $message', error, stackTrace);
      return Future<dynamic>.error(error, stackTrace);
    };
  }
}
