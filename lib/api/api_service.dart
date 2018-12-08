

import 'dart:io';

import 'package:anlage_app_game/api/dtos.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';

final _logger = new Logger("app.anlage.game.api.api_service");

class ApiService {
  static final ApiService instance = new ApiService();


  Env _env;
  Uri _baseUri;


  ApiService({Env env}) {
    this._env = env ?? Env.value;
    _baseUri = Uri.parse(_env.baseUrl);
  }

  Future<GameSimpleSetResponse> getSimpleGameSet() async {
    _logger.fine('Requesting simple game set. ${_baseUri.resolve("api/game/simpleGameSet")}');
    var dio = new Dio();
    var response = await dio.get(_baseUri.resolve("api/game/simpleGameSet").toString(), options: Options(responseType: ResponseType.JSON));
    return GameSimpleSetResponse.fromJson(response.data);

//    var request = await _httpClient.getUrl(_baseUri.resolve("api/game/simpleGameSet"));
//    var response = await request.close();
//    response.read
  }
}