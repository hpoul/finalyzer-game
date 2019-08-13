import 'dart:ui' as ui;

import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/data/company_info_store.dart';
import 'package:anlage_app_game/ui/screens/history/history_list.dart';
import 'package:anlage_app_game/ui/screens/market_cap_sorting_help.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class MarketCapAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MarketCapAppBar({Key key, this.api}) : super(key: key);

  final ApiService api;
  @override
  ui.Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final companyInfoData = Provider.of<CompanyInfoData>(context);
    return AppBar(
      title: const Text('Market Cap Game'),
      actions: <Widget>[
        ...(companyInfoData?.history?.isNotEmpty != true
            ? []
            : [
                IconButton(
                  icon: Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(HistoryList.route);
                  },
                ),
              ]),
        IconButton(
            icon: Icon(Icons.help),
            onPressed: () async {
              await showDialog<dynamic>(context: context, builder: (context) => MarketCapSortingHelpDialog());
            }),
        StreamBuilder<LoginState>(
          builder: (context, snapshot) => IconButton(
              iconSize: 36,
              icon: CircleAvatar(
                  maxRadius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      snapshot.data?.avatarUrl == null ? null : CachedNetworkImageProvider(snapshot.data.avatarUrl)),
              onPressed: () {
                AnalyticsUtils.instance.analytics.logEvent(name: 'drawer_open_click_avatar');
                Scaffold.of(context).openEndDrawer();
              }),
          stream: api.loginState,
        ),
      ],
    );
  }
}
