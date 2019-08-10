import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/preferences.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../main.dart';

enum EnvType { production, development }

abstract class Env {
  static Env value;

  String get baseUrl;
  Color get primarySwatch;
  Duration get fakeLatency => null;
  final EnvType type;

  Env(this.type) {
    value = this;
  }

  Future<void> start() async {
    await startApp(this);
  }

  String get name => runtimeType.toString();

  Deps createDeps() {
    Env env = this;
    final prefs = const PreferenceStore();
    final cloudMessaging = CloudMessagingUtil(prefs);
    final apiCaller = ApiCaller(env);
    return Deps(
      apiCaller: apiCaller,
      api: ApiService(env, apiCaller, cloudMessaging),
      env: env,
      prefs: prefs,
      cloudMessaging: cloudMessaging,
    );
  }
}
