import 'dart:typed_data';

import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge_invite.dart';
import 'package:anlage_app_game/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/screens/navigation_drawer_profile.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'dart:ui' as ui;
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:image/image.dart' as image;

final _logger = new Logger("app.anlage.game.screens.market_cap_sorting");

class MarketCapSorting extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingState();
  }
}

class MarketCapScalePainter extends CustomPainter {
  static const MARGIN_LEFT = 16.0;
  static const MARGIN_VERTICAL = 8.0;
  static const TEXT_MARGIN_VERTICAL = 8.0;
  static const SCALE_WIDTH = 8.0;

  static const ARROW_LENGTH = 16;
  static const ARROW_WIDTH = 8;
  static const ARROW_ARM_WIDTH = ARROW_WIDTH / 2;

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
    final bottomY = size.height - (2 * MARGIN_VERTICAL);
    var rect = Offset(MARGIN_LEFT, MARGIN_VERTICAL + 4) & Size(SCALE_WIDTH, bottomY - 16);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(SCALE_WIDTH / 2)), Paint()..color = FinalyzerTheme.colorPrimary);
    final paint = Paint();
    paint.color = FinalyzerTheme.colorPrimary;
    paint.strokeWidth = 1;

    canvas.drawPath(
        Path()
          ..addPolygon([
            Offset(MARGIN_LEFT - ARROW_ARM_WIDTH, MARGIN_VERTICAL + ARROW_LENGTH),
            Offset(MARGIN_LEFT + (SCALE_WIDTH / 2), MARGIN_VERTICAL),
            Offset(MARGIN_LEFT + SCALE_WIDTH + ARROW_ARM_WIDTH, MARGIN_VERTICAL + ARROW_LENGTH)
          ], true),
        paint);

    canvas.drawPath(
        Path()
          ..addPolygon([
            Offset(MARGIN_LEFT - ARROW_ARM_WIDTH, bottomY - ARROW_LENGTH),
            Offset(MARGIN_LEFT + (SCALE_WIDTH / 2), bottomY),
            Offset(MARGIN_LEFT + SCALE_WIDTH + ARROW_ARM_WIDTH, bottomY - ARROW_LENGTH)
          ], true),
        paint);

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
  ApiService _api;

  @override
  void initState() {
    super.initState();
//    final gameBloc = MarketCapSortingGameProvider.of(context);
//    gameBloc.fetchGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = DepsProvider.of(context).api;
    if (_api != api) {
      _api = api;
      _gameBloc = MarketCapSortingGameBloc(_api);
      _gameBloc.newGame();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _gameBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);

    return MarketCapSortingGameProvider(
      game: _gameBloc,
      child: StreamBuilder(
          stream: _gameBloc.simpleGameSet,
          builder: (context, snapshot) {
            return Scaffold(
                endDrawer: NavigationDrawerProfile(),
                appBar: AppBar(
                  title: Text('Market Cap Game'),
                  actions: <Widget>[
                    StreamBuilder<LoginState>(
                      builder: (context, snapshot) => IconButton(
                          iconSize: 36,
                          icon: CircleAvatar(
                              maxRadius: 18,
                              backgroundColor: Colors.white,
                              backgroundImage: snapshot.data?.avatarUrl == null
                                  ? null
                                  : CachedNetworkImageProvider(snapshot.data.avatarUrl)),
                          onPressed: () {
                            AnalyticsUtils.instance.analytics.logEvent(name: 'drawer_open_click_avatar');
                            Scaffold.of(context).openEndDrawer();
                          }),
                      stream: _api.loginState,
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  label: Text(isVerifying || snapshot.data == null ? 'Loading …' : 'Check'),
                  icon: isVerifying || snapshot.data == null
                      ? Container(
                          height: 16.0,
                          width: 16.0,
//                padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ))
                      : Icon(Icons.check),
                  onPressed: isVerifying || snapshot.data == null
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
                      ],
                    ),
                  ),
                ),
                body: SafeArea(
//        bottom: false,
                  child: snapshot.hasData
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
//            Text("lorem ipsum"),
                            Expanded(
                                child: MarketCapSortingScaleWidget(_gameBloc, snapshot.data as GameSimpleSetResponse)),
                          ],
                        )
                      : snapshot.hasError
                          ? Container(
                              margin: EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                      "Error occurred while fetching data. Please check your network connection and try again."),
                                  RaisedButton(
                                    child: Text('Retry'),
                                    onPressed: () {
                                      _gameBloc.newGame();
                                    },
                                  ),
                                ],
                              ),
                            )
                          : Center(child: CircularProgressIndicator()),
                ));
          }),
    );
  }

  void _showVerifyResultDialog(GameSimpleSetVerifyResponse response) {
    showDialog(context: context, builder: (context) => MarketCapSortingResultWidget(response, _gameBloc));
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

class MarketCapSortingResultWidget extends StatelessWidget {
  final GameSimpleSetVerifyResponse response;
  final MarketCapSortingGameBloc _gameBloc;
  final GlobalKey drawGlobalKey = GlobalKey();

  MarketCapSortingResultWidget(this.response, this._gameBloc);

  @override
  Widget build(BuildContext context) {
//    final _gameBloc = MarketCapSortingGameProvider.of(context);
    return Container(
        child: AlertDialog(
      content: StreamBuilder<GameSimpleSetResponse>(
        stream: _gameBloc.simpleGameSet,
        builder: (context, snapshot) => snapshot.data == null
            ? Container()
            : SingleChildScrollView(
                child: RepaintBoundary(
                  key: drawGlobalKey,
                  child: _createResultScreen(response, snapshot, _gameBloc, context),
                ),
              ),
      ),
      actions: <Widget>[
        FlatButton.icon(
          icon: Icon(Icons.share),
          label: Text('Share'),
          onPressed: () {
            AnalyticsUtils.instance.analytics.logShare(contentType: 'result_sorting', itemId: 'sort');
            _capturePngWithPicture(context);
          },
        ),
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

  _createResultScreen(GameSimpleSetVerifyResponse response, AsyncSnapshot<GameSimpleSetResponse> snapshot,
      MarketCapSortingGameBloc _gameBloc, BuildContext context) {
    final _api = DepsProvider.of(context).api;

    var score = 0;

    // ok, this is a pretty bad misuse, but i couldn't come up with a better use case right now :-)
    final trace = FirebasePerformance.instance.newTrace('sorting_score');
    trace.start();

    final theme = Theme.of(context);
    // Somehow when we use a transparent font during converting to image the emoticon looks weird.
//    final titleTextStyle = theme.textTheme.title.copyWith(color: Color.alphaBlend(theme.textTheme.title.color, Colors.white));
    final titleTextStyle = theme.textTheme.title;
    _logger.fine('title theme: ${theme.textTheme.title.toString()}');

    final ret = Column(
      children: <Widget>[
            (response.correctCount == 0
                ? Text('😞 None were correctly', style: titleTextStyle.copyWith(color: Colors.orange))
                : response.correctCount == 1
                    ? Text('🤔 Nice try.', style: titleTextStyle)
                    : response.correctCount == 2
                        ? Text('️📈️ Almost!', style: titleTextStyle)
                        : response.correctCount == 4
                            ? Text('🎉️ WOW! All Correct!', style: titleTextStyle.copyWith(color: Colors.green))
                            : Text('?!')),

//        Text('${response.correctCount} correct answers.'),
            Container(
              padding: EdgeInsets.only(bottom: 8, top: 20),
              child: Text('Correct order by market cap:', style: theme.textTheme.caption),
            ),
          ] +
          response.actual
              .toList()
              .asMap()
              .map((resultIdx, resultDto) {
                final info = snapshot.data.simpleGame.firstWhere((dto) => dto.instrumentKey == resultDto.instrumentKey);
                var pos = 0;
                double guessedMarketCap;
                final guesses = _gameBloc.marketCapPositions.toList();
                guesses.sort((a, b) => -1 * a.value.compareTo(b.value));

                for (var value in guesses) {
                  pos++;
                  if (value.key == resultDto.instrumentKey) {
                    guessedMarketCap = value.value;
                    break;
                  }
                }

                final isCorrect = pos == resultIdx + 1;
                if (isCorrect) {
                  trace.incrementCounter('correct');
                  score++;
                } else {
                  trace.incrementCounter('wrong');
                }

                return MapEntry(
                    resultIdx,
                    Container(
                      decoration:
                          resultIdx == 0 ? null : BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                      padding:
                          EdgeInsets.only(top: resultIdx == 0 ? 0.0 : 16.0, bottom: resultIdx == null ? 0.0 : 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Text('${resultIdx + 1}.'),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
                                margin: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  formatMarketCap(resultDto.marketCap),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontFamily: 'RobotoMono'),
                                  textAlign: TextAlign.right,
                                ),
                              ),
//                              Text(
//                                "Your Guess:",
//                                style: Theme.of(context).textTheme.caption.copyWith(fontWeight: FontWeight.bold),
//                                textAlign: TextAlign.right,
//                              ),
                              Text("You ranked it: $pos ${isCorrect ? '👍️' : '👎'}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .body1
                                      .copyWith(color: isCorrect ? Colors.green : Colors.red),
                                  textAlign: TextAlign.right),
//                              Text(
//                                "MarketCap: ${formatMarketCap(guessedMarketCap)}",
//                                style: Theme.of(context).textTheme.caption,
//                                textAlign: TextAlign.right,
//                              ),
                            ]),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            child: isCorrect
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                          )
                        ],
                      ),
                    ));
              })
              .values
              .toList(),
    );

    trace.stop();
    AnalyticsUtils.instance.analytics.logEvent(name: "verify_sort", parameters: {'score': score});

    return ret;
  }

  void _capturePngWithPicture(BuildContext context) async {
    try {
      TextSpan span = new TextSpan(
          style: new TextStyle(color: FinalyzerTheme.colorPrimary, fontSize: 24, fontFamily: 'RobotoMono'),
          text: 'https://anlage.app/game');
      final painter = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      painter.layout();

      RenderRepaintBoundary boundary = drawGlobalKey.currentContext.findRenderObject();
      ui.Image img = await boundary.toImage(pixelRatio: 2.0);

      final padding = 64.0;

      final recorder = ui.PictureRecorder();
      final canvasRect =
          Offset(0, 0) & Size(img.width + 2 * padding, img.height + 2 * padding + padding + painter.height);
      final canvas = ui.Canvas(recorder, canvasRect);

      final p = Paint();
      p.color = Colors.white;
      canvas.drawRect(canvasRect, p);
      canvas.drawImage(img, Offset(padding, padding), Paint());

      painter.paint(canvas, Offset(padding, canvasRect.height - padding - painter.height));
      _logger.fine('painter.height: ${painter.height} --- $painter');

      final picture = recorder.endRecording();

      ui.Image finalImage = picture.toImage(canvasRect.width.toInt(), canvasRect.height.toInt());

      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _logger.severe('byteData is null ?!');
        return;
      }
      _logger.fine('Opening share dialog.');
      await EsysFlutterShare.shareImage('result.png', byteData, 'MarketShare Game - Results');
    } catch (error, stackTrace) {
      _logger.warning('Error during share', error, stackTrace);
      rethrow;
    }
  }

  void _capturePng(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary = drawGlobalKey.currentContext.findRenderObject();
      ui.Image img = await boundary.toImage(pixelRatio: 2.0);
//      await EsysFlutterShare.shareImage('result.png', await img.toByteData(format: ui.ImageByteFormat.png), 'MarketShare Game - Results');

      final newImg = image.Image.fromBytes(img.width, img.height,
          (await img.toByteData(format: ui.ImageByteFormat.rawUnmodified)).buffer.asUint32List());
//      img.dispose();
      final padding = 64;
      final targetImage = image.Image(newImg.width + 2 * padding, newImg.height + 2 * padding + 24 + padding);
      image.fill(targetImage, image.Color.fromRgb(255, 255, 255));
      image.drawImage(targetImage, newImg, dstX: padding, dstY: padding);
      image.drawString(
          targetImage, image.arial_24, padding, targetImage.height - padding - 24, 'https://anlage.app/game',
          color: 0xff000000);
//    ByteData byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final byteData = ByteData.view(Uint8List.fromList(image.encodePng(targetImage)).buffer);
      if (byteData == null) {
        _logger.severe('byteData is null ?!');
        return;
      }
      _logger.fine('Opening share dialog.');
      await EsysFlutterShare.shareImage('result.png', byteData, 'MarketShare Game - Results');
//    Uint8List pngBytes = byteData.buffer.asUint8List();
//    print(pngBytes);
//      Scaffold.of(context)
//    .
    } catch (error, stackTrace) {
      _logger.warning('Error during share', error, stackTrace);
      rethrow;
    }
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
  ApiService _apiService;

  static const STOCK_CARD_WIDTH = 100.0;
  static const STOCK_CARD_HEIGHT = 50.0;
  static const STOCK_CARD_DRAGGED_RATIO = 1.4;

  bool moved = false;
  double totalRange;
  String draggedInstrument;

  @override
  void initState() {
    super.initState();
    final simpleGameSet = widget.simpleGameSet;
    final totalRange = simpleGameSet.marketCapScaleMax - simpleGameSet.marketCapScaleMin;
    this.totalRange = totalRange;
    this.moved = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiService = DepsProvider.of(context).api;
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
          var isDragged = draggedInstrument == val.instrumentKey;

          final arrows = <Widget>[
            Positioned(
              top: -30,
              right: STOCK_CARD_WIDTH / 2 - 12,
              child: AnimatedOpacity(
                  opacity: moved ? 0 : 1,
                  duration: Duration(milliseconds: 500),
                  child: Icon(Icons.arrow_upward, size: 24, color: Colors.black26)),
            ),
            Positioned(
              bottom: -30,
              right: STOCK_CARD_WIDTH / 2 - 12,
              child: AnimatedOpacity(
                opacity: moved ? 0 : 1,
                duration: Duration(milliseconds: 500),
                child: Icon(
                  Icons.arrow_downward,
                  size: 24,
                  color: Colors.black26,
                ),
              ),
            ),
          ];

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
                    moved = true;
                    gameBloc.updateMarketCapPosition(val.instrumentKey,
                        this.widget.simpleGameSet.marketCapScaleMax - this.totalRange / context.size.height * local.dy);
                  });
                },
                child: Stack(
                  alignment: Alignment.centerRight,
                  overflow: Overflow.visible,
                  children: arrows +
                      [
//                      Text('Lorem ipsum'),

                        Container(
                          width: isDragged ? STOCK_CARD_WIDTH * STOCK_CARD_DRAGGED_RATIO : STOCK_CARD_WIDTH,
                          height: isDragged ? STOCK_CARD_HEIGHT * STOCK_CARD_DRAGGED_RATIO : STOCK_CARD_HEIGHT,
                          child: Card(
                            elevation: isDragged ? 8 : 1,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: CachedNetworkImage(
                                placeholder: Center(child: LinearProgressIndicator()),
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
                        buildLine(isDragged ? STOCK_CARD_WIDTH * STOCK_CARD_DRAGGED_RATIO : STOCK_CARD_WIDTH),
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

  Widget buildLine(double stockCardWidth) {
    final dotSize = 12.0;
    return Align(
      alignment: Alignment.centerRight,
      heightFactor: 6.0,
      child: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: MarketCapScalePainter.MARGIN_LEFT, right: stockCardWidth - 4),
            height: 2.0,
//          width: 300,
            color: FinalyzerTheme.colorSecondary, //Color.fromARGB(255, 200, 200, 200),
          ),
          Positioned(
            top: -(dotSize / 2),
            right: stockCardWidth - 4 - (dotSize / 2),
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
