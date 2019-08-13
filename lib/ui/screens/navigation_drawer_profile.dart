import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/ui/screens/challenge/challenge.dart';
import 'package:anlage_app_game/ui/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/ui/screens/leaderboard.dart';
import 'package:anlage_app_game/ui/screens/profile_edit.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('app.anlage.game.ui.screens.navigation_drawer_profile');

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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Error while fetching user information.'),
                      RaisedButton(
                        child: const Text('Retry'),
                        onPressed: () {
                          _api.triggerUpdateUserInfo();
                        },
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                _logger.fine(snapshot);
                return const Center(
//                  heightFactor: 1.5,
                  child: CircularProgressIndicator(),
                );
              }

              return FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, packageInfoSnapshot) {
                    return NavigationDrawerContent(
                      loginType: snapshot.data,
                      packageInfo: packageInfoSnapshot.data,
                    );
                  });
            }),
      ),
    );
  }
}

class NavigationDrawerContent extends StatelessWidget {
  const NavigationDrawerContent({Key key, @required this.loginType, @required this.packageInfo})
      : assert(loginType != null),
        super(key: key);

  final LoginState loginType;
  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) {
    final displayName = loginType.userInfo?.displayName ?? '';
    final userType = loginType.userInfo?.userType ?? GameUserType.User;
    return Column(
      mainAxisSize: MainAxisSize.max,
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
              padding: const EdgeInsets.all(16).copyWith(top: MediaQuery.of(context).padding.top + 16),
              child: DefaultTextStyle(
                style: Theme.of(context).primaryTextTheme.body1,
                textAlign: TextAlign.right,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          constraints: const BoxConstraints.tightFor(width: 128, height: 128),
                          child: AvatarWithEditIcon(
                            loginType.avatarUrl,
                            radius: 64,
                          ),
                        ),
                      ] +
                      (displayName == ''
                          ? [
                              Text(
                                'Hello Anonymous Investor!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Tell us a bit about you to get listed in the leaderboard!',
                              ),
                            ]
                          : [Text('Hello $displayName!')]) +
                      (userType == GameUserType.User
                          ? []
                          : [
                              Text(
                                '(${convertGameUserTypeToJson(userType)})',
                                style: Theme.of(context).textTheme.caption,
                              )
                            ]),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.assignment),
                          title: const Text('Completed Turns:'),
                          trailing: Text(
                            '${loginType.userInfo?.statsTotalTurns ?? '?'}',
                            style: Theme.of(context).textTheme.display1,
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.thumb_up,
                            color: Colors.green,
                          ),
                          title: const Text('Correct Answers:'),
                          trailing: Text(
                            '${loginType.userInfo?.statsCorrectAnswers ?? '?'}',
                            style: Theme.of(context).textTheme.display1,
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.send),
                          title: const Text('Challenge a friend.'),
                          onTap: () {
                            Navigator.of(context).pushNamed(ChallengeInvite.ROUTE_NAME);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.view_list),
                          title: const Text('Challenges'),
                          onTap: () {
                            Navigator.of(context).pushNamed(ChallengeList.ROUTE_NAME);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.format_list_numbered),
                          title: const Text('Leaderboard'),
                          onTap: () {
                            Navigator.of(context).pushNamed(LeaderboardList.ROUTE_NAME);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: const Text('How can we improve? Problems?'),
                          subtitle: const Text('We love to hear from you at hello@anlage.app'),
                          onTap: () {
                            DialogUtil.openFeedback(origin: 'drawer');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.link),
                          title: const Text('By https://Anlage.App/'),
                          subtitle: const Text('Track&Analyse your portfolio.'),
                          onTap: () async {
                            const url = 'https://anlage.app/?utm_source=marketcap-game';
                            await DialogUtil.launchUrl(url);
                          },
                          onLongPress: () async {
                            _logger.severe('TEST Crash Stuff', Error(), StackTrace.current);
                            const url = 'https://anlage.app/?utm_source=marketcap-game';
                            if (await canLaunch(url)) {
                              await launch(url, forceSafariVC: false);
                            } else {
                              _logger.severe('Unable to launch url $url');
                            }
                          },
                        ),
                        ...(packageInfo == null
                            ? []
                            : [
                                Text(
                                  'MarketCap Game V${packageInfo.version}-${packageInfo.buildNumber}',
                                  style: TextStyle(color: Colors.black26, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                              ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
