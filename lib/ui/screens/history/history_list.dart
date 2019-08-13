import 'package:anlage_app_game/data/company_info_store.dart';
import 'package:anlage_app_game/ui/screens/company_details.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ReversedListView<T> {
  ReversedListView(this._list);

  final List<T> _list;

  int get length => _list.length;

  T operator [](int index) => _list[length - index - 1];
}

class HistoryList extends StatelessWidget {
  static const String ROUTE_NAME = '/history';

  static PageRoute<void> get route => AnalyticsPageRoute(
        name: ROUTE_NAME,
        builder: (context) => HistoryList(),
      );

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<CompanyInfoData>(context);
    final history = ReversedListView(data.history.toList(growable: false));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Games and Companies'),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) => HistoryGameTurnTile(data: data, turn: history[index]),
      ),
    );
  }
}

class HistoryGameTurnTile extends StatelessWidget {
  const HistoryGameTurnTile({Key key, this.data, this.turn}) : super(key: key);

  final CompanyInfoData data;
  final HistoryGameSet turn;

  @override
  Widget build(BuildContext context) {
    final apiService = Deps.of(context).api;
    final formatUtil = Provider.of<FormatUtil>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${formatUtil.formatRelativeFuzzy(turn.playAt.toLocal())}, you made ${turn.points} points.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...turn.instruments.map((key) {
          final instrument = data.companyInfos[key];
          return ListTile(
            leading: CachedNetworkImage(
              width: 100,
              height: 50,
              imageUrl: apiService.getImageUrl(instrument.logo),
            ),
            title: Text(instrument.details.name),
            subtitle: Text(instrument.details.symbol),
            onTap: () {
              Navigator.of(context).push(CompanyDetailsScreen.route(instrument.details, instrument.logo));
            },
          );
        }),
        const Divider(),
      ],
    );
  }
}
