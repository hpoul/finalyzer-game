import 'package:anlage_app_game/env/_base.dart';
import 'package:flutter/material.dart';

void main() async => await Production().start();

class Production extends Env {
  final String baseUrl = 'http://api.anlage.app';
  final Color primarySwatch = Colors.pink;
}