import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.main');

class AnalyticsPageRoute<T> extends MaterialPageRoute<T> {
  AnalyticsPageRoute({
    @required this.name,
    @required WidgetBuilder builder,
    RouteSettings settings,
  }) : super(builder: builder, settings: settings);

  /// analytics name to be used in firebase.
  String name;
}

class MyAnalyticsObserver extends RouteObserver<Route<dynamic>> {
  MyAnalyticsObserver({
    @required this.analytics,
  });

  final AnalyticsUtils analytics;
  final Expando<String> _routeExpando = Expando<String>('routeExpando');

  String _extractScreenName(Route<dynamic> route) {
    final name = route.settings.name ?? (route is AnalyticsPageRoute ? route.name : null);
    if (name != null) {
      return name;
    }
    final override = DialogUtil.nextPushedScreenName;
    if (override != null) {
      _routeExpando[route] = override;
      return override;
    }
    final previous = _routeExpando[route];
    if (previous != null) {
      return previous;
    }
    final stackTrace = StackTrace.current;
    final firstLine =
        stackTrace.toString().split('\n').firstWhere((line) => !line.contains(RegExp(r'Observer|Navigator')));
    final callerName = RegExp(r'([\w\.]{2,999})').firstMatch(firstLine)?.group(1);
    _logger.warning('Unable to find name for route ${route.runtimeType}, using $callerName', null, stackTrace);
    return _routeExpando[route] = callerName ?? route.runtimeType.toString();
  }

  void _sendScreenView(Route<dynamic> route) {
    final String screenName = _extractScreenName(route);
    if (screenName != null) {
      analytics.setCurrentScreen(screenName: screenName);
      _logger.finer('Track Screen: $screenName');
    } else {
      _logger.fine('Route has no name: $route');
    }
  }

  bool shouldTrackRouteType(Route route) => route is PageRoute || route is PopupRoute;

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
