import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/data/company_info_store.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('app.anlage.game.ui.screens.market_cap_sorting');

class MarketCapSortingGameBloc {
  MarketCapSortingGameBloc(this._apiService, {@required this.companyInfoStore}) {
    _logger.finer('New MarketCapSortingGameBloc created. $runtimeType');
    _simpleGameSetFetcher = BehaviorSubject<GameSimpleSetResponse>.seeded(null, onListen: () {
      _logger.fine('_simpleGameSetFetcher is being listened to.');
//      fetchGame();
    });
    simpleGameSet.listen((event) {
      _logger.fine('Got new game set $event');
      if (event == null) {
        return;
      }
      _currentSimpleGameSet = event;
      calculateMarketCapPositions(event);
    });
  }

  final ApiService _apiService;
  final CompanyInfoStore companyInfoStore;

  ApiService get api => _apiService;

  Iterable<MapEntry<String, double>> marketCapPositions;

  BehaviorSubject<GameSimpleSetResponse> _simpleGameSetFetcher;

  GameSimpleSetResponse _currentSimpleGameSet;

  ValueObservable<GameSimpleSetResponse> get simpleGameSet => _simpleGameSetFetcher.stream;

  final int maxTurns = null;
  int get currentTurn => null;

  void dispose() {
    _simpleGameSetFetcher.close();
  }

  void nextTurn() {
    _simpleGameSetFetcher.add(null);
    _logger.fine('Fetching new turn.');
    _apiService.getSimpleGameSet().then((val) {
      AnalyticsUtils.instance.analytics.logEvent(name: 'start_new_sort');
      _simpleGameSetFetcher.add(val);
    }).catchError((dynamic error, StackTrace stackTrace) {
      if (error is ApiNetworkError) {
        _logger.warning('Error while fetching new game.', error, stackTrace);
      } else {
        _logger.severe('Error while loading new game. (NOT NETWORK)', error, stackTrace);
      }
      _simpleGameSetFetcher.addError(error, stackTrace);
    });
  }

  void calculateMarketCapPositions(GameSimpleSetResponse simpleGameSet) {
    final totalRange = simpleGameSet.marketCapScaleMax - simpleGameSet.marketCapScaleMin;
    final padding = totalRange * 0.1;
    final rangeMin = simpleGameSet.marketCapScaleMin + padding;
    final range = totalRange - 2 * padding;
    final singlePos = range / (simpleGameSet.simpleGame.length - 1);
    var i = 0;

    _logger.fine('Positioning simpleGame starting at ${simpleGameSet.marketCapScaleMin} $i');
    marketCapPositions =
        simpleGameSet.simpleGame.map((dto) => MapEntry(dto.instrumentKey, rangeMin + (singlePos * i++))).toList();
  }

  void updateMarketCapPosition(String instrumentKey, double marketCap) {
    marketCapPositions = (marketCapPositions.where((e) => e.key != instrumentKey).toList(growable: true)
          ..add(MapEntry(
              instrumentKey,
              trimToRange(
                  min: _currentSimpleGameSet.marketCapScaleMin,
                  max: _currentSimpleGameSet.marketCapScaleMax,
                  value: marketCap))))
        .toList();
  }

  Future<GameSimpleSetVerifyResponseWrapper> verifyMarketCaps() {
    final guess = marketCapPositions.map((pos) => GameSimpleSetGuessDto(pos.key, pos.value)).toList()
      ..sort((a, b) => -a.marketCap.compareTo(b.marketCap));
    final gameTurnId = _currentSimpleGameSet.gameTurnId;
    final logos = Map.fromEntries(_currentSimpleGameSet.simpleGame.map((instrument) => MapEntry(
          instrument.instrumentKey,
          instrument.logo,
        )));
    return _apiService.verifySimpleGameSet(gameTurnId, guess).then((response) {
      final guessMap = Map<int, GameSimpleSetGuessDto>.from(guess.asMap());
      final actualMap = response.actual.toList()..sort((a, b) => -a.marketCap.compareTo(b.marketCap));
      guessMap.removeWhere((key, value) => actualMap[key].instrumentKey != value.instrumentKey);

      companyInfoStore.update(
        (b) => b
          ..companyInfos.addEntries(response.details.map(
            (details) => MapEntry(
                details.instrumentKey,
                CompanyInfoWrapper(
                  (wb) => wb
                    ..details = details
                    ..logo = logos[details.instrumentKey],
                )),
          ))
          ..history.add(
            HistoryGameSet(
              (hb) => hb
                ..playAt = DateTime.now().toUtc()
                ..instruments.replace(response.details.map<String>((details) => details.instrumentKey))
                ..turnId = gameTurnId
                ..points = response.correctCount,
            ),
          ),
      );

      return GameSimpleSetVerifyResponseWrapper(
          response: response,
          guessedCorrectInstrumentKeys: guessMap.values.map<String>((i) => i.instrumentKey).toSet());
    });
  }
}

class GameSimpleSetVerifyResponseWrapper {
  GameSimpleSetVerifyResponseWrapper({this.response, this.guessedCorrectInstrumentKeys});
  final GameSimpleSetVerifyResponse response;
  final Set<String> guessedCorrectInstrumentKeys;
}

class MarketCapSortingChallengeBloc extends MarketCapSortingGameBloc {
  MarketCapSortingChallengeBloc(
    ApiService apiService,
    this.challenge, {
    @required CompanyInfoStore companyInfoStore,
  }) : super(apiService, companyInfoStore: companyInfoStore);

  GameChallengeDto challenge;

  @override
  int currentTurn = -1;

  @override
  int get maxTurns => challenge.simpleGame.length;

  bool get isCompleted => currentTurn + 1 == maxTurns;

  @override
  void nextTurn() {
    currentTurn++;
    final turn = challenge.simpleGame[currentTurn];
    _simpleGameSetFetcher.add(turn);
  }
}
