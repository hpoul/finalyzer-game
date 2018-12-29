import 'package:anlage_app_game/utils/deps.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Avatar extends StatelessWidget {

  final String avatarUrl;

  Avatar(this.avatarUrl);

  @override
  Widget build(BuildContext context) {
    final url = DepsProvider.of(context).api.resolveUri(avatarUrl).toString();
    return CircleAvatar(
//      backgroundColor: Theme.of(context).primaryColorDark,
      backgroundImage: CachedNetworkImageProvider(url),
    );
  }
}
