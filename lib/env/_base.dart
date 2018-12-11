import 'package:flutter/material.dart';
import '../main.dart';

abstract class Env {

  static Env value;

  String get baseUrl;
  Color get primarySwatch;

  Env() {
    value = this;
  }

  Future<void> start() async {
    await startApp(this);
  }

  String get name => runtimeType.toString();
}
