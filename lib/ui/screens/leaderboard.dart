import 'dart:math' as math;
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/ui/widgets/index_offset_list_view.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/widgets/avatar.dart';
import 'package:anlage_app_game/utils/widgets/error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.ui.screens.leaderboard');

class LeaderboardList extends StatefulWidget {
  static const ROUTE_NAME = '/leaderboard';

  @override
  State<StatefulWidget> createState() {
    return LeaderboardListState();
  }
}

class LeaderboardListState extends State<LeaderboardList> {
  final leaderboardScaffold = GlobalKey<ScaffoldState>();
  Future<LeaderboardSimpleResponse> _leaderboardFuture;

  @override
  Widget build(BuildContext context) {
    final api = DepsProvider.of(context).api;

    return Scaffold(
      key: leaderboardScaffold,
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: SafeArea(
        child: FutureBuilder<LeaderboardSimpleResponse>(
            future: _leaderboardFuture ??= api.fetchLeaderboard(),
            builder: (context, snapshot) {
              if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return ErrorWidgetWithRetry(
                  error: snapshot.error,
                  onRetry: () {
                    setState(() {
                      _leaderboardFuture = api.fetchLeaderboard();
                    });
                  },
                );
              }

              final list = snapshot.data.leaderboardEntries.toList();
              return IndexOffsetListView.builder(
                initialIndex: math.max(list.indexWhere((e) => e.loggedInUser) - 5, 0),
                itemCount: snapshot.data.leaderboardEntries.length,
                itemBuilder: (context, idx) {
                  assert(idx >= 0 && idx < list.length);
                  final entry = list[idx];
                  return LeaderboardListTile(
                    rank: entry.rank,
                    displayName: entry.displayName,
                    avatarUrl: api.resolveUri(entry.avatarUrl),
                    isMyself: entry.loggedInUser,
                    statsCorrectAnswers: entry.statsCorrectAnswers,
                    onTap: () {
                      showModalBottomSheet<dynamic>(
                        context: context,
                        builder: (context) => BottomSheet(
                            onClosing: () {}, builder: (context) => LeaderBoardBottomSheet(entry, leaderboardScaffold)),
                      );
                    },
                  );
                },
              );
            }),
      ),
    );
  }
}

class LeaderBoardBottomSheet extends StatelessWidget {
  const LeaderBoardBottomSheet(this.entry, this.leaderboardScaffold);

  final LeaderboardEntry entry;
  final GlobalKey<ScaffoldState> leaderboardScaffold;

  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);
    final apiChallenge = deps.apiChallenge;
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('${entry.displayName}', style: Theme.of(context).textTheme.headline),
          ListTile(
            leading: Icon(Icons.send),
            title: const Text('Send Challenge'),
            onTap: () {
              leaderboardScaffold.currentState.showSnackBar(const SnackBar(content: Text('Sending Challenge …')));
              Navigator.of(context).pop();
              apiChallenge
                  .createChallengeInvite(GameChallengeInviteType.DirectInvite, gameUserToken: entry.userToken)
                  .then((val) {
                _logger.fine('Created Challenge.');
                leaderboardScaffold.currentState
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Row(
                    children: const <Widget>[Text('Invitation sent successfully️'), Icon(Icons.check)],
                  )));
//                    DialogUtil.showSimpleAlertDialog(context, null, 'Sent invitation.');
              }).catchError(DialogUtil.genericErrorDialog(context));
            },
          ),
        ],
      ),
    );
  }
}

class LeaderboardListTile extends StatelessWidget {
  const LeaderboardListTile({
    Key key,
    this.rank,
    this.displayName,
    this.avatarUrl,
    this.statsCorrectAnswers,
    this.isMyself,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  final int rank;
  final String displayName;
  final String avatarUrl;
  final int statsCorrectAnswers;
  final bool isMyself;
  final Widget subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Ink(
      color: isMyself ? Colors.lightGreen : null,
      child: ListTile(
        leading: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
                padding: const EdgeInsets.only(right: 8.0),
                constraints: const BoxConstraints(minWidth: 50),
                child: Text(
                  '$rank.',
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.right,
                )),
            Avatar(avatarUrl + '?asdfx'),
          ],
        ),
        title: Text(displayName),
        trailing: Text(
          statsCorrectAnswers.toString(),
        ),
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
