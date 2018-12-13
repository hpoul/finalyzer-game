
import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = new Logger("app.anlage.game.screens.navigation_drawer_profile");


class NavigationDrawerProfile extends StatelessWidget {

  final _api = ApiService.instance;

  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: StreamBuilder<LoginState>(
          stream: _api.loginState,
          builder: (context, snapshot) => Column(
            children: <Widget>[
              Container(
                alignment: Alignment.centerRight,
                color: FinalyzerTheme.colorPrimary,
                padding: EdgeInsets.all(16).copyWith(top: MediaQuery.of(context).padding.top + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: snapshot.data == null ? null : CachedNetworkImageProvider(snapshot.data.avatarUrl),
                        radius: 64,
                      ),
                    ),
                    Text('Hello Anonymous Investor!', textAlign: TextAlign.right,),
                    Text('Maybe you could tell us a bit about you?', textAlign: TextAlign.right),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.assignment),
                title: Text('Completed Turns:'),
                trailing: Text('${snapshot.data?.userInfo?.statsTotalTurns ?? '?'}', style: Theme.of(context).textTheme.display1,),
              ),
              ListTile(
                leading: Icon(Icons.thumb_up, color: Colors.green,),
                title: Text('Correct Answers:'),
                trailing: Text('${snapshot.data?.userInfo?.statsCorrectAnswers ?? '?'}', style: Theme.of(context).textTheme.display1,),
              ),
              Spacer(flex: 1,),
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
          ),
        ),
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
