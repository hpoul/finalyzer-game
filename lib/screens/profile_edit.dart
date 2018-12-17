

import 'package:flutter/material.dart';

class ProfileEdit extends StatefulWidget {

  static const ROUTE_NAME = '/profile/edit';

  @override
  State<StatefulWidget> createState() => ProfileEditState();

}

class ProfileEditState extends State<ProfileEdit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Profile'),
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text('Tell us a bit about yourself so you are immortalized in the MarketCap Leaderboard!'),

            TextFormField(
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Your full name',
              ),
            ),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Your email address, so you can log back in'
              ),
            ),
          ],
        ),
      ),
    );
  }

}
