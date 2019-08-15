import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('app.anlage.game.utils.dialog');

class DialogUtil {
  static Function genericErrorDialog(BuildContext context) {
    return (dynamic error, StackTrace stackTrace) {
      _logger.warning('Got an error for request', error, stackTrace);
//    Scaffold.of(context).
      showDialog<dynamic>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error during request.'),
              content: const Text('There was an error while performing this action. Please try again later.'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
      return Future<dynamic>.error(error, stackTrace);
    };
  }

  static void showSimpleAlertDialog(BuildContext context, String title, String content) {
    showDialog<dynamic>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: title == null ? null : Text(title),
            content: Text(content),
            actions: <Widget>[
              FlatButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  static Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) {
      await AnalyticsUtils.instance.analytics.logEvent(name: 'launch_url', parameters: <String, dynamic>{'url': url});
      await launch(url, forceSafariVC: false);
    } else {
      _logger.severe('Unable to launch url $url');
    }
  }

  static Future<void> openFeedback({String origin}) async {
    await AnalyticsUtils.instance.analytics
        .logEvent(name: 'launch_feedback', parameters: <String, dynamic>{'origin': origin ?? 'unknown'});
    const url = 'mailto:hello@anlage.app';
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false);
    } else {
      _logger.severe('Unable to launch url $url');
    }
  }

  static void askForPermissionsIfRequired(Deps deps) {
    if ((deps.api.currentLoginState?.userInfo?.statsTotalTurns ?? -1) > 2) {
      deps.cloudMessaging.requiresAskPermission().then((askPermission) {
        if (askPermission) {
//                    showDialog(context: context, builder: (context) => AskForMessagingPermission());
          deps.cloudMessaging.requestPermission();
        }
      }).catchError(LoggingUtil.futureCatchErrorLog('require permission?'));
    }
  }

  static String nextPushedScreenName;

  static T pushInfo<T>(String screenName, T Function() callback) {
    try {
      assert(nextPushedScreenName == null);
      nextPushedScreenName = screenName;
      return callback();
    } finally {
      assert(nextPushedScreenName != null);
      nextPushedScreenName = null;
    }
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({this.onPressed, this.error});

  final VoidCallback onPressed;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
//      mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Text('Error while contacting server.'),
          RaisedButton.icon(onPressed: onPressed, icon: Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}
