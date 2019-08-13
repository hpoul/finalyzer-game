import 'dart:async';

import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/data/company_info_store.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge.dart';
import 'package:anlage_app_game/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/screens/leaderboard.dart';
import 'package:anlage_app_game/screens/market_cap_sorting.dart';
import 'package:anlage_app_game/screens/profile_edit.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/logging.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

final _logger = Logger('app.anlage.game.main');

Future<void> _setupCrashlytics() async {
  const bool isInDebugMode = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    _logger.severe('Unhandled FlutterError. ${details.toString()}', details.exception, details.stack);
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      FlutterError.dumpErrorToConsole(details);
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };
}

Future<void> startApp(Env env) async {
  setupLogging();
  // TODO maybe we should check if this stuff makes startup slower? how?
  await _setupCrashlytics();
  _logger.fine('Logging was set up.');

  await runZoned<Future<void>>(() async {
    _logger.fine('calling runApp.');
    runApp(MyApp(env));
  }, onError: (dynamic error, StackTrace stackTrace) async {
    _logger.shout('Error during main run loop of application', error, stackTrace);
  });
}

//void main() => runApp(MyApp());
void main() => throw Exception('Run some env/*.dart');

class MyApp extends StatelessWidget {
  MyApp(this.env) : deps = env.createDeps();

  static AnalyticsUtils analytics = AnalyticsUtils.instance;
  static MyAnalyticsObserver observer = MyAnalyticsObserver(analytics: analytics);

  final Env env;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'topLevelNavigator');

  final Deps deps;

//  final Deps deps;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    unawaited(deps.cloudMessaging.setupFirebaseMessaging());
    analytics.analytics.logAppOpen();
    return DepsProvider(
      deps: deps,
      child: DynamicLinkHandler(
        navigatorKey: navigatorKey,
        child: MultiProvider(
          providers: [
            StreamProvider<CompanyInfoData>(
              builder: (context) => deps.companyInfoStore.store.onValueChangedAndLoad,
              initialData: deps.companyInfoStore.store.cachedValue,
            ),
            Provider.value(value: deps.formatUtil),
          ],
          child: MaterialApp(
            title: 'MarketCap Game',
            navigatorKey: navigatorKey,
//          debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}

class DynamicLinkHandler extends StatefulWidget {
  const DynamicLinkHandler({this.child, this.navigatorKey});

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  _DynamicLinkHandlerState createState() => _DynamicLinkHandlerState();
}

class _DynamicLinkHandlerState extends State<DynamicLinkHandler> with WidgetsBindingObserver {
  StreamSubscription<GameNotification> _onNotificationSubscription;

  @override
  void initState() {
    super.initState();
    FirebaseDynamicLinks.instance.onLink(
      onSuccess: (linkData) async {
        _logger.fine('Received dynamic link $linkData');
        await _handleLink(linkData);
      },
      onError: (error) async {
        _logger.severe('Error while handling dynamic link?', error);
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Deps deps = DepsProvider.of(context);
    WidgetsBinding.instance.addObserver(this);
    _retrieveDynamicLinkBackgroundWithLogging();
    _onNotificationSubscription = deps.cloudMessaging.onNotification.listen((notification) {
      _logger.fine('Handling notification $notification ${notification?.toJson()}');
      if (notification == null) {
        return;
      }
      switch (notification.type) {
        case GameNotificationType.ChallengeWeekly:
        case GameNotificationType.ChallengeInvitation:
          widget.navigatorKey.currentState.push<dynamic>(AnalyticsPageRoute<dynamic>(
            name: '/challenge/invite/info',
            builder: (context) => ChallengeInviteInfo(inviteToken: notification.inviteToken),
          ));
          break;
        case GameNotificationType.ChallengeInvitationAccepted:
        case GameNotificationType.ChallengeParticipantFinished:
          widget.navigatorKey.currentState.push<dynamic>(AnalyticsPageRoute<dynamic>(
            name: '/challenge/details',
            builder: (context) => ChallengeDetails(notification.challengeId),
          ));
          break;
      }
      deps.cloudMessaging.clearNotification();
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
    }).catchError((dynamic error, StackTrace stackTrace) {
      _logger.severe('Error while retrieving dynamic link.', error, stackTrace);
    });
  }

  Future<void> _retrieveDynamicLink(int count) async {
    _logger.fine('retrieving dynamic links .. ($count).');
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
    _logger.fine('dynamic link ($count), Got: $data');
    await _handleLink(data);
  }

  Future<void> _handleLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      _logger.fine('Received dynamic link $deepLink');
      if (deepLink.path == ChallengeInvite.URL_PATH) {
        _logger.fine('pushing ChallgeInviteInfo.');
        var count = 0;
        while (widget.navigatorKey.currentState == null && count < 10) {
          _logger.fine('currentStat is null. $count');
          await Future<dynamic>.delayed(Duration(milliseconds: 100 * count));
          count++;
        }
        await widget.navigatorKey.currentState.push<dynamic>(AnalyticsPageRoute<dynamic>(
          name: '/challenge/invite/info',
          builder: (context) => ChallengeInviteInfo(
            inviteToken: deepLink.queryParameters[ChallengeInvite.URL_QUERY_PARAM_TOKEN],
          ),
        ));
//        Navigator.of(context).push(MaterialPageRoute(
//            builder: (context) => ChallengeInviteInfo(
//              inviteToken: deepLink.queryParameters[ChallengeInvite.URL_QUERY_PARAM_TOKEN],
//            )));
      } else {
        _logger.warning('Unknown dynamic link $deepLink.');
        await Navigator.pushNamed(context, deepLink.path); // deeplink.path == '/helloworld'
      }
    }
  }
}
