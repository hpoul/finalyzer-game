import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.screens.leaderboard');

class LeaderboardList extends StatefulWidget {
  static const ROUTE_NAME = '/leaderboard';

  @override
  State<StatefulWidget> createState() {
    return LeaderboardListState();
  }
}

class LeaderboardListState extends State<LeaderboardList> {
  @override
  Widget build(BuildContext context) {
    final api = DepsProvider.of(context).api;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: SafeArea(
        child: FutureBuilder<LeaderboardSimpleResponse>(
            future: api.fetchLeaderboard(),
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final list = snapshot.data.leaderboardEntries.toList();
              return ListView.builder(
                itemCount: snapshot.data.leaderboardEntries.length,
                itemBuilder: (context, idx) {
                  final entry = list[idx];
                  return LeaderboardListTile(
                    rank: entry.rank,
                    displayName: entry.displayName,
                    avatarUrl: api.resolveUri(entry.avatarUrl),
                    isMyself: entry.loggedInUser,
                    statsCorrectAnswers: entry.statsCorrectAnswers,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => LeaderBoardBottomSheet(entry),
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

  final LeaderboardEntry entry;

  LeaderBoardBottomSheet(this.entry);



  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);
    final apiChallenge = deps.apiChallenge;
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("${entry.displayName}", style: Theme.of(context).textTheme.headline),
          ListTile(
            leading: Icon(Icons.send),
            title: Text('Send Challenge'),
            onTap: () {
              Navigator.of(context).pop();
              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Sending Challenge …')));
              apiChallenge.createChallengeInvite(GameChallengeInviteType.DirectInvite, gameUserToken: entry.userToken)
                  .then((val) {
                    _logger.fine('Created Challenge.');
                    DialogUtil.showSimpleAlertDialog(context, null, 'Sent invitation.');
                  }).catchError(DialogUtil.genericErrorDialog(context));
            },
          ),
        ],
      ),
    );
  }
}


class LeaderboardListTile extends StatelessWidget {
  final int rank;
  final String displayName;
  final String avatarUrl;
  final int statsCorrectAnswers;
  final bool isMyself;
  final Widget subtitle;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    _logger.finer('AvatarUrl: $avatarUrl');
    return Ink(
      color: isMyself ? Colors.lightGreen : null,
      child: ListTile(
        leading: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(right: 8.0),
                constraints: BoxConstraints(minWidth: 50),
                child: Text(
                  '$rank.',
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.right,
                )),
            Avatar(avatarUrl + "?asdfx"),
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
