import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/api_challenge_service.dart';
import 'package:anlage_app_game/api/api_pricedata.dart';
import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/data/preferences.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/firebase_messaging.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:flutter/widgets.dart';

class FirebaseConfig {
  final schema = 'https';
  final domain = 'anlageapp.page.link';
  String get uriPrefix => '$schema://$domain';
  final androidPackageName = 'app.anlage.game.marketcap';
  final iosPackageName = 'app.anlage.game.marketcap';
  final iosAppStoreId = '1446255350';
  final iosCustomScheme = 'anlageappgame';
}

@immutable
class Deps {
  Deps({
    @required this.apiCaller,
    @required this.api,
    @required this.env,
    @required this.prefs,
    @required this.cloudMessaging,
  })  : apiChallenge = ApiChallenge(apiCaller),
        apiPriceData = ApiPriceData(apiCaller),
        analytics = AnalyticsUtils.instance;

  final Env env;
  final FirebaseConfig firebaseConfig = FirebaseConfig();
  final ApiCaller apiCaller;
  final ApiService api;
  final ApiChallenge apiChallenge;
  final ApiPriceData apiPriceData;
  final FormatUtil formatUtil = FormatUtil();
  final PreferenceStore prefs;
  final CloudMessagingUtil cloudMessaging;
  final AnalyticsUtils analytics;

  static Deps of(BuildContext context) => (context.inheritFromWidgetOfExactType(DepsProvider) as DepsProvider).deps;
}

class DepsProvider extends InheritedWidget {
  const DepsProvider({Key key, this.deps, Widget child}) : super(key: key, child: child);

  final Deps deps;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Deps of(BuildContext context) => (context.inheritFromWidgetOfExactType(DepsProvider) as DepsProvider).deps;
}
