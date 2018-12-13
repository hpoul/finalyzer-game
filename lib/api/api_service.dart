

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

class ApiService {
  static final ApiService instance = new ApiService();
  static const PREF_GAME_SESSION = 'GAME_SESSION';
  static const GAME_SESSION_HEADER = 'GAME_SESSION';

  final _loginState = BehaviorSubject<LoginState>();
  get loginState => _loginState.stream;

  Env _env;
  Uri _baseUri;

  String _gameSession;


  ApiService({Env env}) {
    this._env = env ?? Env.value;
    _baseUri = Uri.parse(_env.baseUrl);
    
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
      final userInfo = await this._post(UserInfoLocation(), UserInfoRequest(appVersion, deviceInfo));
      _loginState.add(LoginState()
        ..avatarUrl = 'https://robohash.org/a${userInfo.key}'
        ..userInfo = userInfo);
    });
  }

  Future<String> getGameSession() async {
    if (_gameSession != null) {
      return _gameSession;
    }

    final prefs = await SharedPreferences.getInstance();
    _gameSession = prefs.getString(PREF_GAME_SESSION);

    if (_gameSession == null) {
      _gameSession = await this._registerDevice();
    }

    prefs.setString(PREF_GAME_SESSION, _gameSession);
    _loginState.add(LoginState()..avatarUrl = 'https://robohash.org/a${_gameSession.hashCode.toString()}');

    return _gameSession;
  }
  
  Future<String> _registerDevice() async {
    final dio = Dio();
    final location = RegisterDeviceLocation();
    final response = await dio.post(
        _baseUri.resolve(location.path).toString(),
        data: RegisterDeviceRequest(
            "TODO",
            "${Platform.operatingSystem} ${Platform.operatingSystemVersion} - Dart ${Platform.version}",
            Platform.isIOS ? DevicePlatform.iOS : Platform.isAndroid ? DevicePlatform.Android : DevicePlatform.Unknown).toJson(),
        options: Options(responseType: ResponseType.JSON));
    final gameSession = response.headers.value('GAME_SESSION');
    _logger.finer('Got Game Session: $gameSession');
    return gameSession;
  }

  Future<U> _get<U>(GetLocation<U> location) async {
    final dio = await getSessionDio();
    final response = await dio.get(_baseUri.resolve(location.path).toString(), options: Options(responseType: ResponseType.JSON));
    return location.bodyFromGetJson(response.data);
  }

  Future<U> _post<T, U>(PostBodyLocation<T, U> location, T args, {Dio dio}) async {
    final client = dio ?? await getSessionDio();
    final response = await client.post(_baseUri.resolve(location.path).toString(), data: args);
    return location.bodyFromPostJson(response.data);
  }

  Future<Dio> getSessionDio() async {
    return Dio(Options(headers: {GAME_SESSION_HEADER: await this.getGameSession()}));
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
    state.userInfo.statsCorrectAnswers = result.statsCorrectAnswers;
    state.userInfo.statsTotalTurns = result.statsTotalTurns;
    _loginState.add(state);
    return result;
  }

  String getImageUrl(InstrumentImageDto image) {
    return _baseUri.resolve('api/pricedata/image/${image.id}?noSVG=true').toString();
  }
}