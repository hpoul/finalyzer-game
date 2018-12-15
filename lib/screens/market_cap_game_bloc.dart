import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _logger = new Logger("app.anlage.game.screens.market_cap_sorting");

class MarketCapSortingGameBloc {
  final _apiService = ApiService.instance;

//  GameSimpleSetResponse simpleGameSet;
  Iterable<MapEntry<String, double>> marketCapPositions;

  BehaviorSubject<GameSimpleSetResponse> _simpleGameSetFetcher;

  GameSimpleSetResponse _currentSimpleGameSet;

  ValueObservable<GameSimpleSetResponse> get simpleGameSet => _simpleGameSetFetcher.stream;

  MarketCapSortingGameBloc() {
    _simpleGameSetFetcher = BehaviorSubject<GameSimpleSetResponse>(onListen: () {
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

  void newGame() {
    _simpleGameSetFetcher.add(null);
    _logger.fine('Fetching new game.');
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
          ..add(MapEntry(instrumentKey, marketCap)))
        .toList();
  }

  Future<GameSimpleSetVerifyResponse> verifyMarketCaps() {
    return _apiService.verifySimpleGameSet(
        _currentSimpleGameSet.gameTurnId,
        marketCapPositions
            .map((pos) => GameSimpleSetGuessDto(pos.key, pos.value))
            .toList()
          ..sort((a, b) => -a.marketCap.compareTo(b.marketCap) )
    );
  }
}

class MarketCapSortingGameProvider extends InheritedWidget {
  final MarketCapSortingGameBloc game;

  MarketCapSortingGameProvider({Key key, MarketCapSortingGameBloc game, Widget child})
      : game = game ?? MarketCapSortingGameBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static MarketCapSortingGameBloc of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(MarketCapSortingGameProvider) as MarketCapSortingGameProvider).game;
}
