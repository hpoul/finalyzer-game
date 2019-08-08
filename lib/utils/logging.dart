import 'package:anlage_app_game/utils/analytics.dart';
import 'package:logging/logging.dart';

final _logger = new Logger("app.anlage.game.utils.logging");

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.loggerName} - ${rec.level.name}: ${rec.time}: ${rec.message}');

//    if (rec.level >= Level.INFO) {
//      FlutterCrashlytics().log(rec.message, priority: rec.level.value, tag: rec.loggerName);
//    }

    if (rec.error != null) {
      print(rec.error);
    }
    if (rec.stackTrace != null) {
      print(rec.stackTrace);
      if (rec.level >= Level.INFO) {
        AnalyticsUtils.instance.analytics
            .logEvent(name: 'logerror', parameters: {'message': rec.message, 'stack': rec.stackTrace});
//        FlutterCrashlytics().logException(rec.error, rec.stackTrace);
      }
    } else if (rec.level >= Level.SEVERE) {
      AnalyticsUtils.instance.analytics
          .logEvent(name: 'logerror', parameters: {'message': rec.message, 'stack': StackTrace.current.toString()});
//      FlutterCrashlytics().logException(Exception('SEVERE LOG ${rec.message}'), StackTrace.current);
    }
  });
}

class LoggingUtil {
  static Function futureCatchErrorLog(message) {
    return (error, stackTrace) {
      _logger.warning("Error during future: ${message}", error, stackTrace);
      return Future.error(error, stackTrace);
    };
  }
}
