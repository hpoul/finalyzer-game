
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.utils.dialog');

class DialogUtil {
  static Function genericErrorDialog(BuildContext context) {
    return (dynamic error, StackTrace stackTrace) {
      _logger.warning('Got an error for request', error, stackTrace);
//    Scaffold.of(context).
      showDialog(context: context, builder: (context) {
        return AlertDialog(
          title: Text('Error during request.'),
          content: Text('There was an error while performing this action. Please try again later.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
      return Future.error(error, stackTrace);
    };
  }

  static void showSimpleAlertDialog(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: Text(content),
        actions: <Widget>[
          FlatButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

}
