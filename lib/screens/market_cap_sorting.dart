import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' as intl;

final _logger = new Logger("app.anlage.game.screens.market_cap_sorting");

class MarketCapSorting extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingState();
  }
}

class MarketCapScalePainter extends CustomPainter {
  static const MARGIN_LEFT = 16.0;
  static const MARGIN_VERTICAL = 0.0;
  static const TEXT_MARGIN_VERTICAL = 8.0;
  static const SCALE_WIDTH = 8.0;

  double marketCapScaleMin;
  double marketCapScaleMax;

  TextPainter minTextPainter;
  TextPainter maxTextPainter;

  MarketCapScalePainter(this.marketCapScaleMin, this.marketCapScaleMax) {
    this.minTextPainter = _createMarketCapPainter(marketCapScaleMin);
    this.maxTextPainter = _createMarketCapPainter(marketCapScaleMax);
  }

  TextPainter _createMarketCapPainter(double marketCap) {
    TextSpan span = new TextSpan(style: new TextStyle(color: FinalyzerTheme.colorPrimary, fontSize: 12, fontFamily: 'RobotoMono'), text: MarketCapSortingScaleState.formatMarketCap(marketCap));
    final painter = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    painter.layout();
    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {


    var rect = Offset(MARGIN_LEFT, MARGIN_VERTICAL) & Size(SCALE_WIDTH, size.height - 2 * MARGIN_VERTICAL);
    canvas.drawRect(rect, Paint()..color = FinalyzerTheme.colorPrimary);

    maxTextPainter.paint(canvas, new Offset(MARGIN_LEFT + SCALE_WIDTH + 4, TEXT_MARGIN_VERTICAL));
    minTextPainter.paint(canvas, new Offset(MARGIN_LEFT + SCALE_WIDTH + 4, size.height - minTextPainter.height - TEXT_MARGIN_VERTICAL));
//    minTextPainter.paint(canvas, new Offset(MARGIN_LEFT + SCALE_WIDTH + 4, 600));
//    canvas.draw
  }

  @override
  bool shouldRepaint(MarketCapScalePainter oldDelegate) {
    return false;
  }
}

class OneDimensionalRange {
  final double begin;
  final double end;
  OneDimensionalRange(this.begin, this.end) :
    assert(begin < end);

  bool overlaps(OneDimensionalRange other) =>
      !(this.begin > other.end || this.end < other.begin);
//      (this.begin <= other.begin && this.end >= other.begin) ||
//          (this.begin >= other.begin && this.end <= other.end) ||
//          (this.begin <= other.begin && this.begin >= other.begin);
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
      var marketCapPos = this.simpleGameSet.marketCapScaleMax - i.value;
      var localPos = widgetRange * marketCapPos;
//      final yRange = OneDimensionalRange(localPos, localPos + MarketCapSortingScaleState.STOCK_CARD_HEIGHT);
      int collisions = 0;
      Rect virtualRect;
      do {
        collisions++;
        virtualRect = Offset(size.width - (MarketCapSortingScaleState.STOCK_CARD_WIDTH * collisions), localPos) & Size(MarketCapSortingScaleState.STOCK_CARD_WIDTH, MarketCapSortingScaleState.STOCK_CARD_HEIGHT);
      } while (positions.where((r) => r.overlaps(virtualRect)).isNotEmpty);
      positions.add(virtualRect);

      final marginRight = MarketCapSortingScaleState.STOCK_CARD_WIDTH * (collisions-1);

      var s = layoutChild(i.key, BoxConstraints.loose(Size(size.width - marginRight, size.height)));

      var origin;

      origin = Offset(size.width - s.width - marginRight, localPos - s.height / 2);

      positionChild(i.key, origin);

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
      floatingActionButton: FloatingActionButton.extended(
          label: Text('Verify'),
          icon: Icon(Icons.check),
          onPressed: () { },
          isExtended: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//      persistentFooterButtons: <Widget>[
//            RaisedButton(
//                child: Text('Verify'),
//                onPressed: () { })
//          ],
//    bottomNavigationBar: Container(
//      margin: EdgeInsets.all(16.0),
//      child: Row(
//        children: <Widget>[
//          Text('Bottom sheet.'),
//        ],
//      ),
//    ),
      bottomNavigationBar: Card(
        elevation: 16.0,
        margin: EdgeInsets.only(top: 0.0),
        child: Container(
          margin: EdgeInsets.all(16.0).copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
          padding: EdgeInsets.only(top: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Sort the companies based on their Market Cap.', style: Theme.of(context).textTheme.body2,),
              Text('Extra points for approximating the right value! (+/-10%)'),
            ],
          ),
        ),
      ),
      body: SafeArea(
//        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
//            Text("lorem ipsum"),
            Expanded(
                child: simpleGameSet == null ? CircularProgressIndicator() : MarketCapSortingScaleWidget(simpleGameSet)),
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

  static const STOCK_CARD_WIDTH = 100.0;
  static const STOCK_CARD_HEIGHT = 50.0;
  static final _marketCapFormat = intl.NumberFormat.simpleCurrency(name: 'USD', decimalDigits: 0);

  double totalRange;
  String draggedInstrument;

  static String formatMarketCap(double marketCap) =>
    '${_marketCapFormat.format(marketCap/(1000000.0))}M';

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

  int _calculatePriority(SimpleGameDto dto) {
    if (dto.instrumentKey == draggedInstrument) {
      return 1000;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final instruments = widget.simpleGameSet.simpleGame.toList();
    instruments.sort((a, b) => _calculatePriority(a) - _calculatePriority(b));
    return CustomPaint(
            foregroundPainter: MarketCapScalePainter(widget.simpleGameSet.marketCapScaleMin, widget.simpleGameSet.marketCapScaleMax),
            child: CustomMultiChildLayout(
              delegate: MarketPriceLayoutDelegate(marketCapPositions, widget.simpleGameSet),
              children: instruments.map((val) {
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
                                        this.widget.simpleGameSet.marketCapScaleMax -
                                            this.totalRange / context.size.height * local.dy)))
                                  .toList();
                        });
                      },
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
//                      Text('Lorem ipsum'),
                          Container(
                            width: STOCK_CARD_WIDTH,
                            height: STOCK_CARD_HEIGHT,
                            child: Card(
                              elevation: draggedInstrument == val.instrumentKey ? 4 : 1,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: CachedNetworkImage(
                                  placeholder: CircularProgressIndicator(),
                                  errorWidget: Text('Error :( ${val.logo.id}'),
//                              width: 100,
//                                  height: 50,
                                  imageUrl: _apiService.getImageUrl(val.logo),
                                ),
                              ),
                            ),
                          ),
                          buildMarketCapLabel(marketCapPositions.firstWhere((pos) => pos.key == val.instrumentKey).value),
                          buildLine(),
                        ],
                      ),
                    ));
              }).toList(),
            ),
        );
  }

  // some inspiration from https://github.com/MarcinusX/flutter_ui_challenge_flight_search/blob/v0.5/lib/price_tab/flight_stop_card.dart
  double get maxWidth {
    RenderBox renderBox = context.findRenderObject();
    BoxConstraints constraints = renderBox?.constraints;
    double maxWidth = constraints?.maxWidth ?? 0.0;
    return maxWidth;
  }

  Widget buildMarketCapLabel(double marketCap) {
    return Container(
      margin: EdgeInsets.only(left: MarketCapScalePainter.MARGIN_LEFT + MarketCapScalePainter.SCALE_WIDTH + 4.0),
      child: Align(
          alignment: Alignment.topLeft,
          heightFactor: 2.0,
          child: Text(
            formatMarketCap(marketCap),
            style: Theme.of(context).textTheme.caption.copyWith(fontFamily: 'RobotoMono'),
          )),
    );
  }

  Widget buildLine() {
    return Align(
      alignment: Alignment.centerLeft,
      heightFactor: 1.0,
      child: Container(
        margin: EdgeInsets.only(left: MarketCapScalePainter.MARGIN_LEFT, right: MarketCapSortingScaleState.STOCK_CARD_WIDTH-4),
        height: 2.0,
//          width: 300,
        color: FinalyzerTheme.colorSecondary, //Color.fromARGB(255, 200, 200, 200),
      ),
    );
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
