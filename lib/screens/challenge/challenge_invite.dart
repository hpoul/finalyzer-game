import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:logging/logging.dart';
import 'package:share/share.dart';

final _logger = Logger('app.anlage.game.screens.challenge.challenge_invite');

class ChallengeInvite extends StatelessWidget {
  static const ROUTE_NAME = '/challenge/invite';

  static const URL_QUERY_PARAM_TOKEN = 'inviteToken';
  static const URL_PATH = '/game/invite/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge Friend'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: ChallengeInviteForm(),
      ),
    );
  }
}

class ChallengeInviteForm extends StatefulWidget {
  @override
  _ChallengeInviteFormState createState() => _ChallengeInviteFormState();
}

class _ChallengeInviteFormState extends State<ChallengeInviteForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();

  Future<dynamic> _createFuture;

  @override
  Widget build(BuildContext context) {
    Deps deps = DepsProvider.of(context);
    final apiChallenge = deps.apiChallenge;
    return Form(
      key: _formKey,
      child: FutureBuilder(
        future: _createFuture,
        builder: (context, snapshot) {
          return Column(
            children: <Widget>[
              Text(
                  "Challenge your friends to a round of MarketCap Game! Once your friends accepts your invitation, you "
                  "will both receive the same set of challenges."),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Who do you want to challenge?',
                  style: Theme.of(context).textTheme.subhead.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextFormField(
                controller: _displayNameCtrl,
                decoration: InputDecoration(
                  icon: Icon(Icons.person),
                  labelText: 'Name (Optional)',
                  hintText: 'Max',
                ),
              ),
              RaisedButton.icon(
                icon: Icon(Icons.create),
                color: Theme.of(context).accentColor,
                label: Text('Create Challenge'),
                onPressed: () {
                  _logger.fine('Creating challenge ...');
                  _createFuture = apiChallenge.createChallengeInvite(_displayNameCtrl.text).then((value) {
                    _logger.fine('Created challenge ${value.toJson()}');
                    return _createInviteLink(deps, value);
                  }).then((dynamicLink) {
                    _logger.fine('Created url: $dynamicLink');
                    Share.share('Beat me by guessing Market Caps! $dynamicLink');
                  }).catchError((error, stackTrace) {
                    _logger.warning('Error producing challenge invite.', error, stackTrace);
                    return Future.error(error, stackTrace);
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Uri> _createInviteLink(Deps deps, GameChallengeInviteResponse value) {
    final params = DynamicLinkParameters(
        domain: deps.firebaseConfig.domain,
        link: Uri.parse('https://anlage.app${ChallengeInvite.URL_PATH}')
            .replace(queryParameters: {ChallengeInvite.URL_QUERY_PARAM_TOKEN: value.inviteToken}),
        androidParameters: AndroidParameters(
          packageName: deps.firebaseConfig.androidPackageName,
        ),
        iosParameters: IosParameters(
          bundleId: deps.firebaseConfig.domain,
          appStoreId: deps.firebaseConfig.iosAppStoreId,
//          customScheme: deps.firebaseConfig.iosCustomScheme,
        ),
        googleAnalyticsParameters: GoogleAnalyticsParameters(
          campaign: 'challenge',
          medium: 'app',
          source: 'game',
        ));
//    return params.buildShortLink().then((shortLink) => shortLink.shortUrl);
    return params.buildUrl();
  }
}

class ChallengeInviteInfo extends StatefulWidget {
  final String inviteToken;

  ChallengeInviteInfo({@required this.inviteToken});

  @override
  _ChallengeInviteInfoState createState() => _ChallengeInviteInfoState();
}

class _ChallengeInviteInfoState extends State<ChallengeInviteInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accepting invitation'),
      ),
      body: Column(
        children: <Widget>[
          Text('You want to accept invite ${widget.inviteToken}'),
        ],
      ),
    );
  }
}
