import 'package:anlage_app_game/api/api_challenge_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/screens/leaderboard.dart';
import 'package:anlage_app_game/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../market_cap_sorting.dart';

class Challenge extends StatefulWidget {
  final MarketCapSortingChallengeBloc gameBloc;

  const Challenge({Key key, @required this.gameBloc}) : super(key: key);

  @override
  _ChallengeState createState() => _ChallengeState();
}

class _ChallengeState extends State<Challenge> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.gameBloc.currentTurn < 0) {
      widget.gameBloc.nextTurn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameSimpleSetResponse>(
        stream: widget.gameBloc.simpleGameSet,
        builder: (context, snapshot) => MarketCapSortingScreen(widget.gameBloc, snapshot));
  }
}

class ChallengeList extends StatefulWidget {
  static const ROUTE_NAME = '/challenge/list';

  @override
  _ChallengeListState createState() => _ChallengeListState();
}

class _ChallengeListState extends State<ChallengeList> {
  Deps _deps;

  Future<GameChallengeListResponse> _listFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this._deps = DepsProvider.of(context);
    _deps.cloudMessaging.requestPermission();
    _refresh();
  }

  void _refresh() {
    _listFuture = _deps.apiChallenge.listChallenges().catchError(DialogUtil.genericErrorDialog(context));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GameChallengeInfoDto>>(
      future: _listFuture.then((response) {
        if (response.currentWeeklyChallenge.myParticipantStatus == GameChallengeParticipantStatus.Invited) {
          return [response.currentWeeklyChallenge] + response.challenges;
        }
        return response.challenges;
      }),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Challenges'),
          ),
          body: !snapshot.hasData
              ? Center(child: CircularProgressIndicator())
              : ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                        height: 0,
                      ),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, idx) {
                    final item = snapshot.data[idx];
                    final isWeeklyChallenge = item.type == GameChallengeType.WeeklyChallenge;
                    return Theme(
                      data: Theme.of(context).copyWith(textTheme: Theme.of(context).accentTextTheme),
                      child: Ink(
                        color: isWeeklyChallenge && item.myParticipantStatus != GameChallengeParticipantStatus.Finished ? Theme.of(context).accentColor : null,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          leading: Avatar(
                              item.createdBy == null ? _deps.api.currentLoginState.avatarUrl : item.createdBy.avatarUrl),
                          title: isWeeklyChallenge ? Text('Weekly challenge!') : Text('Created ${_deps.formatUtil.formatRelativeFuzzy(item.createdAt.dateTime)}'),
                          subtitle: isWeeklyChallenge ? Text('Participate now!') : Text(item.createdBy == null ? 'by you.' : 'by: ${item.createdBy.displayName}.'),
                          trailing: Icon(
                            item.myParticipantStatus == GameChallengeParticipantStatus.Finished
                                ? Icons.check
                                : item.status == GameChallengeStatus.Accepted ? Icons.play_arrow : Icons.markunread_mailbox,
                          ),
                          onTap: () {
                            if (item.myParticipantStatus == GameChallengeParticipantStatus.Invited &&
                                item.inviteToken != null) {
                              Navigator.of(context).push(
                                AnalyticsPageRoute(
                                    name: '/challenge/invite/info',
                                    builder: (context) => ChallengeInviteInfo(
                                          inviteToken: item.inviteToken,
                                        )),
                              ).then((ret) {
                                _refresh();
                              });
                            } else {
                              Navigator.of(context).push(AnalyticsPageRoute(
                                  name: '/challenge/details', builder: (context) => ChallengeDetails(item.challengeId)));
                            }
                          },
                          onLongPress: () {
                            // TODO for debugging purposes.. but we should remove this :)
                            showModalBottomSheet(
                                context: context, builder: (context) => ChallengeListActionBottomSheet(item));
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class ChallengeListActionBottomSheet extends StatelessWidget {
  final GameChallengeInfoDto challengeInfo;

  ChallengeListActionBottomSheet(this.challengeInfo);

  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);
    final apiChallenge = deps.apiChallenge;
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("Challenge", style: Theme.of(context).textTheme.headline),
          ListTile(
            leading: Icon(Icons.play_arrow),
            title: Text('Start'),
            onTap: () {
              apiChallenge.startChallenge(this.challengeInfo.challengeId).then((challenge) {
                final bloc = MarketCapSortingChallengeBloc(deps.api, challenge);
                Navigator.of(context).pushReplacement(AnalyticsPageRoute(
                    name: '/challenge/game',
                    builder: (context) => Challenge(
                          gameBloc: bloc,
                        )));
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.details),
            title: Text('Details/Results'),
            onTap: () {
              Navigator.of(context).pushReplacement(AnalyticsPageRoute(
                  name: '/challenge/details', builder: (context) => ChallengeDetails(challengeInfo.challengeId)));
            },
          )
        ],
      ),
    );
  }
}

class ChallengeDetails extends StatefulWidget {
  final String challengeId;

  ChallengeDetails(this.challengeId);

  @override
  _ChallengeDetailsState createState() => _ChallengeDetailsState();
}

class _ChallengeDetailsState extends State<ChallengeDetails> {
  ApiChallenge _apiChallenge;

  Future<GameChallengeDetailsResponse> detailsFuture;

  Deps _deps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deps = DepsProvider.of(context);
    _apiChallenge = _deps.apiChallenge;
    if (detailsFuture == null) {
      detailsFuture = _apiChallenge.getGameChallengeDetails(widget.challengeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameChallengeDetailsResponse>(
      future: detailsFuture,
      builder: (context, snapshot) {
        final details = snapshot.data;
        final createdBy = details?.baseInfo?.createdBy;
        final createdAt = details?.baseInfo?.createdAt?.dateTime;

        List<Widget> actions = [];
        if (details?.baseInfo?.status == GameChallengeStatus.Accepted) {
          if (details?.baseInfo?.myParticipantStatus == GameChallengeParticipantStatus.Ready ||
              details?.baseInfo?.myParticipantStatus == GameChallengeParticipantStatus.TurnsCreated)
            actions = [
              RaisedButton(
                child: Text('Play Now'),
                onPressed: () {
                  _apiChallenge
                      .startChallenge(details.baseInfo.challengeId, action: GameChallengeAction.Retrieve)
                      .then((challenge) {
                    final bloc = MarketCapSortingChallengeBloc(_deps.api, challenge);
                    Navigator.of(context).push(AnalyticsPageRoute(
                        name: '/challenge/game',
                        builder: (context) => Challenge(
                              gameBloc: bloc,
                            )));
                  });
                },
              ),
            ];
        }

        final statusText = (GameChallengeParticipantStatus status) {
          switch (status) {
            case GameChallengeParticipantStatus.Invited:
              return Text('Did not accept invitation.');
            case GameChallengeParticipantStatus.TurnsCreated:
            case GameChallengeParticipantStatus.Ready:
              return Text('Did not finish yet.');
            case GameChallengeParticipantStatus.Finished:
              return null;
          }
        };

        return Scaffold(
          appBar: AppBar(
            title: Text('Challenge Details'),
          ),
          body: !snapshot.hasData
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: createdBy == null
                              ? Text('You created this callenge ${_deps.formatUtil.formatRelativeFuzzy(createdAt)}.')
                              : details.baseInfo.type == GameChallengeType.WeeklyChallenge
                              ? Text('Weekly Challenge')
                              : Text(
                                  'Challenge created by ${details.baseInfo.createdBy.displayName}, ${_deps.formatUtil.formatRelativeFuzzy(createdAt)}.'),
                        ),
                      ] +
                      [] +
                      actions +
                      [
                        Expanded(
                          child: ListView.separated(
                            separatorBuilder: (context, index) => Divider(height: 0),
                            itemBuilder: (context, index) {
                              final p = details.participants[index];
                              return LeaderboardListTile(
                                rank: index + 1,
                                displayName: p.baseInfo.displayName,
                                avatarUrl: p.baseInfo.avatarUrl,
                                statsCorrectAnswers: p.statsCorrectAnswers,
                                isMyself: p.myself,
                                subtitle: statusText(p.status),
                              );
//                          return ListTile(
//                            leading: Avatar(p.baseInfo.avatarUrl),
//                            title: Text(p.baseInfo.displayName),
//                            trailing: Text(
//                              p.statsCorrectAnswers.toString(),
//                              style: Theme.of(context).textTheme.title.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
//                            ),
//                          );
                            },
                            itemCount: details.participants.length,
                          ),
                        )
                      ],
                ),
        );
      },
    );
  }
}
