

import 'dart:io';

import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger("app.anlage.game.api.api_caller");

class ApiCaller {
  static const PREF_GAME_SESSION = 'GAME_SESSION';
  static const GAME_SESSION_HEADER = 'GAME-SESSION';


  final Env _env;
  final Uri _baseUri;
  Dio _dio;

  String _gameSession;

  ApiCaller(this._env)
      : _baseUri = Uri.parse(_env.baseUrl) {
    _dio = _createSessionDio();
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

  Future<String> _registerDevice() async {
    final dio = Dio();
    final location = RegisterDeviceLocation();
    final response = await _post(location, RegisterDeviceRequest(
        "TODO",
        "${Platform.operatingSystem} ${Platform.operatingSystemVersion} - Dart ${Platform.version}",
        Platform.isIOS ? DevicePlatform.iOS : Platform.isAndroid ? DevicePlatform.Android : DevicePlatform.Unknown).toJson(),
        dio: dio
    );
    final gameSession = response.response.headers.value(GAME_SESSION_HEADER);
    _logger.finer('Got Game Session: $gameSession');
    if (gameSession == null) {
      throw StateError('Got null response for gameSession from server.');
    }
    return gameSession;
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

  Future<U> get<U>(GetLocation<U> location) async {
    if (_env.fakeLatency != null) {
      await Future.delayed(_env.fakeLatency);
    }
    final dio = _dio;
    try {
      final response = await dio.get(_baseUri.resolve(location.path).toString(), options: Options(responseType: ResponseType.JSON));
      return location.bodyFromGetJson(response.data);
    } on DioError catch (dioError) {
      throw ApiNetworkError.fromError(dioError);
    }
  }

  Future<ResponseWrapper<U>> post<T, U>(PostBodyLocation<T, U> location, T args) async {
    return await _post(location, args);
  }

  Future<ResponseWrapper<U>> _post<T, U>(PostBodyLocation<T, U> location, T args, {Dio dio}) async {
    final client = dio ?? _dio;
    try {
      final response = await client.post(_baseUri.resolve(location.path).toString(), data: args);
      return ResponseWrapper(response, location.bodyFromPostJson(response.data));
    } on DioError catch (dioError) {
      throw ApiNetworkError.fromError(dioError);
    } catch (error, stackTrace) {
      _logger.warning('Error during post request', error, stackTrace);
      rethrow;
    }
  }

  Future<ResponseWrapper<U>> upload<T, U>(PostBodyLocation<T, U> location, FormData data) async {
    final client = _dio;
    try {
      final response = await client.post(_baseUri.resolve(location.path).toString(), data: data);
      return ResponseWrapper(response, location.bodyFromPostJson(response.data));
    } on DioError catch (dioError) {
      throw ApiNetworkError.fromError(dioError);
    } catch (error, stackTrace) {
      _logger.warning('Error during post request', error, stackTrace);
      rethrow;
    }
  }


}
