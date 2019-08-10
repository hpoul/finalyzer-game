import 'package:anlage_app_game/env/_base.dart';
import 'package:flutter/material.dart';

void main() async => await Development().start();

class Development extends Env {
//  final String baseUrl = 'http://localhost:8080';
  final String baseUrl = 'http://api.anlage.app';
//  final String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  final Color primarySwatch = Colors.pink;
  final Duration fakeLatency = Duration(seconds: 2);

  Development() : super(EnvType.development);
}
