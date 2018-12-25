

import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/api_challenge_service.dart';
import 'package:anlage_app_game/api/api_service.dart';
import 'package:flutter/widgets.dart';

@immutable
class Deps {
  final ApiCaller apiCaller;
  final ApiService api;
  final ApiChallenge apiChallenge;

  Deps({@required this.apiCaller, @required this.api}) :
      apiChallenge = ApiChallenge(api);
}

class DepsProvider extends InheritedWidget {

  final Deps deps;

  DepsProvider({Key key, this.deps, Widget child}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Deps of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(DepsProvider) as DepsProvider).deps;

}
