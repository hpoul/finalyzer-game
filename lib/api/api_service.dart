

import 'dart:io';

import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:anlage_app_game/utils/analytics.dart';
import 'package:anlage_app_game/utils/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';
import 'package:pedantic/pedantic.dart';

final _logger = new Logger("app.anlage.game.api.api_service");

class LoginState {

  LoginState(Uri baseUri, UserInfoResponse userInfoResponse) :
        avatarUrl = baseUri.resolve(userInfoResponse.avatarUrl).toString(),
        userInfo = userInfoResponse;

  String avatarUrl;

  UserInfoResponse userInfo;

}

class ResponseWrapper<T> {
  Response<dynamic> response;
  T data;

  ResponseWrapper(this.response, this.data);
}

class ApiNetworkError extends Error {
  String message;
  DioError cause;

  ApiNetworkError(this.message, this.cause);

  ApiNetworkError.fromError(DioError cause) : this(cause.message, cause);

  @override
  String toString() {
    var data = '';
    if (cause.response?.statusCode == HttpStatus.badRequest) {
      data = cause?.response?.data;
    }
    return 'ApiNetworkError{$cause, $data}';
  }
}

class NativeService {
  NativeService._(MethodChannel channel)
      : _channel = channel;

  static final _instance = NativeService._(const MethodChannel('app.anlage.anlageappgame/SystemSetting'));

  static NativeService get instance => _instance;

  final MethodChannel _channel;

  Future<bool> isFirebaseTestLab() {
    if (!Platform.isAndroid) {
      return Future.value(false);
    }
    return _channel.invokeMethod('getString', {'name': 'firebase.test.lab'})
        .then((value) => value == 'true');
  }
}

class ApiService {

  final Env _env;
  final ApiCaller _apiCaller;
  final CloudMessagingUtil _cloudMessaging;

  final _loginState = BehaviorSubject<LoginState>();

  Uri _baseUri;
  get loginState => _loginState.stream;
  // Simple way to access the currently logged in user. Can always be null!!!
  LoginState get currentLoginState => _loginState.value;


  ApiService(this._env, this._apiCaller, this._cloudMessaging) {
    _baseUri = Uri.parse(_env.baseUrl);
    _loginState.onListen = () {
      _logger.fine('Somebody listening on loginState.');
    };
    _logger.fine('Creating new ApiService.');

    // some arbitrary time after staring up, request current status from the server.
    Future.delayed(Duration(seconds: 3)).then((x) async { await _updateUserInfo(); });
    _cloudMessaging.onTokenRefresh.listen((newToken) {
      _updateUserInfo();
    });
  }

  Future<void> _updateUserInfo({int retryCount = 0}) async {
    var deviceInfo;

    String testlabUserProperty;
    if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      deviceInfo = "${iosInfo.model},${iosInfo.name},${iosInfo.systemName},${iosInfo.systemVersion}";
    } else if (Platform.isAndroid) {
      final isTestLab = await NativeService.instance.isFirebaseTestLab();
      final testLab = (isTestLab) ? 'FIREBASE TESTLAB,' : '';
      if (isTestLab) {
        testlabUserProperty = 'firebase';
      }
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      deviceInfo = "$testLab${androidInfo.model},${androidInfo.brand},${androidInfo.device},${androidInfo.board},${androidInfo
          .manufacturer},${androidInfo.product},${androidInfo.version.baseOS},${androidInfo.version.release}";
    }
    if (testlabUserProperty == null) {
      switch (_env.type) {
        case EnvType.production:
          testlabUserProperty = null;
          break;
        case EnvType.development:
        // this is actually already set in analytics constructor.. but anyway.
          testlabUserProperty = 'env-development';
          break;
      }
    }
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = "${packageInfo.version} (${packageInfo.buildNumber}) ${packageInfo.packageName} ${packageInfo
        .appName}";
    _logger.finer('sending userinfo.');

    try {
      final userInfo = await this._apiCaller.post(UserInfoLocation(), UserInfoRequest(appVersion, deviceInfo, await _cloudMessaging.getToken()));
      final userTypeString = convertGameUserTypeToJson(userInfo.userType);
      await AnalyticsUtils.instance.analytics.setUserProperty(name: 'testlab', value: testlabUserProperty ?? 'prod');
      await AnalyticsUtils.instance.analytics.setUserProperty(name: 'user_type', value: testlabUserProperty == null ? userTypeString : testlabUserProperty + ':' + userTypeString);

      _loginState.add(LoginState(_baseUri, userInfo));
    } on DioError catch (error, stackTrace)  {
      if (_loginState.value == null) {
        _loginState.addError(error, stackTrace);
      }
      if (retryCount < 10) {
        final duration = 10 * (retryCount+1);
        _logger.warning('Error while updating user info. retrying in $duration seconds. Retries: $retryCount', error, stackTrace);
        // retry later in the background.. do not wait for the response.
        unawaited(Future.delayed(Duration(seconds: duration)).then((val) {
          _updateUserInfo(retryCount: retryCount - 1);
        }));
      }
    } catch (error, stackTrace) {
      _logger.severe('Error while updating user info', error, stackTrace);
      _loginState.addError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> triggerUpdateUserInfo() async {
    return await this._updateUserInfo();
  }





  Future<GameSimpleSetResponse> getSimpleGameSet() async {
    _logger.fine('Requesting simple game set.');
    return await _apiCaller.get(GameSimpleSetLocation());

//    var request = await _httpClient.getUrl(_baseUri.resolve("api/game/simpleGameSet"));
//    var response = await request.close();
//    response.read
  }

  Future<GameSimpleSetVerifyResponse> verifySimpleGameSet(String gameTurnId, List<GameSimpleSetGuessDto> guesses) async {
    final result = await _apiCaller.post(GameSimpleSetLocation(), GameSimpleSetVerifyRequest(gameTurnId, guesses));
    final state = _loginState.value;
    if (state == null) {
      // kick off user info update.. we don't care about the response..
      unawaited(this._updateUserInfo());
    } else {
      state.userInfo.statsCorrectAnswers = result.statsCorrectAnswers;
      state.userInfo.statsTotalTurns = result.statsTotalTurns;
      _loginState.add(state);
    }
    _logger.finer('Received answer with correctAnswers: ${result.statsCorrectAnswers} (now: ${result.correctCount})');
    return result;
  }

  String getImageUrl(InstrumentImageDto image) {
    return _baseUri.resolve('api/pricedata/image/${image.id}?noSVG=true').toString();
  }

  Future<UserInfoResponse> uploadAvatarImage(File image) async {
    final formData = FormData.from({"avatarImage": UploadFileInfo(image, basename(image.path))});
    final response = await _apiCaller.upload(UserInfoAvatarUpload(), formData);
    _loginState.add(LoginState(_baseUri, response.data));
    return response.data;
  }

  Future<UserInfoResponse> updateUserInfo({String displayName, String email}) async {
    final res = await _apiCaller.post(UserInfoUpdateLocation(), UserInfoUpdateRequest(displayName, email));
    _loginState.add(LoginState(_baseUri, res));
    return res;
  }

  Future<LeaderboardSimpleResponse> fetchLeaderboard() async {
    return await _apiCaller.get(LeaderboardSimpleLocation());
  }

  resolveUri(String relativeOrAbsoluteUrl) => _baseUri.resolve(relativeOrAbsoluteUrl).toString();
}