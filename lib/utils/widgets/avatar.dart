import 'package:anlage_app_game/utils/deps.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.utils.widgets.avatar');

class Avatar extends StatelessWidget {
  final String avatarUrl;
  final double radius;

  Avatar(this.avatarUrl, {this.radius});

  @override
  Widget build(BuildContext context) {
    final url = DepsProvider.of(context).api.resolveUri(avatarUrl).toString();
    return CircleAvatar(
//      backgroundColor: Theme.of(context).primaryColorDark,
      backgroundImage: CachedNetworkImageProvider(url, errorListener: () {
        _logger.severe('Error while loading avatar from ${avatarUrl}');
      }),
      radius: radius,
    );
  }
}
