import 'package:anlage_app_game/utils/deps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AskForMessagingPermission extends StatelessWidget {
  const AskForMessagingPermission();

  @override
  Widget build(BuildContext context) {
    final Deps deps = DepsProvider.of(context);
    return Container(
      child: AlertDialog(
        title: const Text('Notifications'),
        content: const Text(
            'Allow receiving of notifications so we can send you challenges and information about new features.'),
        actions: <Widget>[
          FlatButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FlatButton(
            child: const Text('Okay'),
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
