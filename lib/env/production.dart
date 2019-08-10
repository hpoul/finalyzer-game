import 'package:anlage_app_game/env/_base.dart';
import 'package:flutter/material.dart';

Future<void> main() async => await Production().start();

class Production extends Env {
  Production() : super(EnvType.production);

  @override
  final String baseUrl = 'http://api.anlage.app';
  @override
  final Color primarySwatch = Colors.pink;
}
