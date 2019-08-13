import 'dart:math';

import 'package:anlage_app_game/api/api_challenge_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/ui/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/ui/screens/leaderboard.dart';
import 'package:anlage_app_game/ui/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../market_cap_sorting.dart';

class Challenge extends StatefulWidget {
  const Challenge({Key key, @required this.gameBloc}) : super(key: key);

  final MarketCapSortingChallengeBloc gameBloc;

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

enum ChallengeListItemType { Challenge, InviteCta }

class ChallengeListItem {
  ChallengeListItem.info(this.challengeInfo) : type = ChallengeListItemType.Challenge;
  ChallengeListItem.type(this.type);
  ChallengeListItemType type;
  GameChallengeInfoDto challengeInfo;
}

class _ChallengeListState extends State<ChallengeList> {
  Deps _deps;

  Future<GameChallengeListResponse> _listFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deps = DepsProvider.of(context);
    _deps.cloudMessaging.requestPermission();
    _refresh();
  }

  void _refresh() {
    _listFuture = _deps.apiChallenge.listChallenges().catchError(DialogUtil.genericErrorDialog(context));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChallengeListItem>>(
      future: _listFuture.then((response) {
        final challenges = response.challenges.map((c) => ChallengeListItem.info(c)).toList(growable: true);
        if (response.currentWeeklyChallenge.myParticipantStatus == GameChallengeParticipantStatus.Invited) {
          challenges.insert(0, ChallengeListItem.info(response.currentWeeklyChallenge));
        }
        challenges.insert(min(challenges.length, 3), ChallengeListItem.type(ChallengeListItemType.InviteCta));
        return challenges;
      }),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Challenges'),
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  separatorBuilder: (context, index) => const Divider(
                    height: 0,
                  ),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, idx) {
                    final item = snapshot.data[idx];
                    if (item.type == ChallengeListItemType.InviteCta) {
                      return ChallengeInviteCta();
                    }
                    final challenge = item.challengeInfo;
                    final isWeeklyChallenge = challenge.type == GameChallengeType.WeeklyChallenge;
                    return Theme(
                      data: Theme.of(context).copyWith(textTheme: Theme.of(context).accentTextTheme),
                      child: Ink(
                        color: isWeeklyChallenge &&
                                challenge.myParticipantStatus != GameChallengeParticipantStatus.Finished
                            ? Theme.of(context).accentColor
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: Avatar(challenge.createdBy == null
                              ? _deps.api.currentLoginState.avatarUrl
                              : challenge.createdBy.avatarUrl),
                          title: challenge.title.isNotEmpty
                              ? Text(challenge.title)
                              : isWeeklyChallenge
                                  ? const Text('Weekly challenge!')
                                  : Text(
                                      'Created ${_deps.formatUtil.formatRelativeFuzzy(challenge.createdAt.dateTime)}'),
                          subtitle: isWeeklyChallenge
                              ? const Text('Participate now!')
                              : Text(
                                  challenge.createdBy == null ? 'by you.' : 'by: ${challenge.createdBy.displayName}.'),
                          trailing: Icon(
                            challenge.myParticipantStatus == GameChallengeParticipantStatus.Finished
                                ? Icons.check
                                : challenge.status == GameChallengeStatus.Accepted
                                    ? Icons.play_arrow
                                    : Icons.markunread_mailbox,
                          ),
                          onTap: () {
                            if (challenge.myParticipantStatus == GameChallengeParticipantStatus.Invited &&
                                challenge.inviteToken != null) {
                              Navigator.of(context)
                                  .push<dynamic>(
                                AnalyticsPageRoute<dynamic>(
                                    name: '/challenge/invite/info',
                                    builder: (context) => ChallengeInviteInfo(
                                          inviteToken: challenge.inviteToken,
                                        )),
                              )
                                  .then((dynamic ret) {
                                _refresh();
                              });
                            } else {
                              Navigator.of(context).push<dynamic>(AnalyticsPageRoute<dynamic>(
                                  name: '/challenge/details',
                                  builder: (context) => ChallengeDetails(challenge.challengeId)));
                            }
                          },
                          onLongPress: () {
                            // TODO for debugging purposes.. but we should remove this :)
                            showModalBottomSheet<dynamic>(
                                context: context, builder: (context) => ChallengeListActionBottomSheet(challenge));
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

class ChallengeInviteCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Ink(
        color: Theme.of(context).primaryColorLight,
        child: ListTile(
          contentPadding: const EdgeInsets.all(32),
          title: Column(
            children: <Widget>[
              Container(
                child: Icon(Icons.send),
              ),
              Container(
                margin: const EdgeInsets.only(top: 32),
                child: const Text('Challenge a friend'),
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed(ChallengeInvite.ROUTE_NAME);
          },
        ),
      ),
    );
  }
}

class ChallengeListActionBottomSheet extends StatelessWidget {
  const ChallengeListActionBottomSheet(this.challengeInfo);

  final GameChallengeInfoDto challengeInfo;

  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);
    final apiChallenge = deps.apiChallenge;
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Challenge', style: Theme.of(context).textTheme.headline),
          ListTile(
            leading: Icon(Icons.play_arrow),
            title: const Text('Start'),
            onTap: () {
              apiChallenge.startChallenge(challengeInfo.challengeId).then((challenge) {
                final bloc = MarketCapSortingChallengeBloc(
                  deps.api,
                  challenge,
                  companyInfoStore: deps.companyInfoStore,
                );
                Navigator.of(context).pushReplacement<dynamic, dynamic>(AnalyticsPageRoute<dynamic>(
                    name: '/challenge/game',
                    builder: (context) => Challenge(
                          gameBloc: bloc,
                        )));
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.details),
            title: const Text('Details/Results'),
            onTap: () {
              Navigator.of(context).pushReplacement<dynamic, dynamic>(AnalyticsPageRoute<dynamic>(
                  name: '/challenge/details', builder: (context) => ChallengeDetails(challengeInfo.challengeId)));
            },
          )
        ],
      ),
    );
  }
}

class ChallengeDetails extends StatefulWidget {
  const ChallengeDetails(this.challengeId);

  final String challengeId;

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
    detailsFuture ??= _apiChallenge.getGameChallengeDetails(widget.challengeId);
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
              details?.baseInfo?.myParticipantStatus == GameChallengeParticipantStatus.TurnsCreated) {
            actions = [
              RaisedButton(
                child: const Text('Play Now'),
                onPressed: () {
                  _apiChallenge
                      .startChallenge(details.baseInfo.challengeId, action: GameChallengeAction.Retrieve)
                      .then((challenge) {
                    final bloc =
                        MarketCapSortingChallengeBloc(_deps.api, challenge, companyInfoStore: _deps.companyInfoStore);
                    Navigator.of(context).push<dynamic>(AnalyticsPageRoute<dynamic>(
                        name: '/challenge/game',
                        builder: (context) => Challenge(
                              gameBloc: bloc,
                            )));
                  });
                },
              ),
            ];
          }
        }

        final statusText = (GameChallengeParticipantStatus status) {
          switch (status) {
            case GameChallengeParticipantStatus.Invited:
              return const Text('Did not accept invitation.');
            case GameChallengeParticipantStatus.TurnsCreated:
            case GameChallengeParticipantStatus.Ready:
              return const Text('Did not finish yet.');
            case GameChallengeParticipantStatus.Finished:
              return null;
          }
          throw StateError('Invalid status $status');
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Challenge Details'),
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: createdBy == null
                              ? Text('You created this callenge ${_deps.formatUtil.formatRelativeFuzzy(createdAt)}.')
                              : details.baseInfo.type == GameChallengeType.WeeklyChallenge
                                  ? const Text('Weekly Challenge')
                                  : Text(
                                      'Challenge created by ${details.baseInfo.createdBy.displayName}, ${_deps.formatUtil.formatRelativeFuzzy(createdAt)}.'),
                        ),
                      ] +
                      [] +
                      actions +
                      [
                        Expanded(
                          child: ListView.separated(
                            separatorBuilder: (context, index) => const Divider(height: 0),
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
