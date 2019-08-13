import 'package:analytics_event_gen/analytics_event_gen.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

part 'analytics.g.dart';

final _logger = Logger('analytics');

class AnalyticsUtils {
  AnalyticsUtils._() {
    events = AnalyticsEventImpl((eventName, params) {
      _logger.fine('logEvent(name: $eventName, parameters: $params)');
      _analytics.logEvent(name: eventName, parameters: params);
    });
    switch (Env.value.type) {
      case EnvType.development:
        _analytics.setUserProperty(name: 'testlab', value: 'env-development');
        break;
      case EnvType.production:
        // nothing to do.
        break;
    }
  }

  static final instance = AnalyticsUtils._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics();
  AnalyticsUtils get analytics => this;
  FirebaseAnalytics get firebaseAnalytics => _analytics;
  AnalyticsEvent events;

  // backward compatibility methods which simply redirect to firebase analytics.
  Future<void> logEvent({@required String name, Map<String, dynamic> parameters, bool silent = false}) async {
    if (!silent) {
      _logger.fine('logEvent(name: $name, parameters: $parameters)');
    }
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserProperty({@required String name, @required String value}) async {
    _logger.fine('setUserProperty(name: $name, value: $value)');
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setCurrentScreen({String screenName}) async {
    _logger.fine('setCurrentScreen(screenName: $screenName)');
    await _analytics.setCurrentScreen(screenName: screenName);
  }

  Future<void> logAppOpen() async {
    _logger.fine('logAppOpen()');
    await _analytics.logAppOpen();
  }

  Future<void> logShare({String contentType, String itemId, String method}) async {
    _logger.fine('logShare(contentType: $contentType, itemId: $itemId, method: $method)');
    await _analytics.logShare(contentType: contentType, itemId: itemId, method: method);
  }
}

enum GameType {
  sorting,
}

@AnalyticsEvents()
abstract class AnalyticsEvent {
  void trackResultVerify();

  void trackTurnVerify({@required GameType gameType, @required int score});

  void trackCloseResultOverlay();
}
