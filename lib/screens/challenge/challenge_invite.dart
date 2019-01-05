import 'package:anlage_app_game/api/api_challenge_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge.dart';
import 'package:anlage_app_game/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/firebase_messaging.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/widgets/avatar.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:share/share.dart';

final _logger = Logger('app.anlage.game.screens.challenge.challenge_invite');

class ChallengeInvite extends StatelessWidget {
  static const ROUTE_NAME = '/challenge/invite';

  static const URL_QUERY_PARAM_TOKEN = 'inviteToken';
  static const URL_PATH = '/game/invite/';

  @override
  Widget build(BuildContext context) {
    DepsProvider.of(context).cloudMessaging.requestPermission();
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
          _logger.finer('snapshot: $snapshot');
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
                disabledColor: FinalyzerTheme.colorSecondary.withOpacity(0.5),
                label: Text('Create Challenge'),
                onPressed: snapshot.connectionState == ConnectionState.waiting ? null : () {
                  _logger.fine('Creating challenge ...');
                  setState(() {
                    _createFuture = apiChallenge.createChallengeInvite(GameChallengeInviteType.LinkInvite, displayName: _displayNameCtrl.text).then((value) {
                      _logger.fine('Created challenge ${value.toJson()}');
                      return _createInviteLink(deps, value);
                    }).then((dynamicLink) {
                      _logger.fine('Created url: $dynamicLink');
                      AnalyticsUtils.instance.analytics.logEvent(name: 'invite_create');
                      return Share.share('Beat me by guessing Market Caps! $dynamicLink');
                    }).catchError((error, stackTrace) {
                      _logger.warning('Error producing challenge invite.', error, stackTrace);
                      return Future.error(error, stackTrace);
                    });
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
    return params.buildShortLink().then((shortLink) => shortLink.shortUrl);
//    return params.buildUrl();
  }
}

class ChallengeInviteInfo extends StatefulWidget {
  final String inviteToken;

  ChallengeInviteInfo({@required this.inviteToken});

  @override
  _ChallengeInviteInfoState createState() => _ChallengeInviteInfoState();
}

class _ChallengeInviteInfoState extends State<ChallengeInviteInfo> {
  Future<GameChallengeInviteInfoResponse> _inviteInfoFuture;
  Future<GameChallengeDto> _acceptChallengeFuture;

  Deps _deps;
  ApiChallenge _apiChallenge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this._deps = DepsProvider.of(context);
    this._apiChallenge = _deps.apiChallenge;
    _requestInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accepting invitation'),
      ),
      body: FutureBuilder<GameChallengeInviteInfoResponse>(
        future: _inviteInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(onPressed: this._requestInfo, error: snapshot.error);
          }
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Loading invitation'),
                  ),
                ],
              ),
            );
          }
          final createdBy = snapshot.data.createdBy;
          return Container(
            alignment: Alignment(0, -0.4),
            margin: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Avatar(
                  createdBy.avatarUrl,
                  radius: 80,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                  child: Text(
                    createdBy.displayName,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                Text('You have been challenged by ${createdBy.displayName}. Do you want to play?'),
                FutureBuilder<GameChallengeDto>(
                  future: _acceptChallengeFuture,
                  builder: (context, snapshot) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton.icon(
                          onPressed: snapshot.connectionState == ConnectionState.waiting
                              ? null
                              : () {
                                  setState(() {
                                    _apiChallenge.acceptChallengeInvite(widget.inviteToken).then((value) {
                                      Navigator.of(context).pushReplacement(AnalyticsPageRoute(
                                        name: '/challenge/game',
                                          builder: (context) => Challenge(
                                                gameBloc: MarketCapSortingChallengeBloc(_deps.api, value),
                                              )));
                                    }).catchError(DialogUtil.genericErrorDialog(context));
                                  });
                                },
                          icon: Icon(Icons.check),
                          label: Text('Accept'),
                        ),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _requestInfo() {
    _logger.finer('Requesting invite info.');
    _inviteInfoFuture = _apiChallenge.getChallengeInviteInfo(widget.inviteToken).catchError((error, stackTrace) {
      _logger.warning('Error while requesting info', error, stackTrace);
      return Future.error(error, stackTrace);
    });
  }
}


class ErrorRetry extends StatelessWidget {
  final VoidCallback onPressed;
  final Error error;

  ErrorRetry({this.onPressed, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
//      mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text('Error while contacting server.'),
          RaisedButton.icon(onPressed: onPressed, icon: Icon(Icons.refresh), label: Text('Retry')),
        ],
      ),
    );
  }
}
