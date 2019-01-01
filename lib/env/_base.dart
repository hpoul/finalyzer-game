import 'package:flutter/material.dart';
import '../main.dart';

enum EnvType {
  production,
  development
}

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
}
