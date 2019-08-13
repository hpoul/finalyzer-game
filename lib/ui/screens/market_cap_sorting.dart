import 'dart:ui' as ui;

import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/ui/screens/challenge/challenge.dart';
import 'package:anlage_app_game/ui/screens/company_details.dart';
import 'package:anlage_app_game/ui/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/ui/screens/market_cap_sorting_result.dart';
import 'package:anlage_app_game/ui/screens/navigation_drawer_profile.dart';
import 'package:anlage_app_game/ui/widgets/app_bar.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.ui.screens.market_cap_sorting');

class MarketCapSorting extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingState();
  }
}

class MarketCapScalePainter extends CustomPainter {
  MarketCapScalePainter(this.marketCapScaleMin, this.marketCapScaleMax)
      : assert(marketCapScaleMin != null),
        assert(marketCapScaleMax != null) {
    minTextPainter = _createMarketCapPainter(marketCapScaleMin);
    maxTextPainter = _createMarketCapPainter(marketCapScaleMax);
  }

  static const MARGIN_LEFT = 16.0;
  static const MARGIN_VERTICAL = 8.0;
  static const TEXT_MARGIN_VERTICAL = 8.0;
  static const SCALE_WIDTH = 8.0;

  static const ARROW_LENGTH = 16;
  static const ARROW_WIDTH = 8;
  static const ARROW_ARM_WIDTH = ARROW_WIDTH / 2;

  final double marketCapScaleMin;
  final double marketCapScaleMax;

  TextPainter minTextPainter;
  TextPainter maxTextPainter;

  TextPainter _createMarketCapPainter(double marketCap) {
    final TextSpan span = TextSpan(
        style: TextStyle(color: FinalyzerTheme.colorPrimary, fontSize: 12, fontFamily: 'RobotoMono'),
        text: formatMarketCap(marketCap));
    final painter = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    painter.layout();
    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bottomY = size.height - (2 * MARGIN_VERTICAL);
    final rect = const Offset(MARGIN_LEFT, MARGIN_VERTICAL + 4) & Size(SCALE_WIDTH, bottomY - 16);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(SCALE_WIDTH / 2)),
        Paint()..color = FinalyzerTheme.colorPrimary);
    final paint = Paint();
    paint.color = FinalyzerTheme.colorPrimary;
    paint.strokeWidth = 1;

    canvas.drawPath(
        Path()
          ..addPolygon(const [
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

    maxTextPainter.paint(canvas, const Offset(MARGIN_LEFT + SCALE_WIDTH + 4, TEXT_MARGIN_VERTICAL));
    minTextPainter.paint(
        canvas, Offset(MARGIN_LEFT + SCALE_WIDTH + 4, size.height - minTextPainter.height - TEXT_MARGIN_VERTICAL));
//    minTextPainter.paint(canvas, new Offset(MARGIN_LEFT + SCALE_WIDTH + 4, 600));
//    canvas.draw
  }

  @override
  bool shouldRepaint(MarketCapScalePainter oldDelegate) {
    return false;
  }
}

class OneDimensionalRange {
  OneDimensionalRange(this.begin, this.end) : assert(begin < end);

  final double begin;
  final double end;

  bool overlaps(OneDimensionalRange other) => !(begin > other.end || end < other.begin);
}

class MarketPriceLayoutDelegate extends MultiChildLayoutDelegate {
  MarketPriceLayoutDelegate(this.marketCapPositions, this.marketCapScaleMin, this.marketCapScaleMax);

  final Iterable<MapEntry<String, double>> marketCapPositions;
  final double marketCapScaleMin;
  final double marketCapScaleMax;

  @override
  void performLayout(Size size) {
    final range = marketCapScaleMax - marketCapScaleMin;
    final widgetRange = (size.height - 2 * MarketCapScalePainter.MARGIN_VERTICAL) / range;

    final positions = <Rect>[];
    for (final i in marketCapPositions) {
      final marketCapPos = marketCapScaleMax - i.value;
      final localPos = widgetRange * marketCapPos + MarketCapScalePainter.MARGIN_VERTICAL;
//      final yRange = OneDimensionalRange(localPos, localPos + MarketCapSortingScaleState.STOCK_CARD_HEIGHT);
      int collisions = 0;
      Rect virtualRect;
      do {
        collisions++;
        virtualRect = Offset(size.width - (_STOCK_CARD_WIDTH * collisions), localPos) &
            const Size(_STOCK_CARD_WIDTH, _STOCK_CARD_HEIGHT);
      } while (positions.where((r) => r.overlaps(virtualRect)).isNotEmpty);
      positions.add(virtualRect);

      final marginRight = _STOCK_CARD_WIDTH * (collisions - 1);

      final s = layoutChild(i.key, BoxConstraints.loose(Size(size.width - marginRight, size.height)));

      positionChild(i.key, Offset(size.width - s.width - marginRight, localPos - s.height / 2));
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class MarketCapSortingState extends State<MarketCapSorting> {
  MarketCapSortingGameBloc _gameBloc;
  ApiService _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = Deps.of(context);
    final api = deps.api;
    if (_api != api) {
      _api = api;
      _gameBloc = MarketCapSortingGameBloc(_api, companyInfoStore: deps.companyInfoStore);
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
    return StreamBuilder<GameSimpleSetResponse>(
        stream: _gameBloc.simpleGameSet,
        builder: (context, snapshot) {
          return MarketCapSortingScreen(_gameBloc, snapshot);
        });
  }
}

class MarketCapSortingScreen extends StatefulWidget {
  const MarketCapSortingScreen(this.gameBloc, this.snapshot);

  final MarketCapSortingGameBloc gameBloc;
  final AsyncSnapshot<GameSimpleSetResponse> snapshot;

  @override
  _MarketCapSortingScreenState createState() => _MarketCapSortingScreenState();
}

class _MarketCapSortingScreenState extends State<MarketCapSortingScreen> with SingleTickerProviderStateMixin {
  bool isVerifying = false;
  GameSimpleSetVerifyResponseWrapper verification;
  AnimationController _verificationAnimation;

  @override
  void dispose() {
    _verificationAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _gameBloc = widget.gameBloc;
    final snapshot = widget.snapshot;
    final _api = _gameBloc.api;
    final challengeBloc = _gameBloc is MarketCapSortingChallengeBloc ? _gameBloc : null;
    return Scaffold(
        endDrawer: NavigationDrawerProfile(),
        appBar: MarketCapAppBar(
          api: _api,
        ),
        floatingActionButton: isVerifying
            ? FloatingActionButton.extended(
                label: const Text('Checking …'),
                icon: FabProgressCircle(),
                onPressed: null,
              )
            : !snapshot.hasData
                ? FloatingActionButton.extended(
                    label: const Text('Loading …'),
                    icon: FabProgressCircle(),
                    onPressed: null,
                  )
                : verification != null
                    ? FloatingActionButton.extended(
                        label: (challengeBloc == null
                            ? const Text('New Game')
                            : challengeBloc.isCompleted ? const Text('Finish') : const Text('Next Turn')),
                        icon: Icon(Icons.navigate_next),
                        onPressed: () async {
                          if (challengeBloc?.isCompleted ?? false) {
                            await Navigator.of(context).pushReplacement<dynamic, dynamic>(
                              AnalyticsPageRoute<dynamic>(
                                  name: '/challenge/details',
                                  builder: (context) => ChallengeDetails(challengeBloc.challenge.challengeId)),
                            );
                          } else {
                            _gameBloc.nextTurn();
                            setState(() {
                              verification = null;
                            });
                            DialogUtil.askForPermissionsIfRequired(Deps.of(context));
                          }
                        },
                      )
                    : FloatingActionButton.extended(
                        label: const Text('Check'),
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          setState(() {
                            isVerifying = true;
                          });
                          _gameBloc.verifyMarketCaps().then((val) {
                            DepsProvider.of(context)
                                .analytics
                                .events
                                .trackTurnVerify(gameType: GameType.sorting, score: val.response.correctCount);
//                    _showVerifyResultDialog(val, snapshot.data);
                            setState(() {
//                          isVerifying = false;
                              _verificationAnimation ??=
                                  AnimationController(duration: const Duration(seconds: 8), vsync: this);
                              _verificationAnimation.forward(from: 0).then<void>((dynamic val) {
                                setState(() {
                                  isVerifying = false;
                                });
                              });
                              verification = val;
                            });
                          }).catchError((dynamic error, StackTrace stackTrace) {
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
          margin: const EdgeInsets.only(top: 0.0),
          child: Container(
            margin: const EdgeInsets.all(16.0).copyWith(bottom: 16.0 + MediaQuery.of(context).padding.bottom),
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...(verification == null || isVerifying
                    ? const [Text('Sort the companies based on their Market Cap.')]
                    : [
                        Text(
                          'You got ${verification.response.correctCount} of ${verification.response.actual.length} correct!',
                          style: Theme.of(context).textTheme.body2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Hint: Tap on Company Logo for more information!',
                          style: Theme.of(context).textTheme.body2.apply(fontSizeFactor: 0.8, color: Colors.black38),
                        ),
                      ]),
                ...(widget.gameBloc.maxTurns == null
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
                      ])
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: snapshot.hasData
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: MarketCapSortingScaleWidget(
                    _gameBloc,
                    snapshot.data,
                    verification: verification,
                    verificationAnimation: _verificationAnimation,
                  ),
                )
              : snapshot.hasError
                  ? Container(
                      margin: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                              'Error occurred while fetching data. Please check your network connection and try again.'),
                          RaisedButton(
                            child: const Text('Retry'),
                            onPressed: () {
                              _gameBloc.nextTurn();
                            },
                          ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
        ));
  }

  @Deprecated('old result screen')
  // ignore: unused_element
  void _showVerifyResultDialog(GameSimpleSetVerifyResponse response, GameSimpleSetResponse gameSet) {
    showDialog<dynamic>(
        context: context, builder: (context) => MarketCapSortingResultWidget(response, widget.gameBloc, gameSet));
  }

  void _showErrorDialog(dynamic error) {
    showDialog<dynamic>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('There was an error during the request.\nPlease try again later.\n$error'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }
}

class FabProgressCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 16.0,
        width: 16.0,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      );
}

class MarketCapSortingScaleWidget extends StatefulWidget {
  const MarketCapSortingScaleWidget(this.gameBloc, this.simpleGameSet, {this.verification, this.verificationAnimation});

  final MarketCapSortingGameBloc gameBloc;
  final GameSimpleSetResponse simpleGameSet;
  final GameSimpleSetVerifyResponseWrapper verification;
  final Animation<double> verificationAnimation;

  @override
  State<StatefulWidget> createState() {
    return MarketCapSortingScaleState();
  }
}

class MarketCapSortingScaleState extends State<MarketCapSortingScaleWidget> with TickerProviderStateMixin {
  bool moved = false;
  String draggedInstrument;
  bool _captureImage = false;
  Animation<double> _forceHideResultOverlay;
  final GlobalKey repaintBoundary = GlobalKey();

  @override
  void initState() {
    super.initState();
    _logger.finer('MarketCapSortingScaleState.init');
    moved = false;
    _forceHideResultOverlay = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.finer('MarketCapSortingScaleState.didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant MarketCapSortingScaleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.finer('MarketCapSortingScaleState.didUpdateWidget');
    if (oldWidget.simpleGameSet != widget.simpleGameSet) {
      moved = false;
    }
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
    final finishAnimation = widget.verificationAnimation?.drive(_slotAnimation(9, 10));
    return RepaintBoundary(
      key: repaintBoundary,
      child: CustomPaint(
        foregroundPainter: MarketCapScalePainter(simpleGameSet.marketCapScaleMin, simpleGameSet.marketCapScaleMax),
        child: Stack(
          children: <Widget>[
            AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: widget.verification == null ? 1 : 0.2,
              child: MarketCapPositionScale(
                moved: moved,
                instruments: instruments
                    .map(
                      (instrument) => MarketCapPositionScaleChild(
                        instrumentKey: instrument.instrumentKey,
                        builder: (context, marketCapValue, isDragged) => MarketCapInstrumentCard(
                          instrument: instrument,
                          marketCapValue: marketCapValue,
                          moved: moved,
                          isDragged: isDragged,
                          lineColor: widget.verification == null ? FinalyzerTheme.colorPrimary : Colors.grey,
                          disabled: widget.verification != null,
                        ),
                      ),
                    )
                    .toList(growable: false),
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
              ),
            ),
            ...(widget.verification == null
                ? []
                : [
                    MarketCapAnimationTween(
                      animation: _slotAnimation(1, 10, slotSpan: 9.0).animate(widget.verificationAnimation),
                      startMarketCap: Map.fromEntries(gameBloc.marketCapPositions),
                      endMarketCap: widget.verification?.response?.actual
                          ?.map((guessDto) => MapEntry(guessDto.instrumentKey, guessDto.marketCap)),
                      builder: (context, marketCapPositions) => MarketCapPositionScale(
                        moved: true,
                        instruments: instruments
                            .map(
                              (instrument) => MarketCapPositionScaleChild(
                                instrumentKey: instrument.instrumentKey,
                                builder: (context, marketCapValue, isDragged) {
                                  final isCorrect = widget.verification.guessedCorrectInstrumentKeys
                                      .contains(instrument.instrumentKey);
                                  final animation = marketCapPositions[instrument.instrumentKey];
                                  final colorTween =
                                      ColorTween(begin: Colors.grey, end: isCorrect ? Colors.green : Colors.red)
                                          .animate(animation.subAnimation);
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: animation.subAnimation
                                          .drive(_slotAnimation(0, 5))
                                          .drive(Tween(begin: 0.0, end: 32.0))
                                          .value,
                                    ),
                                    child: MarketCapInstrumentCard(
                                      instrument: instrument,
                                      marketCapValue: marketCapValue,
                                      moved: null,
                                      isDragged: isDragged,
                                      lineColor: colorTween.value,
                                      circleReplacement: animation.subAnimation.value < 1
                                          ? null
                                          : Container(
                                              alignment: Alignment.topCenter,
                                              child: isCorrect
                                                  ? Icon(Icons.check_circle, color: colorTween.value)
                                                  : Icon(Icons.cancel, color: colorTween.value),
                                            ),
                                      onTap: () {
                                        final details = widget.verification.response.details
                                            .firstWhere((details) => details.instrumentKey == instrument.instrumentKey);
                                        Navigator.of(context)
                                            .push<dynamic>(CompanyDetailsScreen.route(details, instrument.logo));
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                        marketCapScaleMin: simpleGameSet.marketCapScaleMin,
                        marketCapScaleMax: simpleGameSet.marketCapScaleMax,
                        marketCapPositions: marketCapPositions.map((key, value) => MapEntry(key,
                            value.subAnimation.drive(_slotAnimation(1, 5, slotSpan: 4)).drive(value.marketCap).value)),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _forceHideResultOverlay ?? finishAnimation,
                      builder: (BuildContext context, Widget child) =>
                          Opacity(opacity: _forceHideResultOverlay?.value ?? finishAnimation.value, child: child),
                      child: TurnResultOverlay(
                        correctCount: widget.verification.response.correctCount,
                        onShare: _captureImage
                            ? null
                            : () {
                                _shareResult(context);
                              },
                        onClose: _captureImage
                            ? null
                            : () {
                                Deps.of(context).analytics.events.trackCloseResultOverlay();
                                setState(() {
                                  _forceHideResultOverlay = Tween(begin: 1.0, end: 0.0).animate(
                                      AnimationController(duration: const Duration(milliseconds: 300), vsync: this)
                                        ..forward(from: 0));
                                });
                              },
                      ),
                    ),
                  ]),
          ],
        ),
      ),
    );
  }

  // some inspiration from https://github.com/MarcinusX/flutter_ui_challenge_flight_search/blob/v0.5/lib/price_tab/flight_stop_card.dart
  double get maxWidth {
    final renderBox = context.findRenderObject() as RenderBox;
    final constraints = renderBox?.constraints;
    return constraints?.maxWidth ?? 0.0;
  }

  Future<void> _shareResult(BuildContext context) async {
    setState(() {
      _captureImage = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _capturePngWithPicture(context);
        _captureImage = false;
      });
    });
  }

  Future<void> _capturePngWithPicture(BuildContext context) async {
    try {
      final TextSpan span = TextSpan(
          style: TextStyle(color: FinalyzerTheme.colorPrimary, fontSize: 24, fontFamily: 'RobotoMono'),
          text: 'https://anlage.app/game');
      final painter = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      painter.layout();

      final boundary = repaintBoundary.currentContext.findRenderObject() as RenderRepaintBoundary;
      final ui.Image img = await boundary.toImage(pixelRatio: 2.0);

      const padding = 64.0;

      final recorder = ui.PictureRecorder();
      final canvasRect =
          const Offset(0, 0) & Size(img.width + 2 * padding, img.height + 2 * padding + padding + painter.height);
      final canvas = ui.Canvas(recorder, canvasRect);

      final p = Paint();
      p.color = Colors.white;
      canvas.drawRect(canvasRect, p);
      canvas.drawImage(img, const Offset(padding, padding), Paint());

      painter.paint(canvas, Offset(padding, canvasRect.height - padding - painter.height));
      _logger.fine('painter.height: ${painter.height} --- $painter');

      final picture = recorder.endRecording();

      final ui.Image finalImage = await picture.toImage(canvasRect.width.toInt(), canvasRect.height.toInt());

      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _logger.severe('byteData is null ?!');
        return;
      }
      _logger.fine('Opening share dialog.');
      await Share.file('MarketCap Game - Results', 'result.png', byteData.buffer.asUint8List(), 'image/png');
      await Deps.of(context).analytics.logShare(contentType: 'result_sorting', itemId: 'sort', method: 'share');
//      await EsysFlutterShare.shareImage('result.png', byteData, 'MarketShare Game - Results');
    } catch (error, stackTrace) {
      _logger.severe('Error during share', error, stackTrace);
      rethrow;
    }
  }
}

class TurnResultOverlay extends StatelessWidget {
  const TurnResultOverlay({
    Key key,
    @required this.correctCount,
    this.onShare,
    this.onClose,
  }) : super(key: key);

  static const List<String> _emoji = ['🤔', '🤷️', '😎️', '😎️', '🎉️'];
  static const List<String> _correctLabels = [
    'None were correct',
    'Nice try!',
    'Almost!',
    'Almost!',
    'WOW! All Correct!',
  ];
  final int correctCount;
  final VoidCallback onShare;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: onShare == null && onClose == null
                  ? []
                  : <Widget>[
                      FlatButton.icon(
                        icon: Icon(Icons.share),
                        label: const Text('Share'),
                        onPressed: onShare,
                      ),
                      IconButton(icon: Icon(Icons.close), onPressed: onClose),
                    ],
            ),
            Text(
              _emoji[correctCount] ?? '',
//                          textScaleFactor: 10,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 120,
//                            shadows: [Shadow(color: Colors.black54, offset: const Offset(0, 4), blurRadius: 8)],
              ),
            ),
            Card(
              elevation: 2,
              child: Container(
//                            decoration:
//                                BoxDecoration(border: Border.all(), borderRadius: BorderRadius.all(Radius.circular(4))),
                padding: const EdgeInsets.all(8),
                child: Text(
                  _correctLabels[correctCount],
                  style: Theme.of(context).textTheme.body1.apply(fontSizeFactor: 2).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
//                              textScaleFactor: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketCapPositionScaleChild {
  const MarketCapPositionScaleChild({@required this.instrumentKey, @required this.builder});

  final String instrumentKey;
  final Widget Function(BuildContext context, double marketCapValue, bool isDragged) builder;
}

class MarketCapPositionScale extends StatelessWidget {
  const MarketCapPositionScale({
    Key key,
    @required this.moved,
    @required this.instruments,
    @required this.marketCapScaleMin,
    @required this.marketCapScaleMax,
    @required this.marketCapPositions,
    this.draggedInstrument,
    this.changedDraggedInstrument,
    this.draggedInstrumentToMarketCap,
  })  : assert(instruments != null),
        super(key: key);

  final bool moved;
  final String draggedInstrument;
  final List<MarketCapPositionScaleChild> instruments;
  final Map<String, double> marketCapPositions;
  final double marketCapScaleMin;
  final double marketCapScaleMax;
  final void Function(String instrumentKey) changedDraggedInstrument;
  final void Function(String instrumentKey, double newMarketValue) draggedInstrumentToMarketCap;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: MarketPriceLayoutDelegate(marketCapPositions.entries, marketCapScaleMin, marketCapScaleMax),
      children: instruments.map((val) {
        final isDragged = draggedInstrument == val.instrumentKey;

        return LayoutId(
            id: val.instrumentKey,
            child: GestureDetector(
              onVerticalDragStart: changedDraggedInstrument == null
                  ? null
                  : (event) {
                      _logger.fine('started vertical dragging.');
                      changedDraggedInstrument(val.instrumentKey);
                    },
              onVerticalDragDown: (event) {
                _logger.fine('vertical drag down');
              },
              onVerticalDragCancel: changedDraggedInstrument == null
                  ? null
                  : () {
                      _logger.fine('vertical drag cancel.');
                      changedDraggedInstrument(null);
                    },
              onVerticalDragEnd: changedDraggedInstrument == null
                  ? null
                  : (event) {
                      _logger.fine('vertical drag end.');
                      changedDraggedInstrument(null);
                    },
              onVerticalDragUpdate: draggedInstrumentToMarketCap == null
                  ? null
                  : (event) {
                      final renderBox = context.findRenderObject() as RenderBox;
                      final local = renderBox.globalToLocal(event.globalPosition);
                      final totalRange = marketCapScaleMax - marketCapScaleMin;
                      draggedInstrumentToMarketCap(
                          val.instrumentKey, marketCapScaleMax - totalRange / context.size.height * local.dy);
                    },
              child: val.builder(context, marketCapPositions[val.instrumentKey] ?? 0, isDragged),
            ));
      }).toList(),
    );
  }
}

Animatable<double> _slotAnimation(int slot, int totalSlotCount, {double slotSpan = 1}) => TweenSequence([
      if (slot > 0) TweenSequenceItem(tween: ConstantTween(0.0), weight: slot.toDouble()),
      TweenSequenceItem(tween: CurveTween(curve: Curves.easeInOut), weight: slotSpan),
      if (totalSlotCount - slot - slotSpan > 0)
        TweenSequenceItem(tween: ConstantTween(1.0), weight: (totalSlotCount - slot - slotSpan).toDouble()),
    ]);

class MarketCapAnimationTween extends StatefulWidget {
  const MarketCapAnimationTween(
      {Key key, @required this.startMarketCap, this.endMarketCap, @required this.builder, this.animation})
      : assert(startMarketCap != null),
        assert(builder != null),
        super(key: key);

  final Map<String, double> startMarketCap;
  final Iterable<MapEntry<String, double>> endMarketCap;
  final Widget Function(BuildContext context, Map<String, _MarketCapAnimationTweenStateAnimation> marketCap) builder;
  final Animation<double> animation;

  @override
  _MarketCapAnimationTweenState createState() => _MarketCapAnimationTweenState();
}

class _MarketCapAnimationTweenStateAnimation {
  const _MarketCapAnimationTweenStateAnimation._(this.subAnimation, this.marketCap);

  _MarketCapAnimationTweenStateAnimation.drive(this.subAnimation, this.marketCap);

  _MarketCapAnimationTweenStateAnimation.constantValue(double value)
      : this._(const AlwaysStoppedAnimation(1), ConstantTween(value));

  final Animation<double> subAnimation;
  final Animatable<double> marketCap;
}

class _MarketCapAnimationTweenState extends State<MarketCapAnimationTween> {
  Map<String, _MarketCapAnimationTweenStateAnimation> _tweenMarketCap;

//  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _reInitState();
  }

  @override
  void didUpdateWidget(MarketCapAnimationTween oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.finer('_MarketCapAnimationTweenState.didUpdateWidget --- changed: ${widget != oldWidget}');
    if (widget != oldWidget) {
      _reInitState();
    }
  }

  void _reInitState() {
    if (widget.endMarketCap != null && widget.animation != null) {
//      _controller = AnimationController(duration: const Duration(seconds: 5), vsync: this);
//      _controller.forward();

      const delay = 0;

      final slotCount = widget.endMarketCap.length + delay;
      int slot = delay;

      final sorted = widget.endMarketCap.toList()..sort((a, b) => -a.value.compareTo(b.value));

      _tweenMarketCap = Map.fromEntries(
        sorted.map(
          (entry) => MapEntry(
            entry.key,
            _MarketCapAnimationTweenStateAnimation.drive(widget.animation.drive(_slotAnimation(slot++, slotCount)),
                Tween(begin: widget.startMarketCap[entry.key], end: entry.value)),
          ),
        ),
      );
    } else {
//      _controller = null;
      _tweenMarketCap = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animation == null || _tweenMarketCap == null) {
      _logger.finer('No controller.');
      return widget.builder(
          context,
          widget.startMarketCap
              .map((key, value) => MapEntry(key, _MarketCapAnimationTweenStateAnimation.constantValue(value))));
    }
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
//        final marketCaps = _tweenMarketCap.map((entry, animation) => MapEntry(entry, animation));
//        _logger.finer('new marketCaps: (${_controller.value}) $marketCaps');
        return widget.builder(context, _tweenMarketCap);
      },
    );
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
    this.circleReplacement,
    this.lineColor = FinalyzerTheme.colorSecondary,
    this.onTap,
    this.disabled = false,
  }) : super(key: key);

  final SimpleGameDto instrument;
  final double marketCapValue;
  final bool moved;
  final bool isDragged;
  final Color lineColor;
  final Widget circleReplacement;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final deps = DepsProvider.of(context);
    final _apiService = deps.api;
    final arrows = moved == null
        ? <Widget>[]
        : <Widget>[
            Positioned(
              top: -30,
              right: _STOCK_CARD_WIDTH / 2 - 12,
              child: AnimatedOpacity(
                  opacity: moved ? 0 : 1,
                  duration: const Duration(milliseconds: 500),
                  child: Icon(Icons.arrow_upward, size: 24, color: Colors.black26)),
            ),
            Positioned(
              bottom: -30,
              right: _STOCK_CARD_WIDTH / 2 - 12,
              child: AnimatedOpacity(
                opacity: moved ? 0 : 1,
                duration: const Duration(milliseconds: 500),
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
//                color: Colors.green,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: CachedNetworkImage(
                      color: disabled ? Colors.white : null,
                      colorBlendMode: BlendMode.color,
                      placeholder: (context, url) => const Center(child: LinearProgressIndicator()),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          instrument.symbol ?? 'Error ${instrument.logo.id}',
                          style: Theme.of(context).textTheme.body2,
                        ),
                      ),
//                              width: 100,
//                                  height: 50,
                      imageUrl: _apiService.getImageUrl(instrument.logo),
                    ),
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
      margin: const EdgeInsets.only(left: MarketCapScalePainter.MARGIN_LEFT + MarketCapScalePainter.SCALE_WIDTH + 4.0),
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
    const dotSize = 12.0;
    return Align(
      alignment: Alignment.centerRight,
      heightFactor: 6.0,
      child: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: MarketCapScalePainter.MARGIN_LEFT, right: stockCardWidth + 4),
            height: 2.0,
//          width: 300,
            color: lineColor, //Color.fromARGB(255, 200, 200, 200),
          ),
          Positioned(
            top: circleReplacement != null ? -12 : -(dotSize / 2),
            right: stockCardWidth - 4 - (dotSize / 2),
//            height: dotSize,
//            width: dotSize,
            child: circleReplacement ??
                Container(
//              margin: EdgeInsets.,
                  alignment: Alignment.centerRight,
                  height: dotSize,
                  width: dotSize,
                  decoration: BoxDecoration(
                      color: lineColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26 /*FinalyzerTheme.colorSecondary*/, width: 1.0)),
                ),
          ),
        ],
      ),
    );
  }
}
