import 'dart:async';
import 'dart:io';

import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger('app.anlage.game.api.api_caller');

class ApiCallerInterceptor implements Interceptor {
  ApiCallerInterceptor(this._apiCaller, this._dio);

  final ApiCaller _apiCaller;
  final Dio _dio;

  @override
  FutureOr onError(DioError error) async {
    if (error.response != null && error.response.statusCode == HttpStatus.unauthorized) {
      _logger.severe(
          'It seems session got invalid. at least remove session so on next request it is working again. ${await _apiCaller._getGameSessionFromPreferences()}');
      await _apiCaller._setGameSession(null);
    }
    return error;
  }

  @override
  FutureOr onRequest(RequestOptions options) async {
    var gameSession = await _apiCaller._getGameSessionFromPreferences();

    if (gameSession == null) {
      _dio.interceptors.requestLock.lock();
      _logger.info('No session found, registering device.');

      try {
        gameSession = await _apiCaller._registerDevice();
        await _apiCaller._setGameSession(gameSession);
      } finally {
        _dio.interceptors.requestLock.unlock();
      }
    }

    options.headers[ApiCaller.GAME_SESSION_HEADER] = gameSession;

    return options;
  }

  @override
  FutureOr onResponse(Response response) {
    // TODO: implement onResponse
    return null;
  }
}

class SessionStore {
  const SessionStore();
  static const PREF_GAME_SESSION = 'GAME_SESSION';

  Future<String> loadSession() async {
    final storage = FlutterSecureStorage();
    String _gameSession = await storage.read(key: PREF_GAME_SESSION);

    if (_gameSession == null) {
      // for backward compatibility check shared preferences.
      final prefs = await SharedPreferences.getInstance();
      _gameSession = prefs.getString(PREF_GAME_SESSION);
      if (_gameSession != null) {
        await storage.write(key: PREF_GAME_SESSION, value: _gameSession);
        await prefs.remove(PREF_GAME_SESSION);
      }
    }
    return _gameSession;
  }

  Future<void> writeSession(String gameSession) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: PREF_GAME_SESSION, value: gameSession);
  }
}

class ApiCaller {
  ApiCaller(this._env, {this.sessionStore = const SessionStore()}) : _baseUri = Uri.parse(_env.baseUrl) {
    _dio = _createSessionDio();
  }

  static const GAME_SESSION_HEADER = 'GAME-SESSION';

  final Env _env;
  final Uri _baseUri;
  final SessionStore sessionStore;
  Dio _dio;

  String _gameSession;

  Dio _createSessionDio() {
    final dio = Dio();
    dio.interceptors.add(ApiCallerInterceptor(this, dio));
    return dio;
  }

  Future<String> _registerDevice() async {
    final dio = Dio();
    final location = RegisterDeviceLocation();
    final response = await _post(
        location,
        RegisterDeviceRequest(
                'TODO', // TODO implement device info?
                '${Platform.operatingSystem} ${Platform.operatingSystemVersion} - Dart ${Platform.version}',
                Platform.isIOS
                    ? DevicePlatform.iOS
                    : Platform.isAndroid ? DevicePlatform.Android : DevicePlatform.Unknown)
            .toJson(),
        dio: dio);
    final gameSession = response.response.headers.value(GAME_SESSION_HEADER);
    _logger.finer('Got Game Session: $gameSession');
    if (gameSession == null) {
      throw StateError('Got null response for gameSession from server.');
    }
    return gameSession;
  }

  Future<String> _getGameSessionFromPreferences() async {
    return _gameSession ??= await sessionStore.loadSession();
  }

  Future<void> _setGameSession(String gameSession) async {
    await sessionStore.writeSession(gameSession);
    _gameSession = gameSession;
  }

  Future<U> get<U>(GetLocation<U> location) async {
    if (_env.fakeLatency != null) {
      await Future<dynamic>.delayed(_env.fakeLatency);
    }
    final dio = _dio;
    try {
      final response = await dio.get<dynamic>(_baseUri.resolve(location.path).toString(),
          options: Options(responseType: ResponseType.json));
      return location.bodyFromGetJson(response.data);
    } on DioError catch (dioError, stackTrace) {
      _logger.finer('${_gameSession}Error during api call $location', dioError, stackTrace);
      throw ApiNetworkError.fromError(dioError);
    }
  }

  Future<U> post<T, U>(PostBodyLocation<T, U> location, T args) async {
    return (await _post(location, args)).data;
  }

  Future<ResponseWrapper<U>> _post<T, U>(PostBodyLocation<T, U> location, T args, {Dio dio}) async {
    final client = dio ?? _dio;
    try {
      final response = await client.post<dynamic>(_baseUri.resolve(location.path).toString(), data: args);
      return ResponseWrapper(response, location.bodyFromPostJson(response.data));
    } on DioError catch (dioError) {
      throw ApiNetworkError.fromError(dioError);
    } catch (error, stackTrace) {
      _logger.warning('Error during post request', error, stackTrace);
      rethrow;
    }
  }

  Future<U> put<T, U>(PutBodyLocation<T, U> location, T args) async {
    final client = _dio;
    try {
      final response = await client.put<dynamic>(_baseUri.resolve(location.path).toString(), data: args);
      return location.bodyFromPutJson(response.data);
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
      final response = await client.post<dynamic>(_baseUri.resolve(location.path).toString(), data: data);
      return ResponseWrapper(response, location.bodyFromPostJson(response.data));
    } on DioError catch (dioError) {
      throw ApiNetworkError.fromError(dioError);
    } catch (error, stackTrace) {
      _logger.warning('Error during post request', error, stackTrace);
      rethrow;
    }
  }
}
