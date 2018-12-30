import 'dart:async';

import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge.dart';
import 'package:anlage_app_game/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/screens/leaderboard.dart';
import 'package:anlage_app_game/screens/market_cap_sorting.dart';
import 'package:anlage_app_game/screens/profile_edit.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/firebase_messaging.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';

final _logger = new Logger("app.anlage.game.main");

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');

    if (rec.level >= Level.INFO) {
      FlutterCrashlytics().log(rec.message, priority: rec.level.value, tag: rec.loggerName);
    }

    if (rec.error != null) {
      print(rec.error);
    }
    if (rec.stackTrace != null) {
      print(rec.stackTrace);
      if (rec.level >= Level.INFO) {
        AnalyticsUtils.instance.analytics
            .logEvent(name: 'logerror', parameters: {'message': rec.message, 'stack': rec.stackTrace});
        FlutterCrashlytics().logException(rec.error, rec.stackTrace);
      }
    } else if (rec.level >= Level.SEVERE) {
      AnalyticsUtils.instance.analytics
          .logEvent(name: 'logerror', parameters: {'message': rec.message, 'stack': StackTrace.current.toString()});
      FlutterCrashlytics().logException(Exception('SEVERE LOG ${rec.message}'), StackTrace.current);
    }
  });
}

Future<void> _setupCrashlytics() async {
  bool isInDebugMode = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  await FlutterCrashlytics().initialize();
}

Future<void> startApp(Env env) async {
  _setupLogging();
  // TODO maybe we should check if this stuff makes startup slower? how?
  await _setupCrashlytics();
  unawaited(CloudMessagingUtil.instance.setupFirebaseMessaging());
  _logger.fine('Logging was set up.');

  await runZoned<Future<Null>>(() async {
    runApp(MyApp(env));
  }, onError: (error, stackTrace) async {
    // Whenever an error occurs, call the `reportCrash` function. This will send
    // Dart errors to our dev console or Crashlytics depending on the environment.
    await FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: false);
  });
}

//void main() => runApp(MyApp());
void main() => throw Exception('Run some env/*.dart');

class MyApp extends StatelessWidget {
  static AnalyticsUtils analytics = AnalyticsUtils.instance;
  static MyAnalyticsObserver observer = MyAnalyticsObserver(analytics: analytics.analytics);

  final Env env;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'topLevelNavigator');

//  final Deps deps;

  MyApp(this.env);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final apiCaller = ApiCaller(env);
    Deps deps = Deps(
      apiCaller: apiCaller,
      api: ApiService(env, apiCaller),
      env: env,
    );
    analytics.analytics.logAppOpen();
    return DepsProvider(
      deps: deps,
      child: DynamicLinkHandler(
        navigatorKey: navigatorKey,
        child: MaterialApp(
          title: 'MarketCap Game',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: buildFinalyzerTheme(),
          navigatorObservers: [observer],
          home: MarketCapSorting(),
          //MyHomePage(title: 'Never mind.'),
          routes: {
            ProfileEdit.ROUTE_NAME: (context) => ProfileEdit(),
            LeaderboardList.ROUTE_NAME: (context) => LeaderboardList(),
            ChallengeInvite.ROUTE_NAME: (context) => ChallengeInvite(),
            ChallengeList.ROUTE_NAME: (context) => ChallengeList(),
          },
        ),
      ),
    );
  }
}

class DynamicLinkHandler extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  DynamicLinkHandler({this.child, this.navigatorKey});

  @override
  _DynamicLinkHandlerState createState() => _DynamicLinkHandlerState();
}

class _DynamicLinkHandlerState extends State<DynamicLinkHandler> with WidgetsBindingObserver {
  StreamSubscription<GameNotification> _onNotificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _retrieveDynamicLinkBackgroundWithLogging();
    _onNotificationSubscription = CloudMessagingUtil.instance.onNotification.listen((notification) {
      _logger.fine('Handling notification ${notification} ${notification?.toJson()}');
      if (notification == null) {
        return;
      }
      switch (notification.type) {
        case GameNotificationType.ChallengeInvitation:
          widget.navigatorKey.currentState
              .push(MaterialPageRoute(builder: (context) => ChallengeInviteInfo(inviteToken: notification.inviteToken)));
          break;
        case GameNotificationType.ChallengeInvitationAccepted:
        case GameNotificationType.ChallengeParticipantFinished:
          widget.navigatorKey.currentState
              .push(MaterialPageRoute(builder: (context) => ChallengeDetails(notification.challengeId)));
          break;
      }
      CloudMessagingUtil.instance.clearNotification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onNotificationSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.fine('didChangeLifecycleState to: $state');
    if (state == AppLifecycleState.resumed) {
      _retrieveDynamicLinkBackgroundWithLogging();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _retrieveDynamicLinkBackgroundWithLogging({int count = 0}) {
    _retrieveDynamicLink(count).then((val) {
      _logger.fine('retrieving dynamic link successful.');
    }).catchError((error, stackTrace) {
      _logger.severe('Error while retrieving dynamic link.', error, stackTrace);
    });
  }

  Future<void> _retrieveDynamicLink(int count) async {
    _logger.fine('retrieving dynamic links .. ($count).');
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.retrieveDynamicLink();
    _logger.fine('dynamic link ($count), Got: $data');
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      _logger.fine('Received dynamic link $deepLink');
      if (deepLink.path == ChallengeInvite.URL_PATH) {
        _logger.fine('pushing ChallgeInviteInfo.');
        var count = 0;
        while (widget.navigatorKey.currentState == null && count < 10) {
          _logger.fine('currentStat is null. $count');
          await Future.delayed(Duration(milliseconds: 100 * count));
          count++;
        }
        await widget.navigatorKey.currentState.push(MaterialPageRoute(
            builder: (context) => ChallengeInviteInfo(
                  inviteToken: deepLink.queryParameters[ChallengeInvite.URL_QUERY_PARAM_TOKEN],
                )));
//        Navigator.of(context).push(MaterialPageRoute(
//            builder: (context) => ChallengeInviteInfo(
//              inviteToken: deepLink.queryParameters[ChallengeInvite.URL_QUERY_PARAM_TOKEN],
//            )));
      } else {
        _logger.warning('Unknown dynamic link $deepLink.');
        await Navigator.pushNamed(context, deepLink.path); // deeplink.path == '/helloworld'
      }
    } else {
      if (count < 1) {
        unawaited(Future.delayed(Duration(milliseconds: 500)).then((val) {
          this._retrieveDynamicLinkBackgroundWithLogging(count: count + 1);
        }));
      }
    }
  }
}
