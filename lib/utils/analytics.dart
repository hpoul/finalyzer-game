
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsUtils {
  static final instance = new AnalyticsUtils._();

  FirebaseAnalytics analytics = FirebaseAnalytics();


  AnalyticsUtils._();
}