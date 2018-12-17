

import 'package:anlage_app_game/api/api_service.dart';
import 'package:flutter/widgets.dart';

@immutable
class Deps {
  ApiService api;

  Deps({this.api});
}

class DepsProvider extends InheritedWidget {

  final Deps deps;

  DepsProvider({Key key, this.deps, Widget child}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Deps of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(DepsProvider) as DepsProvider).deps;

}
