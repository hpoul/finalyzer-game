import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/utils_format.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _logger = new Logger("app.anlage.game.screens.market_cap_sorting");

class MarketCapSortingGameBloc {
  final ApiService _apiService;

  ApiService get api => _apiService;

  Iterable<MapEntry<String, double>> marketCapPositions;

  BehaviorSubject<GameSimpleSetResponse> _simpleGameSetFetcher;

  GameSimpleSetResponse _currentSimpleGameSet;

  ValueObservable<GameSimpleSetResponse> get simpleGameSet => _simpleGameSetFetcher.stream;

  final int maxTurns = null;
  final int currentTurn = null;

  MarketCapSortingGameBloc(this._apiService) {
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

  void dispose() {
    _simpleGameSetFetcher.close();
  }

  void nextTurn() {
    _simpleGameSetFetcher.add(null);
    _logger.fine('Fetching new turn.');
    _apiService.getSimpleGameSet().then((val) {
      AnalyticsUtils.instance.analytics.logEvent(name: 'start_new_sort');
      _simpleGameSetFetcher.add(val);
    }).catchError((error, stackTrace) {
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
    var singlePos = range / (simpleGameSet.simpleGame.length - 1);
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
    return _apiService.verifySimpleGameSet(_currentSimpleGameSet.gameTurnId, guess).then((response) {
      final guessMap = Map.from(guess.asMap());
      final actualMap = response.actual.toList()..sort((a, b) => -a.marketCap.compareTo(b.marketCap));
      guessMap.removeWhere((key, value) => actualMap[key].instrumentKey != value.instrumentKey);
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
  GameChallengeDto challenge;
  @override
  int currentTurn = -1;

  @override
  int get maxTurns => challenge.simpleGame.length;

  bool get isCompleted => currentTurn + 1 == maxTurns;

  MarketCapSortingChallengeBloc(ApiService apiService, this.challenge) : super(apiService);

  @override
  void nextTurn() {
    currentTurn++;
    final turn = challenge.simpleGame[currentTurn];
    _simpleGameSetFetcher.add(turn);
  }
}
