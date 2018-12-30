
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _logger = new Logger("app.anlage.game.main");


class CloudMessagingUtil {

  static final instance = CloudMessagingUtil._();

  CloudMessagingUtil._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final BehaviorSubject<String> _onTokenRefresh = BehaviorSubject<String>();
  ValueObservable<String> get onTokenRefresh => _onTokenRefresh.stream;


  Future<void> setupFirebaseMessaging() {
    _firebaseMessaging.configure(
      onMessage: (message) async {
        _logger.info('Received in app message. $message');
        _handleMessage(message);
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
      _onTokenRefresh.add(newToken);
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

  void _handleMessage(Map<String, dynamic> message) {
    if (message.containsKey('d')) {
      try {
        final notification = GameNotification.fromJson(message);

      } catch (error, stackTrace) {
        _logger.warning('Error while parsing notification.', error, stackTrace);
      }
    }
  }

  void dispose() {
    _onTokenRefresh.close();
  }

}

