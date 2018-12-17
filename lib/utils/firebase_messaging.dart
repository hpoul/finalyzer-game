
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';

final _logger = new Logger("app.anlage.game.main");


class CloudMessagingUtil {

  static final instance = CloudMessagingUtil._();

  CloudMessagingUtil._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  Future<void> setupFirebaseMessaging() {
    _firebaseMessaging.configure(
      onMessage: (message) async {
        _logger.info('Received in app message. $message'); null;
      },
      onLaunch: (message) async {
        _logger.info('Received message for onLaunch. $message');
      },
      onResume: (message) async {
        _logger.info('Received message for onResume. $message');
      },
    );
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _logger.warning('We have received a new token. Need to change it to $newToken');
    });
    return null;
  }

  Future<String>getToken() async {
    return _firebaseMessaging.getToken();
  }

  requestPermission() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      alert: true,
      badge: true,
      sound: true,
    ));
  }

}

