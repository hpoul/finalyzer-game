import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                return Center(child: CircularProgressIndicator(),);
              }

              final list = snapshot.data.leaderboardEntries.toList();
              return ListView.builder(
                itemCount: snapshot.data.leaderboardEntries.length,
                itemBuilder: (context, idx) {
                  final entry = list[idx];
                  return Container(
                    color: entry.loggedInUser ? Colors.lightGreen : null,
                    child: ListTile(
                      leading: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(right: 8.0),
                              child: Text('${entry.rank}.', style: Theme.of(context).textTheme.title,)
                          ),
                          CircleAvatar(radius: 20,backgroundImage: CachedNetworkImageProvider(api.resolveUri(entry.avatarUrl))),
                        ],
                      ),
                      title: Text(entry.displayName),
                      trailing: Text(entry.statsCorrectAnswers.toString(),),
                    ),
                  );
                },
              );
            }),
      ),
    );
  }
}
