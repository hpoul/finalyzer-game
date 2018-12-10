import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/utils_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
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
    TextSpan span = new TextSpan(
        style: new TextStyle(color: FinalyzerTheme.colorPrimary, fontSize: 12, fontFamily: 'RobotoMono'),
        text: formatMarketCap(marketCap));
    final painter = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    painter.layout();
    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset(MARGIN_LEFT, MARGIN_VERTICAL) & Size(SCALE_WIDTH, size.height - 2 * MARGIN_VERTICAL);
    canvas.drawRect(rect, Paint()..color = FinalyzerTheme.colorPrimary);

    maxTextPainter.paint(canvas, new Offset(MARGIN_LEFT + SCALE_WIDTH + 4, TEXT_MARGIN_VERTICAL));
    minTextPainter.paint(
        canvas, new Offset(MARGIN_LEFT + SCALE_WIDTH + 4, size.height - minTextPainter.height - TEXT_MARGIN_VERTICAL));
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

  OneDimensionalRange(this.begin, this.end) : assert(begin < end);

  bool overlaps(OneDimensionalRange other) => !(this.begin > other.end || this.end < other.begin);
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
        virtualRect = Offset(size.width - (MarketCapSortingScaleState.STOCK_CARD_WIDTH * collisions), localPos) &
            Size(MarketCapSortingScaleState.STOCK_CARD_WIDTH, MarketCapSortingScaleState.STOCK_CARD_HEIGHT);
      } while (positions.where((r) => r.overlaps(virtualRect)).isNotEmpty);
      positions.add(virtualRect);

      final marginRight = MarketCapSortingScaleState.STOCK_CARD_WIDTH * (collisions - 1);

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
  bool isVerifying = false;
  MarketCapSortingGameBloc _gameBloc;

  @override
  void initState() {
    super.initState();
//    final gameBloc = MarketCapSortingGameProvider.of(context);
//    gameBloc.fetchGame();
    _gameBloc = MarketCapSortingGameBloc();
    _gameBloc.newGame();
  }

  @override
  void dispose() {
    super.dispose();
    _gameBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarketCapSortingGameProvider(
      game: _gameBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Market Cap Game by https://Anlage.App'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text(isVerifying ? 'Loading …' : 'Check'),
          icon: isVerifying
              ? Container(
                  height: 16.0,
                  width: 16.0,
//                padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ))
              : Icon(Icons.check),
          onPressed: isVerifying
              ? null
              : () {
                  setState(() {
                    isVerifying = !isVerifying;
                  });
                  _gameBloc.verifyMarketCaps().then((val) {
                    _showVerifyResultDialog(val);
                    setState(() {
                      isVerifying = false;
                    });
                  }).catchError((error, stackTrace) {
                    _logger.severe('Error while verifying market caps.', error, stackTrace);
                    setState(() {
                      isVerifying = false;
                    });
                    _showErrorDialog(error);
                  });
                },
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
                Text(
                  'Sort the companies based on their Market Cap.',
                  style: Theme.of(context).textTheme.body2,
                ),
                Text('Extra points for approximating the right value! (+/-10%)'),
              ],
            ),
          ),
        ),
        body: SafeArea(
//        bottom: false,
            child: StreamBuilder(
          stream: _gameBloc.simpleGameSet,
          builder: (context, snapshot) => snapshot.data == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
//            Text("lorem ipsum"),
                    Expanded(child: MarketCapSortingScaleWidget(_gameBloc, snapshot.data as GameSimpleSetResponse)),
                  ],
                ),
        )),
      ),
    );
  }

  void _showVerifyResultDialog(GameSimpleSetVerifyResponse response) {
    final _api = ApiService.instance;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Correct Market Caps'),
              content: StreamBuilder<GameSimpleSetResponse>(
                stream: _gameBloc.simpleGameSet,
                builder: (context, snapshot) => snapshot.data == null
                    ? Container()
                    : SingleChildScrollView(
                  child: Column(
                        children: response.actual.asMap().map((resultIdx, resultDto) {
                        final info =
                            snapshot.data.simpleGame.firstWhere((dto) => dto.instrumentKey == resultDto.instrumentKey);
                        var pos = 0;
                        double guessedMarketCap;
                        final guesses = _gameBloc.marketCapPositions.toList();
                        guesses.sort((a, b) => a.value.compareTo(b.value));

                        for (var value in guesses) {
                          pos++;
                          if (value.key == resultDto.instrumentKey) {
                            guessedMarketCap = value.value;
                            break;
                          }
                        }

                        return MapEntry(resultIdx, Container(
                          decoration: resultIdx == 0 ? null : BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                          padding: EdgeInsets.only(top: 16.0, bottom: resultIdx == null ? 0.0 : 16.0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Container(
                              alignment: Alignment.centerRight,
                              width: 100,
                              height: 40,
                              child: CachedNetworkImage(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                width: 100,
                                height: 40,
                                imageUrl: _api.getImageUrl(info.logo),
                              ),
                            ),
                            Container(
//                              constraints: BoxConstraints.expand(),
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: Text(formatMarketCap(resultDto.marketCap),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontFamily: 'RobotoMono'), textAlign: TextAlign.right,),
                            ),
                            Text("Your Guess:", style: Theme.of(context).textTheme.caption.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right,),
                            Text("Position: $pos ${pos == resultIdx+1 ? '👍 ️️✅️' : '👎 🤷️'}",style: Theme.of(context).textTheme.caption.copyWith(color: pos == resultIdx + 1 ? Colors.green : Colors.red), textAlign: TextAlign.right),
                            Text("MarketCap: ${formatMarketCap(guessedMarketCap)}",
                              style: Theme.of(context).textTheme.caption, textAlign: TextAlign.right,
                            ),
                          ]),
                        ));
                      }).values.toList()),
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('New Game'),
                  onPressed: () {
                    _gameBloc.newGame();
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }

  void _showErrorDialog(Error error) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('There was an error during the request.\nPlease try again later.\n$error'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }
}

class MarketCapSortingScaleWidget extends StatefulWidget {
  final MarketCapSortingGameBloc gameBloc;
  final GameSimpleSetResponse simpleGameSet;

  MarketCapSortingScaleWidget(this.gameBloc, this.simpleGameSet);

  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingScaleState();
  }
}

class MarketCapSortingScaleState extends State<MarketCapSortingScaleWidget> {
  final ApiService _apiService = ApiService.instance;

  static const STOCK_CARD_WIDTH = 100.0;
  static const STOCK_CARD_HEIGHT = 50.0;

  double totalRange;
  String draggedInstrument;

  @override
  void initState() {
    super.initState();
    final simpleGameSet = widget.simpleGameSet;
    final totalRange = simpleGameSet.marketCapScaleMax - simpleGameSet.marketCapScaleMin;
    this.totalRange = totalRange;
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
    final gameBloc = MarketCapSortingGameProvider.of(context);
    return CustomPaint(
      foregroundPainter:
          MarketCapScalePainter(widget.simpleGameSet.marketCapScaleMin, widget.simpleGameSet.marketCapScaleMax),
      child: CustomMultiChildLayout(
        delegate: MarketPriceLayoutDelegate(gameBloc.marketCapPositions, widget.simpleGameSet),
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
                    gameBloc.updateMarketCapPosition(val.instrumentKey,
                        this.widget.simpleGameSet.marketCapScaleMax - this.totalRange / context.size.height * local.dy);
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
                            placeholder: Center(child: CircularProgressIndicator()),
                            errorWidget: Text('Error :( ${val.logo.id}'),
//                              width: 100,
//                                  height: 50,
                            imageUrl: _apiService.getImageUrl(val.logo),
                          ),
                        ),
                      ),
                    ),
                    buildMarketCapLabel(
                        gameBloc.marketCapPositions.firstWhere((pos) => pos.key == val.instrumentKey).value),
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
    final dotSize = 12.0;
    return Align(
      alignment: Alignment.centerRight,
      heightFactor: 6.0,
      child: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
                left: MarketCapScalePainter.MARGIN_LEFT, right: MarketCapSortingScaleState.STOCK_CARD_WIDTH - 4),
            height: 2.0,
//          width: 300,
            color: FinalyzerTheme.colorSecondary, //Color.fromARGB(255, 200, 200, 200),
          ),
          Positioned(
            top: -(dotSize / 2),
            right: MarketCapSortingScaleState.STOCK_CARD_WIDTH - 4 - (dotSize / 2),
            height: dotSize,
            width: dotSize,
            child: Container(
//              margin: EdgeInsets.,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                  color: FinalyzerTheme.colorSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26 /*FinalyzerTheme.colorSecondary*/, width: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}
