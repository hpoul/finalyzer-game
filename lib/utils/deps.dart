

import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/api_challenge_service.dart';
import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:flutter/widgets.dart';

class FirebaseConfig {
  final domain = 'anlageapp.page.link';
  final androidPackageName = 'app.anlage.game.marketcap';
  final iosPackageName = 'app.anlage.game.marketcap';
  final iosAppStoreId = '1446255350';
  final iosCustomScheme = 'anlageappgame';

}

@immutable
class Deps {
  final Env env;
  final FirebaseConfig firebaseConfig = FirebaseConfig();
  final ApiCaller apiCaller;
  final ApiService api;
  final ApiChallenge apiChallenge;
  final FormatUtil formatUtil = FormatUtil();

  Deps({@required this.apiCaller, @required this.api, @required this.env}) :
      apiChallenge = ApiChallenge(apiCaller);
}

class DepsProvider extends InheritedWidget {

  final Deps deps;

  DepsProvider({Key key, this.deps, Widget child}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Deps of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(DepsProvider) as DepsProvider).deps;

}
