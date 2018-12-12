// hand made dto :-) copied from kotlin code
// need to find a way to automate this..

import 'package:meta/meta.dart';

class InstrumentImageDto {
  String id;
  String mimeType;

  InstrumentImageDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        mimeType = json['mimeType'] as String;
}

class SimpleGameDto {
  String instrumentKey;
  InstrumentImageDto logo;

  SimpleGameDto.fromJson(Map<String, dynamic> json)
      : instrumentKey = json['instrumentKey'],
        logo = InstrumentImageDto.fromJson(json['logo']);
}

class GameSimpleSetResponse {
  List<SimpleGameDto> simpleGame;
  String gameTurnId;
  double marketCapScaleMin;
  double marketCapScaleMax;

  GameSimpleSetResponse.fromJson(Map<String, dynamic> json)
      : simpleGame = (json['simpleGame'] as List<dynamic>).map((val) => SimpleGameDto.fromJson(val)).toList(),
        gameTurnId = json['gameTurnId'] as String,
        marketCapScaleMin = json['marketCapScaleMin'] as double,
        marketCapScaleMax = json['marketCapScaleMax'] as double;
}

class GameSimpleSetGuessDto {
  String instrumentKey;
  double marketCap;

  GameSimpleSetGuessDto(this.instrumentKey, this.marketCap);

  GameSimpleSetGuessDto.fromJson(Map<String, dynamic> json)
      : instrumentKey = json['instrumentKey'] as String,
        marketCap = json['marketCap'] as double;

  toJson() => {
        'instrumentKey': instrumentKey,
        'marketCap': marketCap,
      };
}

class GameSimpleSetVerifyRequest {
  String gameTurnId;
  List<GameSimpleSetGuessDto> guesses;

  GameSimpleSetVerifyRequest(this.gameTurnId, this.guesses);

  toJson() => {
        'gameTurnId': gameTurnId,
        'guesses': guesses.map((guess) => guess.toJson()).toList(),
      };
}

class GameSimpleSetVerifyResponse {
  List<GameSimpleSetGuessDto> actual;

  GameSimpleSetVerifyResponse.fromJson(Map<String, dynamic> data)
      : actual = (data['actual'] as List<dynamic>).map((a) => GameSimpleSetGuessDto.fromJson(a)).toList();
}

enum DevicePlatform {
  iOS,
  Android,
  Unknown
}

String _devicePlatformToString(DevicePlatform platform) {
  switch (platform) {
    case DevicePlatform.iOS: return 'iOS';
    case DevicePlatform.Android: return 'Android';
    case DevicePlatform.Unknown: return 'Unknown';
  }
  throw Exception('cannot happen. ever.');
}

class RegisterDeviceRequest {
  String osInfo;
  String deviceInfo;
  DevicePlatform platform;

  RegisterDeviceRequest({@required this.osInfo, @required this.deviceInfo, @required this.platform});

  toJson() => {
    'osInfo': osInfo,
    'deviceInfo': deviceInfo,
    'platform': _devicePlatformToString(platform),
  };
}



