// hand made dto :-) copied from kotlin code
// need to find a way to automate this..

class InstrumentImageDto {
  String id;
  String mimeType;

  InstrumentImageDto.fromJson(Map<String, dynamic> json) :
        id = json['id'] as String,
        mimeType = json['mimeType'] as String;
}

class SimpleGameDto {

  String instrumentKey;
  InstrumentImageDto logo;


  SimpleGameDto.fromJson(Map<String, dynamic> json) :
      instrumentKey = json['instrumentKey'],
      logo = InstrumentImageDto.fromJson(json['logo']);

}

class GameSimpleSetResponse {
  List<SimpleGameDto> simpleGame;
  double marketCapScaleMin;
  double marketCapScaleMax;

  GameSimpleSetResponse.fromJson(Map<String, dynamic> json)
      : simpleGame = (json['simpleGame'] as List<dynamic>).map((val) => SimpleGameDto.fromJson(val)).toList(),
        marketCapScaleMin = json['marketCapScaleMin'] as double,
        marketCapScaleMax = json['marketCapScaleMax'] as double;
  
}
