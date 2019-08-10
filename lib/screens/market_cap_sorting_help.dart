import 'package:anlage_app_game/utils/deps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TextWithIcon extends StatelessWidget {
  const TextWithIcon({Key key, @required this.icon, @required this.label, this.reverse = false}) : super(key: key);

  final Widget icon;
  final String label;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final children = [
      icon,
      const SizedBox(width: 12),
      Text(label),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reverse ? children.reversed.toList(growable: false) : children,
    );
  }
}

class MarketCapSortingHelpDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Deps.of(context).analytics.setCurrentScreen(screenName: runtimeType.toString());
    return AlertDialog(
      title: const TextWithIcon(
        icon: Text('👋️'),
        label: 'MarketCap Sorting',
        reverse: true,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Welcome to the Market Cap Game! 😀️\n\n'
              'Sort the shown companies based on their current "Market cap". '
              'You do not have to match the exact value, but only sort the companies correctly '
              'by dragging their shown logos up and down.\n\n',
              style: Theme.of(context).textTheme.body2,
            ),
            Text(
              'The "Market Cap" is the current value of the company calculated by the current share price multipled '
              'by the number of outstanding shres.',
              style: Theme.of(context).textTheme.body2.apply(
                    color: Colors.black38,
                    fontSizeFactor: 0.8,
                  ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: const Text('Great, let\'s go!'),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        )
      ],
    );
  }
}
