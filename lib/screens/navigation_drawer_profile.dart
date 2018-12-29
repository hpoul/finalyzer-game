import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge.dart';
import 'package:anlage_app_game/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/screens/leaderboard.dart';
import 'package:anlage_app_game/screens/profile_edit.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/firebase_messaging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = new Logger("app.anlage.game.screens.navigation_drawer_profile");

class NavigationDrawerProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _api = DepsProvider.of(context).api;

    return Drawer(
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: StreamBuilder<LoginState>(
            stream: _api.loginState,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: <Widget>[
                    Text('Error while fetching user information.'),
                  ],
                );
              }
              if (!snapshot.hasData) {
                _logger.fine(snapshot);
                return Center(
//                  heightFactor: 1.5,
                  child: CircularProgressIndicator(),
                );
              }

              final displayName = snapshot?.data?.userInfo?.displayName ?? "";
              return Column(
                children: <Widget>[
                  Ink(
                    color: FinalyzerTheme.colorPrimary,
                    child: InkWell(
                      onTap: () {
                        _logger.info('Tapped on profile image.');
                        Navigator.of(context).pushNamed(ProfileEdit.ROUTE_NAME);
//                        CloudMessagingUtil.instance.requestPermission();
                      },
                      child: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.all(16).copyWith(top: MediaQuery.of(context).padding.top + 16),
                        child: DefaultTextStyle(
                          style: Theme.of(context).primaryTextTheme.body1,
                          textAlign: TextAlign.right,
                          child: !snapshot.hasData ? Container() : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    constraints: BoxConstraints.tightFor(width: 128, height: 128),
                                    child: AvatarWithEditIcon(
                                      snapshot?.data?.avatarUrl,
                                      radius: 64,
                                    ),
                                  ),
                                ] +
                                (displayName == ""
                                    ? [
                                        Text(
                                          'Hello Anonymous Investor!',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Tell us a bit about you to get listed in the leaderboard!',
                                        ),
                                      ]
                                    : [Text('Hello $displayName!')]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.assignment),
                    title: Text('Completed Turns:'),
                    trailing: Text(
                      '${snapshot.data?.userInfo?.statsTotalTurns ?? '?'}',
                      style: Theme.of(context).textTheme.display1,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.thumb_up,
                      color: Colors.green,
                    ),
                    title: Text('Correct Answers:'),
                    trailing: Text(
                      '${snapshot.data?.userInfo?.statsCorrectAnswers ?? '?'}',
                      style: Theme.of(context).textTheme.display1,
                    ),
                  ),
                  Spacer(
                    flex: 1,
                  ),
                  ListTile(
                    leading: Icon(Icons.insert_invitation),
                    title: Text('Challenge a friend.'),
                    onTap: () {
                      Navigator.of(context).pushNamed(ChallengeInvite.ROUTE_NAME);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.view_list),
                    title: Text('Challenges'),
                    onTap: () {
                      Navigator.of(context).pushNamed(ChallengeList.ROUTE_NAME);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.list),
                    title: Text('Leaderboard'),
                    onTap: () {
                      Navigator.of(context).pushNamed(LeaderboardList.ROUTE_NAME);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text('How can we improve? Problems?'),
                    subtitle: Text('We love to hear from you at hello@anlage.app'),
                  ),
                  ListTile(
                    leading: Icon(Icons.link),
                    title: Text('By https://Anlage.App/'),
                    subtitle: Text('Track&Analyse your portfolio.'),
                    onTap: () async {
                      final url = 'https://anlage.app/?utm_source=marketcap-game';
                      if (await canLaunch(url)) {
                        await launch(url, forceSafariVC: false);
                      } else {
                        _logger.severe('Unable to launch url $url');
                      }
                    },
                  )
                ],
              );
            }),
      ),
    );
  }
}

//Drawer createNavigationDrawerProfile() {
//  final _api = ApiService.instance;
//  return Drawer(
//    child: ListView(
//      children: <Widget>[
//        Container(
//          alignment: Alignment.centerRight,
//          padding: EdgeInsets.all(8),
//          child: Column(
//            children: <Widget>[
//              CircleAvatar(
//                backgroundColor: Colors.white,
//                backgroundImage: _api.getAvatarUrl() == null ? null : CachedNetworkImageProvider(_api.getAvatarUrl()),
//                radius: 64,
//              )
//            ],
//          ),
//        )
//      ],
//    ),
//  );
//}
