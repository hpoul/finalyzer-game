import 'package:flutter/material.dart';

const kFinalyzerOrangePrimary = 0xFFE29B4A;
const kFinalyzerOrange = const Color(kFinalyzerOrangePrimary);
const kFinalyzerGreen = const Color(0xFF97c965);
const kDarkGray = const Color(0XFFF1F5F6);
const kTextDarkGray = Colors.grey;
const kAppBarElevation = 0.5;

const finalyzerOrange = MaterialColor(
  kFinalyzerOrangePrimary,
  <int, Color>{
    50: Color(0xFFFBF3E5),
    100: Color(0xFFF6DFBD),
    200: Color(0xFFF0CB94),
    300: Color(0xFFEBB76D),
    400: Color(0xFFE7A856),
    500: Color(kFinalyzerOrangePrimary),
    600: Color(0xFFD58440),
    700: Color(0xFFD58440),
    800: Color(0xFFCD773C),
    900: Color(0xFFBE6538),
  },
);

class FinalyzerTheme {
  static const colorPrimary = kFinalyzerOrange;
  static const colorSecondary = kFinalyzerGreen;
}

ThemeData buildFinalyzerTheme() {
//  final ThemeData base = ThemeData.light();
  final ThemeData base = ThemeData(
    brightness: Brightness.light,
    primarySwatch: finalyzerOrange,
    accentColor: kFinalyzerGreen,
    primaryColor: kFinalyzerOrange,
    primaryColorBrightness: Brightness.dark,
//    canvasColor: kDarkGray,
    canvasColor: Colors.white,
    backgroundColor: kDarkGray,
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
