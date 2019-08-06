import 'dart:ui' as ui;

import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge.dart';
import 'package:anlage_app_game/screens/company_details.dart';
import 'package:anlage_app_game/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/screens/navigation_drawer_profile.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/logging.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final Iterable<MapEntry<String, double>> marketCapPositions;
  final double marketCapScaleMin;
  final double marketCapScaleMax;

  MarketPriceLayoutDelegate(this.marketCapPositions, this.marketCapScaleMin, this.marketCapScaleMax);

  @override
  void performLayout(Size size) {
    var range = marketCapScaleMax - marketCapScaleMin;
    var widgetRange = size.height / range;

    var positions = List<Rect>();
    marketCapPositions.forEach((i) {
      var marketCapPos = marketCapScaleMax - i.value;
      var localPos = widgetRange * marketCapPos;
//      final yRange = OneDimensionalRange(localPos, localPos + MarketCapSortingScaleState.STOCK_CARD_HEIGHT);
      int collisions = 0;
      Rect virtualRect;
      do {
        collisions++;
        virtualRect = Offset(size.width - (_STOCK_CARD_WIDTH * collisions), localPos) &
            Size(_STOCK_CARD_WIDTH, _STOCK_CARD_HEIGHT);
      } while (positions.where((r) => r.overlaps(virtualRect)).isNotEmpty);
      positions.add(virtualRect);

      final marginRight = _STOCK_CARD_WIDTH * (collisions - 1);

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
      _gameBloc.nextTurn();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _gameBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _gameBloc.simpleGameSet,
        builder: (context, snapshot) {
          return MarketCapSortingScreen(_gameBloc, snapshot);
        });
  }
}

class MarketCapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ApiService api;
  final ui.Size preferredSize = const Size.fromHeight(kToolbarHeight);

  const MarketCapAppBar({Key key, this.api}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Market Cap Game'),
      actions: <Widget>[
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

class MarketCapSortingScreen extends StatefulWidget {
  final MarketCapSortingGameBloc gameBloc;
  final AsyncSnapshot<GameSimpleSetResponse> snapshot;

  MarketCapSortingScreen(this.gameBloc, this.snapshot);

  @override
  _MarketCapSortingScreenState createState() => _MarketCapSortingScreenState();
}

class _MarketCapSortingScreenState extends State<MarketCapSortingScreen> {
  bool isVerifying = false;

  @override
  Widget build(BuildContext context) {
    final _gameBloc = widget.gameBloc;
    final snapshot = widget.snapshot;
    final _api = _gameBloc.api;
    return Scaffold(
        endDrawer: NavigationDrawerProfile(),
        appBar: MarketCapAppBar(
          api: _api,
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text(isVerifying || snapshot.data == null ? 'Loading …' : 'Check'),
          icon: isVerifying || snapshot.data == null
              ? Container(
                  height: 16.0,
                  width: 16.0,
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
                    _showVerifyResultDialog(val, snapshot.data);
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                    Text(
                      widget.gameBloc.maxTurns == null
                          ? 'Sort the companies based on their Market Cap.'
                          : 'Sort the companies based on their Market Cap.',
                      style: Theme.of(context).textTheme.body2,
                    ),
                  ] +
                  (widget.gameBloc.maxTurns == null
                      ? []
                      : [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Turn ${widget.gameBloc.currentTurn + 1} of ${widget.gameBloc.maxTurns}',
                              style: Theme.of(context).textTheme.caption,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          LinearProgressIndicator(value: (widget.gameBloc.currentTurn + 1) / widget.gameBloc.maxTurns),
                        ]),
            ),
          ),
        ),
        body: SafeArea(
          child: snapshot.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: MarketCapSortingScaleWidget(_gameBloc, snapshot.data)),
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
                              _gameBloc.nextTurn();
                            },
                          ),
                        ],
                      ),
                    )
                  : Center(child: CircularProgressIndicator()),
        ));
  }

  void _showVerifyResultDialog(GameSimpleSetVerifyResponse response, GameSimpleSetResponse gameSet) {
    showDialog(
        context: context, builder: (context) => MarketCapSortingResultWidget(response, widget.gameBloc, gameSet));
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
  final GameSimpleSetResponse _gameSet;
  final GlobalKey drawGlobalKey = GlobalKey();

  MarketCapSortingResultWidget(this.response, this._gameBloc, this._gameSet);

  @override
  Widget build(BuildContext context) {
    final challengeBloc =
        _gameBloc is MarketCapSortingChallengeBloc ? _gameBloc as MarketCapSortingChallengeBloc : null;
//    final _gameBloc = MarketCapSortingGameProvider.of(context);
    final deps = DepsProvider.of(context);
    return Container(
      child: AlertDialog(
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        content: SingleChildScrollView(
          child: RepaintBoundary(
            key: drawGlobalKey,
            child: _createResultScreen(response, _gameSet, _gameBloc, context),
          ),
        ),
        actions: <Widget>[
          FlatButton.icon(
            icon: Icon(Icons.share),
            label: Text('Share'),
            onPressed: () {
              AnalyticsUtils.instance.analytics
                  .logShare(contentType: 'result_sorting', itemId: 'sort', method: 'share');
              _capturePngWithPicture(context);
            },
          ),
          FlatButton(
            child:
                Text(challengeBloc == null ? 'New Game' : challengeBloc.isCompleted ? 'Finish Challenge' : 'Next Turn'),
            onPressed: () {
              if (challengeBloc?.isCompleted ?? false) {
                Navigator.of(context)
                  ..pop()
                  ..pushReplacement(
                    AnalyticsPageRoute(
                        name: '/challenge/details',
                        builder: (context) => ChallengeDetails(challengeBloc.challenge.challengeId)),
                  );
              } else {
                Navigator.of(context).pop();
                _gameBloc.nextTurn();

                if ((deps.api.currentLoginState?.userInfo?.statsTotalTurns ?? -1) > 2) {
                  deps.cloudMessaging.requiresAskPermission().then((askPermission) {
                    if (askPermission) {
//                    showDialog(context: context, builder: (context) => AskForMessagingPermission());
                      deps.cloudMessaging.requestPermission();
                    }
                  }).catchError(LoggingUtil.futureCatchErrorLog("require permission?"));
                }
              }
            },
          )
        ],
      ),
    );
  }

  _createResultScreen(GameSimpleSetVerifyResponse response, GameSimpleSetResponse gameSet,
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
                ? Text('😞 None were correct', style: titleTextStyle.copyWith(color: Colors.orange))
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
                final info = gameSet.simpleGame.firstWhere((dto) => dto.instrumentKey == resultDto.instrumentKey);
                var pos = 0;
                final guesses = _gameBloc.marketCapPositions.toList();
                guesses.sort((a, b) => -1 * a.value.compareTo(b.value));

                for (var value in guesses) {
                  pos++;
                  if (value.key == resultDto.instrumentKey) {
                    break;
                  }
                }

                final isCorrect = pos == resultIdx + 1;
                if (isCorrect) {
                  trace.incrementMetric('correct', 1);
                  score++;
                } else {
                  trace.incrementMetric('wrong', 1);
                }

                return MapEntry(
                    resultIdx,
                    InkWell(
                      onTap: () {
                        final details =
                            response.details.firstWhere((details) => resultDto.instrumentKey == details.instrumentKey);
                        Navigator.of(context).push(AnalyticsPageRoute(
                          name: '/company/details',
                          builder: (context) => CompanyDetailsScreen(details, info.logo),
                        ));
                      },
                      child: Container(
                        decoration: resultIdx == 0
                            ? null
                            : BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                        padding: EdgeInsets.only(
                          top: resultIdx == 0 ? 0.0 : 16.0,
                          bottom: resultIdx == null ? 0.0 : 16.0,
                          left: 16,
                          right: 8,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${resultIdx + 1}.',
                                            style: Theme.of(context).textTheme.headline,
                                          )),
                                    ),
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(
                                    alignment: Alignment.centerRight,
                                    width: 100,
                                    height: 40,
                                    child: CachedNetworkImage(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      placeholder: (context, url) => Center(child: LinearProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Center(child: Text(info.symbol ?? 'Error ${info.logo.id}')),
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
                        ),
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

      ui.Image finalImage = await picture.toImage(canvasRect.width.toInt(), canvasRect.height.toInt());

      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _logger.severe('byteData is null ?!');
        return;
      }
      _logger.fine('Opening share dialog.');
      await Share.file('MarketCap Game - Results', 'result.png', byteData.buffer.asUint8List(), 'image/png');
//      await EsysFlutterShare.shareImage('result.png', byteData, 'MarketShare Game - Results');
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
  bool moved = false;
  String draggedInstrument;

  @override
  void initState() {
    super.initState();
    _logger.finer('MarketCapSortingScaleState.init');
    _precalculateRange();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.finer('MarketCapSortingScaleState.didChangeDependencies');
  }

  void _precalculateRange() {
    this.moved = false;
  }

  @override
  void didUpdateWidget(covariant MarketCapSortingScaleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.finer('MarketCapSortingScaleState.didUpdateWidget');
    _precalculateRange();
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
    final gameBloc = widget.gameBloc;
    final simpleGameSet = widget.simpleGameSet;
    return MarketCapPositionScale(
      moved: moved,
      instruments: instruments,
      marketCapScaleMin: simpleGameSet.marketCapScaleMin,
      marketCapScaleMax: simpleGameSet.marketCapScaleMax,
      marketCapPositions: Map.fromEntries(gameBloc.marketCapPositions),
      draggedInstrument: draggedInstrument,
      changedDraggedInstrument: (instrumentKey) {
        setState(() {
          draggedInstrument = instrumentKey;
        });
      },
      draggedInstrumentToMarketCap: (instrumentKey, marketCap) {
        setState(() {
          moved = true;
          gameBloc.updateMarketCapPosition(instrumentKey, marketCap);
        });
      },
    );
  }

  // some inspiration from https://github.com/MarcinusX/flutter_ui_challenge_flight_search/blob/v0.5/lib/price_tab/flight_stop_card.dart
  double get maxWidth {
    RenderBox renderBox = context.findRenderObject();
    BoxConstraints constraints = renderBox?.constraints;
    double maxWidth = constraints?.maxWidth ?? 0.0;
    return maxWidth;
  }
}

class MarketCapPositionScale extends StatelessWidget {
  const MarketCapPositionScale({
    Key key,
    @required this.moved,
    @required this.instruments,
    @required this.marketCapScaleMin,
    @required this.marketCapScaleMax,
    @required this.marketCapPositions,
    @required this.draggedInstrument,
    @required this.changedDraggedInstrument,
    @required this.draggedInstrumentToMarketCap,
  }) : super(key: key);

  final bool moved;
  final String draggedInstrument;
  final List<SimpleGameDto> instruments;
  final Map<String, double> marketCapPositions;
  final double marketCapScaleMin;
  final double marketCapScaleMax;
  final void Function(String instrumentKey) changedDraggedInstrument;
  final void Function(String instrumentKey, double newMarketValue) draggedInstrumentToMarketCap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: MarketCapScalePainter(marketCapScaleMin, marketCapScaleMax),
      child: CustomMultiChildLayout(
        delegate: MarketPriceLayoutDelegate(marketCapPositions.entries, marketCapScaleMin, marketCapScaleMax),
        children: instruments.map((val) {
          var isDragged = draggedInstrument == val.instrumentKey;

          return LayoutId(
              id: val.instrumentKey,
              child: GestureDetector(
                onVerticalDragStart: (event) {
                  _logger.fine('started vertical dragging.');
                  changedDraggedInstrument(val.instrumentKey);
                },
                onVerticalDragDown: (event) {
                  _logger.fine('vertical drag down');
                },
                onVerticalDragCancel: () {
                  _logger.fine('vertical drag cancel.');
                  changedDraggedInstrument(null);
                },
                onVerticalDragEnd: (event) {
                  _logger.fine('vertical drag end.');
                  changedDraggedInstrument(null);
                },
                onVerticalDragUpdate: (event) {
                  RenderBox renderBox = context.findRenderObject();
                  final local = renderBox.globalToLocal(event.globalPosition);
                  final totalRange = marketCapScaleMax - marketCapScaleMin;
                  draggedInstrumentToMarketCap(
                      val.instrumentKey, marketCapScaleMax - totalRange / context.size.height * local.dy);
                },
                child: MarketCapInstrumentCard(
                  instrument: val,
                  marketCapValue: marketCapPositions[val.instrumentKey],
                  moved: moved,
                  isDragged: isDragged,
                ),
              ));
        }).toList(),
      ),
    );
  }
}

class MarketCapAnimationTween extends StatefulWidget {
  const MarketCapAnimationTween({Key key, @required this.startMarketCap, this.endMarketCap, @required this.builder})
      : assert(startMarketCap != null),
        assert(builder != null),
        super(key: key);

  final Map<String, double> startMarketCap;
  final Map<String, double> endMarketCap;
  final Widget Function(BuildContext context, Map<String, double> marketCap) builder;

  @override
  _MarketCapAnimationTweenState createState() => _MarketCapAnimationTweenState();
}

class _MarketCapAnimationTweenState extends State<MarketCapAnimationTween> with SingleTickerProviderStateMixin {
  Map<String, Tween<double>> _tweenMarketCap;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.endMarketCap != null) {
      _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
      _tweenMarketCap = Map.fromEntries(widget.startMarketCap.keys
          .map((key) => MapEntry(key, Tween(begin: widget.startMarketCap[key], end: widget.endMarketCap[key]))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _tweenMarketCap == null) {
      return widget.builder(context, widget.startMarketCap);
    }
    final marketCaps = _tweenMarketCap.map((entry, tween) => MapEntry(entry, tween.evaluate(_controller)));
    return widget.builder(context, marketCaps);
  }
}

const _STOCK_CARD_WIDTH = 100.0;
const _STOCK_CARD_HEIGHT = 50.0;
const _STOCK_CARD_DRAGGED_RATIO = 1.4;

class MarketCapInstrumentCard extends StatelessWidget {
  const MarketCapInstrumentCard({
    Key key,
    @required this.instrument,
    @required this.marketCapValue,
    @required this.moved,
    @required this.isDragged,
  }) : super(key: key);

  final SimpleGameDto instrument;
  final double marketCapValue;
  final bool moved;
  final bool isDragged;

  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);
    final _apiService = deps.api;
    final arrows = <Widget>[
      Positioned(
        top: -30,
        right: _STOCK_CARD_WIDTH / 2 - 12,
        child: AnimatedOpacity(
            opacity: moved ? 0 : 1,
            duration: Duration(milliseconds: 500),
            child: Icon(Icons.arrow_upward, size: 24, color: Colors.black26)),
      ),
      Positioned(
        bottom: -30,
        right: _STOCK_CARD_WIDTH / 2 - 12,
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
    return Stack(
      alignment: Alignment.centerRight,
      overflow: Overflow.visible,
      children: arrows +
          [
//                      Text('Lorem ipsum'),

            Container(
              width: isDragged ? _STOCK_CARD_WIDTH * _STOCK_CARD_DRAGGED_RATIO : _STOCK_CARD_WIDTH,
              height: isDragged ? _STOCK_CARD_HEIGHT * _STOCK_CARD_DRAGGED_RATIO : _STOCK_CARD_HEIGHT,
              child: Card(
                elevation: isDragged ? 8 : 1,
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: CachedNetworkImage(
                    placeholder: (context, url) => Center(child: LinearProgressIndicator()),
                    errorWidget: (context, url, error) => Center(
                        child: Text(
                      instrument.symbol ?? 'Error ${instrument.logo.id}',
                      style: Theme.of(context).textTheme.body2,
                    )),
//                              width: 100,
//                                  height: 50,
                    imageUrl: _apiService.getImageUrl(instrument.logo),
                  ),
                ),
              ),
            ),
            buildMarketCapLabel(context, marketCapValue),
            buildLine(isDragged ? _STOCK_CARD_WIDTH * _STOCK_CARD_DRAGGED_RATIO : _STOCK_CARD_WIDTH),
          ],
    );
  }

  Widget buildMarketCapLabel(BuildContext context, double marketCap) {
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
