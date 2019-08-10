import 'dart:ui' as ui;

import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/finalyzer_theme.dart';
import 'package:anlage_app_game/screens/challenge/challenge.dart';
import 'package:anlage_app_game/screens/company_details.dart';
import 'package:anlage_app_game/screens/market_cap_game_bloc.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:anlage_app_game/utils/route_observer_analytics.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('market_cap_sorting_result');

class MarketCapSortingResultWidget extends StatelessWidget {
  MarketCapSortingResultWidget(this.response, this._gameBloc, this._gameSet);

  final GameSimpleSetVerifyResponse response;
  final MarketCapSortingGameBloc _gameBloc;
  final GameSimpleSetResponse _gameSet;
  final GlobalKey drawGlobalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final challengeBloc =
        _gameBloc is MarketCapSortingChallengeBloc ? _gameBloc as MarketCapSortingChallengeBloc : null;
//    final _gameBloc = MarketCapSortingGameProvider.of(context);
    final deps = DepsProvider.of(context);
    return Container(
      child: AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        content: SingleChildScrollView(
          child: RepaintBoundary(
            key: drawGlobalKey,
            child: _createResultScreen(response, _gameSet, _gameBloc, context),
          ),
        ),
        actions: <Widget>[
          FlatButton.icon(
            icon: Icon(Icons.share),
            label: const Text('Share'),
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
                  ..pushReplacement<dynamic, dynamic>(
                    AnalyticsPageRoute<dynamic>(
                        name: '/challenge/details',
                        builder: (context) => ChallengeDetails(challengeBloc.challenge.challengeId)),
                  );
              } else {
                Navigator.of(context).pop();
                _gameBloc.nextTurn();

                DialogUtil.askForPermissionsIfRequired(deps);
              }
            },
          )
        ],
      ),
    );
  }

  Widget _createResultScreen(GameSimpleSetVerifyResponse response, GameSimpleSetResponse gameSet,
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
                            : const Text('?!')),

//        Text('${response.correctCount} correct answers.'),
            Container(
              padding: const EdgeInsets.only(bottom: 8, top: 20),
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
                        Navigator.of(context).push<dynamic>(AnalyticsPageRoute<dynamic>(
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
                                      placeholder: (context, url) => const Center(child: LinearProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Center(child: Text(info.symbol ?? 'Error ${info.logo.id}')),
                                      width: 100,
                                      height: 40,
                                      imageUrl: _api.getImageUrl(info.logo),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
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
                                margin: const EdgeInsets.only(left: 8),
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
    AnalyticsUtils.instance.analytics.logEvent(name: 'verify_sort', parameters: <String, dynamic>{'score': score});

    return ret;
  }

  Future<void> _capturePngWithPicture(BuildContext context) async {
    try {
      final TextSpan span = TextSpan(
          style: TextStyle(color: FinalyzerTheme.colorPrimary, fontSize: 24, fontFamily: 'RobotoMono'),
          text: 'https://anlage.app/game');
      final painter = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      painter.layout();

      final boundary = drawGlobalKey.currentContext.findRenderObject() as RenderRepaintBoundary;
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
//      await EsysFlutterShare.shareImage('result.png', byteData, 'MarketShare Game - Results');
    } catch (error, stackTrace) {
      _logger.warning('Error during share', error, stackTrace);
      rethrow;
    }
  }
}
