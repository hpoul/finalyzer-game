import 'package:flutter/material.dart';
import '../main.dart';

abstract class Env {

  static Env value;

  String get baseUrl;
  Color get primarySwatch;

  Env() {
    value = this;
    runApp(MyApp(this));
  }

  String get name => runtimeType.toString();
}