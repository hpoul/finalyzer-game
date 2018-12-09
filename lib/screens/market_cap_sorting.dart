import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';

final _logger = new Logger("app.anlage.game.screens.market_cap_sorting");

class MarketCapSorting extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingState();
  }
}

class MarketCapScalePainter extends CustomPainter {
  MarketCapScalePainter() {}

  @override
  void paint(Canvas canvas, Size size) {
    const scaleWidth = 8.0;

    var rect = Offset(16.0, 16.0) & Size(scaleWidth, size.height - 2 * scaleWidth);

    canvas.drawRect(rect, Paint()..color = FinalyzerTheme.colorPrimary);
//    canvas.draw
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

    var positions = List<Rect>();
    marketCapPositions.forEach((i) {
      var s = layoutChild(i.key, BoxConstraints.loose(size));
      var pos = i.value - this.simpleGameSet.marketCapScaleMin;

      var origin;
      var rect;
      int collissions = 0;

      do {
        origin = Offset(size.width - s.width - 8 - ((s.width + 8) * collissions), widgetRange * pos - s.height / 2);
        rect = origin & s;
        collissions ++;

      } while (positions.where((r) => r.overlaps(rect)).isNotEmpty);

      positionChild(i.key, origin);

      positions.add(rect);

//      _logger.fine(
//          'positioning child at ${widgetRange * pos} (for value: ${i.value})');
    });
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class MarketCapSortingState extends State<MarketCapSorting> {
  GameSimpleSetResponse simpleGameSet;

  final ApiService _apiService = ApiService.instance;

  @override
  Widget build(BuildContext context) {
    if (simpleGameSet == null) {
      _apiService.getSimpleGameSet().then((val) {
        setState(() {
          simpleGameSet = val;
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
                child: simpleGameSet == null ? CircularProgressIndicator() : MarketCapSortingScaleWidget(simpleGameSet))
          ],
        ),
      ),
    );
  }
}

class MarketCapSortingScaleWidget extends StatefulWidget {
  final GameSimpleSetResponse simpleGameSet;

  MarketCapSortingScaleWidget(this.simpleGameSet) {}

  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingScaleState();
  }

  static initPositions() {}
}

class MarketCapSortingScaleState extends State<MarketCapSortingScaleWidget> {
  final ApiService _apiService = ApiService.instance;
  Iterable<MapEntry<String, double>> marketCapPositions;

  double totalRange;
  String draggedInstrument = null;

  @override
  void initState() {
    super.initState();
    final simpleGameSet = widget.simpleGameSet;
    final totalRange = simpleGameSet.marketCapScaleMax - simpleGameSet.marketCapScaleMin;
    this.totalRange = totalRange;
    final padding = totalRange * 0.1;
    final rangeMin = simpleGameSet.marketCapScaleMin + padding;
    final range = totalRange - 2 * padding;
    var singlePos = range / (simpleGameSet.simpleGame.length - 1);
    var i = 0;

    _logger.fine('Positining simpleGame starting at ${simpleGameSet.marketCapScaleMin} ${i}');
    marketCapPositions =
        simpleGameSet.simpleGame.map((dto) => MapEntry(dto.instrumentKey, rangeMin + (singlePos * i++))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        foregroundPainter: MarketCapScalePainter(),
        child: CustomMultiChildLayout(
          delegate: MarketPriceLayoutDelegate(marketCapPositions, widget.simpleGameSet),
          children: widget.simpleGameSet.simpleGame.map((val) {
            return LayoutId(
                id: val.instrumentKey,
                child: GestureDetector(
                  onVerticalDragStart: (event) {
                    _logger.fine('started vertical dragging.');
                    setState(() {
                      draggedInstrument = val.instrumentKey;
                    });
                  },
                  onVerticalDragDown: (event) {
                    _logger.fine('vertical drag down');
                  },
                  onVerticalDragCancel: () {
                    _logger.fine('vertical drag cancel.');
                    setState(() {
                      draggedInstrument = null;
                    });
                  },
                  onVerticalDragEnd: (event) {
                    _logger.fine('vertical drag end.');
                    setState(() {
                      draggedInstrument = null;
                    });
                  },
                  onVerticalDragUpdate: (event) {
//                      _logger.fine('vertical drag update');
                    setState(() {
                      RenderBox renderBox = context.findRenderObject();
                      final local = renderBox.globalToLocal(event.globalPosition);
//                        ;
                      marketCapPositions =
                          (marketCapPositions.where((e) => e.key != val.instrumentKey).toList(growable: true)
                                ..add(MapEntry(
                                    val.instrumentKey,
                                    this.widget.simpleGameSet.marketCapScaleMin +
                                        this.totalRange / context.size.height * local.dy)))
                              .toList();
                    });
                  },
                  child: Card(
                    elevation: draggedInstrument == val.instrumentKey ? 4 : 1,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: CachedNetworkImage(
                        placeholder: CircularProgressIndicator(),
                        errorWidget: Text('Error :( ${val.logo.id}'),
                        width: 100,
                        height: 50,
                        imageUrl: _apiService.getImageUrl(val.logo),
                      ),
                    ),
                  ),
                ));
          }).toList(),
        ));
  }
}

class StockDraggable extends StatefulWidget {
  Widget child;

  StockDraggable({this.child});

  @override
  State<StatefulWidget> createState() {
    return StockDraggableState();
  }
}

class StockDraggableState extends State<StockDraggable> {
  @override
  Widget build(BuildContext context) {
    final gestureRecognizer = ImmediateMultiDragGestureRecognizer(debugOwner: this);
    return Listener(
      child: widget.child,
    );
  }
}
