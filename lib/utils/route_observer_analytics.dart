
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = new Logger("app.anlage.game.main");

class MyAnalyticsObserver extends RouteObserver<Route<dynamic>> {
  MyAnalyticsObserver({
    @required this.analytics,
  });

  final FirebaseAnalytics analytics;

  _extractScreenName(Route<dynamic> route) =>
    route.settings.name ?? route.runtimeType.toString();


  void _sendScreenView(Route<dynamic> route) {
    final String screenName = _extractScreenName(route);
    if (screenName != null) {
      analytics.setCurrentScreen(screenName: screenName);
      _logger.finer('Track Screen: $screenName');
    } else {
      _logger.fine('Route has no name: $route');
    }
  }

  shouldTrackRouteType(Route route) => route is PageRoute || route is PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    if (shouldTrackRouteType(route)) {
      _sendScreenView(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    if (shouldTrackRouteType(previousRoute) && shouldTrackRouteType(route)) {
      _sendScreenView(previousRoute);
    }
  }

}