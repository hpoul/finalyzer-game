
import 'package:flutter/material.dart';

const kFinalyzerOrange = const Color(0xFFE29B4A);
const kFinalyzerGreen = const Color(0xFF97c965);
const kDarkGray = const Color(0XFFF1F5F6);
const kTextDarkGray = Colors.grey;
const kAppBarElevation = 0.5;

class FinalyzerTheme {
  static final colorPrimary = kFinalyzerOrange;
  static final colorSecondary = kFinalyzerGreen;
}


ThemeData buildFinalyzerTheme() {
//  final ThemeData base = ThemeData.light();
  final ThemeData base = ThemeData(
    brightness: Brightness.light,
    accentColor: kFinalyzerGreen,
    primaryColor: kFinalyzerOrange,
    primaryColorBrightness: Brightness.dark,
    canvasColor: kDarkGray,
  );
//  base.inputDecorationTheme.fillColor = Colors.white;
  return base;
//
//  return base.copyWith(
//      inputDecorationTheme: InputDecorationTheme(
//          fillColor: Colors.white,
//          enabledBorder: InputBorder.none),
//      textTheme: base.textTheme.apply(
//        displayColor: kTextDarkGray,
//      )//.copyWith(headline: base.textTheme.headline.copyWith(fontWeight: FontWeight.bold))
//  );
}
