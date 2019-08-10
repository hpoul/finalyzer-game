import 'package:anlage_app_game/env/_base.dart';
import 'package:flutter/material.dart';

Future<void> main() async => await Development().start();

class Development extends Env {
  Development() : super(EnvType.development);

  //  final String baseUrl = 'http://localhost:8080';
  @override
  final String baseUrl = 'http://api.anlage.app';
//  final String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  @override
  final Color primarySwatch = Colors.pink;
  @override
  final Duration fakeLatency = const Duration(seconds: 2);
}
