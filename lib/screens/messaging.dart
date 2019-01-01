import 'package:anlage_app_game/utils/deps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AskForMessagingPermission extends StatelessWidget {
  AskForMessagingPermission();

  @override
  Widget build(BuildContext context) {
    Deps deps = DepsProvider.of(context);
    return Container(
      child: AlertDialog(
        title: Text('Notifications'),
        content:
            Text('Allow receiving of notifications so we can send you challenges and information about new features.'),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel'),
            onPressed: () { Navigator.of(context).pop(); },
          ),
          FlatButton(
            child: Text('Okay'),
            onPressed: () {
              deps.cloudMessaging.requestPermission();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }
}
