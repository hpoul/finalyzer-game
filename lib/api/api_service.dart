

import 'dart:io';

import 'package:anlage_app_game/api/dtos.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = new Logger("app.anlage.game.api.api_service");

class ApiService {
  static final ApiService instance = new ApiService();
  static final PREF_GAME_SESSION = 'GAME_SESSION';
  static final GAME_SESSION_HEADER = 'GAME_SESSION';


  Env _env;
  Uri _baseUri;

  String _gameSession;


  ApiService({Env env}) {
    this._env = env ?? Env.value;
    _baseUri = Uri.parse(_env.baseUrl);
  }

  Future<String> getGameSession() async {
    if (_gameSession != null) {
      return _gameSession;
    }

    final prefs = await SharedPreferences.getInstance();
    _gameSession = prefs.getString(PREF_GAME_SESSION);

    if (_gameSession != null) {
      return _gameSession;
    }

    _gameSession = await this._registerDevice();
    prefs.setString(PREF_GAME_SESSION, _gameSession);
    return _gameSession;
  }
  
  Future<String> _registerDevice() async {
    final dio = Dio();
    final response = await dio.post(
        _baseUri.resolve("api/game/registerDevice").toString(),
        data: RegisterDeviceRequest(osInfo: "${Platform.operatingSystem} ${Platform.operatingSystemVersion} - Dart ${Platform.version}", deviceInfo: "TODO",
            platform: Platform.isIOS ? DevicePlatform.iOS : Platform.isAndroid ? DevicePlatform.Android : DevicePlatform.Unknown).toJson(),
        options: Options(responseType: ResponseType.JSON));
    final gameSession = response.headers.value('GAME_SESSION');
    _logger.finer('Got Game Session: $gameSession');
    return gameSession;
  }

  Future<Dio> getSessionDio() async {
    return Dio(Options(headers: {GAME_SESSION_HEADER: await this.getGameSession()}));
  }

  Future<GameSimpleSetResponse> getSimpleGameSet() async {
    _logger.fine('Requesting simple game set. ${_baseUri.resolve("api/game/simpleGameSet")}');
    var dio = await getSessionDio();
//    await Future.delayed(Duration(seconds: 5));
    var response = await dio.get(_baseUri.resolve("api/game/simpleGameSet").toString(), options: Options(responseType: ResponseType.JSON));
    return GameSimpleSetResponse.fromJson(response.data);

//    var request = await _httpClient.getUrl(_baseUri.resolve("api/game/simpleGameSet"));
//    var response = await request.close();
//    response.read
  }

  Future<GameSimpleSetVerifyResponse> verifySimpleGameSet(String gameTurnId, List<GameSimpleSetGuessDto> guesses) async {
    var dio = await getSessionDio();
    var response = await dio.post(
        _baseUri.resolve('api/game/simpleGameSet').toString(),
        data: GameSimpleSetVerifyRequest(gameTurnId, guesses).toJson(),
        options: Options(responseType: ResponseType.JSON));
    return GameSimpleSetVerifyResponse.fromJson(response.data);
  }

  String getImageUrl(InstrumentImageDto image) {
    return _baseUri.resolve('api/pricedata/image/${image.id}?noSVG=true').toString();
  }
}