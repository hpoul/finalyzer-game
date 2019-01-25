
import 'dart:convert';

import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/api/preferences.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/stream_subscriber_mixin.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:platform/platform.dart';
import 'package:rxdart/rxdart.dart';

final _logger = new Logger("app.anlage.game.utils.firebase_messaging");


class CloudMessagingUtil with StreamSubscriberMixin {

  final PreferenceStore _prefs;

  CloudMessagingUtil(this._prefs);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final BehaviorSubject<String> _onTokenRefresh = BehaviorSubject<String>();
  ValueObservable<String> get onTokenRefresh => _onTokenRefresh.stream;

  static const Platform platform = const LocalPlatform();

  final BehaviorSubject<GameNotification> _onNotification = BehaviorSubject<GameNotification>();
  ValueObservable<GameNotification> get onNotification => _onNotification.stream;

  bool _askedForPermissionsThisRun = false;

  Future<void> setupFirebaseMessaging() {
    cancelSubscriptions();
    _firebaseMessaging.configure(
      onMessage: (message) async {
        _logger.info('Received in app message. $message');
        _handleMessage(message);
      },
      onLaunch: (message) async {
        _logger.info('Received message for onLaunch. $message');
        _handleMessage(message);
      },
      onResume: (message) async {
        _logger.info('Received message for onResume. $message');
        _handleMessage(message);
      },
    );
    listen(_firebaseMessaging.onTokenRefresh, (newToken) {
      _logger.warning('We have received a new token. Need to change it to $newToken');
      _onTokenRefresh.add(newToken);
    });
    listen(_firebaseMessaging.onIosSettingsRegistered, (event) {
      _logger.info('User updated iOS Settings ${event}');
    });
    _firebaseMessaging.subscribeToTopic(convertFirebaseMessagingTopicToJson(FirebaseMessagingTopic.WeeklyChallenges));
    _firebaseMessaging.subscribeToTopic(convertFirebaseMessagingTopicToJson(FirebaseMessagingTopic.All));
    return Future.value(null);
  }

  Future<String>getToken() async {
    final token = await _firebaseMessaging.getToken();
    _logger.info('Token: ${token}.');
    return token;
  }

  Future<bool> requiresAskPermission() async {
    if (!platform.isIOS || _askedForPermissionsThisRun) {
      return false;
    }
    return !await _prefs.getValue(Preferences.askedForPushPermission);
//    return await getToken() == null
//        && !await _prefs.getValue(Preferences.askedForPushPermission);
  }

  requestPermission() {
    AnalyticsUtils.instance.analytics.logEvent(name: "fcm_request_permission");
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      alert: true,
      badge: true,
      sound: true,
    ));
    _askedForPermissionsThisRun = true;
    _prefs.setValue(Preferences.askedForPushPermission, true);
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (message.containsKey('d')) {
      try {
        final messageMap = jsonDecode(message['d']);
        final notification = GameNotification.fromJson(messageMap);
        _onNotification.add(notification);
      } catch (error, stackTrace) {
        _logger.severe('Error while parsing notification.', error, stackTrace);
      }
    }
  }

  void dispose() {
    _onTokenRefresh.close();
  }

  void clearNotification() {
    _onNotification.add(null);
  }


}

