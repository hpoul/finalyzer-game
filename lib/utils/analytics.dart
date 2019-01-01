
import 'package:anlage_app_game/env/_base.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsUtils {
  static final instance = new AnalyticsUtils._();

  FirebaseAnalytics analytics = FirebaseAnalytics();


  AnalyticsUtils._() {
    switch (Env.value.type) {
      case EnvType.development:
        analytics.setUserProperty(name: 'testlab', value: 'env-development');
        break;
      case EnvType.production:
        // nothing to do.
        break;
    }
  }
}