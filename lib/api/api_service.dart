

import 'dart:io';

import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';

final _logger = new Logger("app.anlage.game.api.api_service");

class LoginState {

  String avatarUrl;

  UserInfoResponse userInfo;

}

class ResponseWrapper<T> {
  Response<dynamic> response;
  T data;

  ResponseWrapper(this.response, this.data);
}

class ApiService {
  static final ApiService instance = new ApiService();
  static const PREF_GAME_SESSION = 'GAME_SESSION';
  static const GAME_SESSION_HEADER = 'GAME-SESSION';

  final _loginState = BehaviorSubject<LoginState>();
  get loginState => _loginState.stream;

  Env _env;
  Uri _baseUri;

  String _gameSession;
  Dio _dio;


  ApiService({Env env}) {
    this._env = env ?? Env.value;
    _baseUri = Uri.parse(_env.baseUrl);
    _dio = _createSessionDio();
    
    // some arbitrary time after staring up, request current status from the server.
    Future.delayed(Duration(seconds: 3)).then((x) async {
      var deviceInfo;
      if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        deviceInfo = "${iosInfo.model},${iosInfo.name},${iosInfo.systemName},${iosInfo.systemVersion}";
      } else if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        deviceInfo = "${androidInfo.model},${androidInfo.brand},${androidInfo.device},${androidInfo.board},${androidInfo.manufacturer},${androidInfo.product},${androidInfo.version.baseOS},${androidInfo.version.release}";
      }
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = "${packageInfo.version} (${packageInfo.buildNumber}) ${packageInfo.packageName} ${packageInfo.appName}";
      _logger.finer('sending userinfo.');
      final userInfo = (await this._post(UserInfoLocation(), UserInfoRequest(appVersion, deviceInfo))).data;
      _loginState.add(LoginState()
        ..avatarUrl = 'https://robohash.org/a${userInfo.key}'
        ..userInfo = userInfo);
    });
  }

  Dio _createSessionDio() {
    final dio = Dio();
    dio.interceptor.request.onSend = (Options options) async {
      var gameSession = await _getGameSessionFromPreferences();

      if (gameSession == null) {
        dio.interceptor.request.lock();
        _logger.info('No session found, registering device.');
        await Future.delayed(Duration(seconds: 5)); _logger.severe('DEBUG WAITING for 5 SECONDS.');

        try {
          gameSession = await _registerDevice();
          _setGameSession(gameSession);
        } finally {
          dio.interceptor.request.unlock();
        }
      }

      options.headers[GAME_SESSION_HEADER] = gameSession;

      return options;
    };
    dio.interceptor.response.onError = (DioError error) async {
      if (error.response != null && error.response.statusCode == HttpStatus.unauthorized) {
        _logger.severe('It seems session got invalid. at least remove session so on next request it is working again. ${await this._getGameSessionFromPreferences()}');
        await _setGameSession(null);
      }
      return error;
    };
    return dio;
  }

  Future<String> _getGameSessionFromPreferences() async {
    if (_gameSession != null) {
      return _gameSession;
    }

    final prefs = await SharedPreferences.getInstance();
    _gameSession = prefs.getString(PREF_GAME_SESSION);
    return _gameSession;
  }

  Future<void> _setGameSession(String gameSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREF_GAME_SESSION, gameSession);
    _gameSession = gameSession;
  }

  Future<String> _registerDevice() async {
    final dio = Dio();
    final location = RegisterDeviceLocation();
    final response = await _post(location, RegisterDeviceRequest(
        "TODO",
        "${Platform.operatingSystem} ${Platform.operatingSystemVersion} - Dart ${Platform.version}",
        Platform.isIOS ? DevicePlatform.iOS : Platform.isAndroid ? DevicePlatform.Android : DevicePlatform.Unknown).toJson(),
        dio: dio
    );
    final d = response.data.deviceKey;
    final gameSession = response.response.headers.value(GAME_SESSION_HEADER);
    _logger.finer('Got Game Session: $gameSession');
    if (gameSession == null) {
      throw StateError('Got null response for gameSession from server.');
    }
    return gameSession;
  }


  Future<U> _get<U>(GetLocation<U> location) async {
    final dio = await getSessionDio();
    final response = await dio.get(_baseUri.resolve(location.path).toString(), options: Options(responseType: ResponseType.JSON));
    return location.bodyFromGetJson(response.data);
  }

  Future<ResponseWrapper<U>> _post<T, U>(PostBodyLocation<T, U> location, T args, {Dio dio}) async {
    final client = dio ?? await getSessionDio();
    try {
      final response = await client.post(_baseUri.resolve(location.path).toString(), data: args);
      return ResponseWrapper(response, location.bodyFromPostJson(response.data));
    } catch (error, stackTrace) {
      _logger.warning('Error during post request', error, stackTrace);
      rethrow;
    }
  }

  Future<Dio> getSessionDio() async {
    return _dio;
  }

  Future<GameSimpleSetResponse> getSimpleGameSet() async {
    _logger.fine('Requesting simple game set. ${_baseUri.resolve("api/game/simpleGameSet")}');
    return await _get(GameSimpleSetLocation());

//    var request = await _httpClient.getUrl(_baseUri.resolve("api/game/simpleGameSet"));
//    var response = await request.close();
//    response.read
  }

  Future<GameSimpleSetVerifyResponse> verifySimpleGameSet(String gameTurnId, List<GameSimpleSetGuessDto> guesses) async {
    final result = await this._post(GameSimpleSetLocation(), GameSimpleSetVerifyRequest(gameTurnId, guesses));
    final state = _loginState.value;
    state.userInfo.statsCorrectAnswers = result.data.statsCorrectAnswers;
    state.userInfo.statsTotalTurns = result.data.statsTotalTurns;
    _loginState.add(state);
    return result.data;
  }

  String getImageUrl(InstrumentImageDto image) {
    return _baseUri.resolve('api/pricedata/image/${image.id}?noSVG=true').toString();
  }
}