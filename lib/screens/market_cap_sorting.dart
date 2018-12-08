import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = new Logger("app.anlage.game.screens.market_cap_sorting");


class MarketCapSorting extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingState();
  }
}

class MarketCapScalePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset(16.0, 16.0) & Size(16.0, size.height - 32.0);

    canvas.drawRect(rect, Paint()
      ..color = Colors.green);
  }

  @override
  bool shouldRepaint(MarketCapScalePainter oldDelegate) {
    return false;
  }

}

class MarketPriceLayoutDelegate extends MultiChildLayoutDelegate {

  Iterable<MapEntry<String, double>> marketCapPositions;
  GameSimpleSetResponse simpleGameSet;

  MarketPriceLayoutDelegate(this.marketCapPositions, this.simpleGameSet);

  @override
  void performLayout(Size size) {
    var range = simpleGameSet.marketCapScaleMax - simpleGameSet.marketCapScaleMin;
    var widgetRange = size.height / range;
    marketCapPositions.forEach((i) {
      var s = layoutChild(i.key, BoxConstraints.loose(size));
      var pos = i.value - this.simpleGameSet.marketCapScaleMin;
      positionChild(i.key, Offset(100, widgetRange * pos));
      _logger.fine('positioning child at ${widgetRange * pos} (for value: ${i.value})');
    });
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }

}

class MarketCapSortingState extends State<MarketCapSorting> {

  GameSimpleSetResponse simpleGameSet;
  Iterable<MapEntry<String, double>> marketCapPositions;

  @override
  Widget build(BuildContext context) {

    if (simpleGameSet == null || marketCapPositions == null) {
      ApiService.instance.getSimpleGameSet().then((val) {
        setState(() {
          simpleGameSet = val;
          final totalRange = simpleGameSet.marketCapScaleMax - simpleGameSet.marketCapScaleMin;
          final padding = totalRange * 0.1;
          final rangeMin = simpleGameSet.marketCapScaleMin + padding;
          final range = totalRange - 2*padding;
          var singlePos = range / (val.simpleGame.length-1);
          var i = 0;

          _logger.fine('Positining simpleGame starting at ${simpleGameSet.marketCapScaleMin} ${i}');
          marketCapPositions = val.simpleGame.map((dto) => MapEntry(dto.instrumentKey, rangeMin + (singlePos * i++))).toList();
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Market Cap Game by https://Anlage.App'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Sort the given companies based on their market cap!',
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: simpleGameSet == null || marketCapPositions == null ? CircularProgressIndicator() : CustomPaint(
                foregroundPainter: MarketCapScalePainter(),
                child: CustomMultiChildLayout(
                  delegate: MarketPriceLayoutDelegate(marketCapPositions, simpleGameSet),
                  children: simpleGameSet.simpleGame.map((val) => LayoutId(id: val.instrumentKey, child: Text("something"))).toList(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
