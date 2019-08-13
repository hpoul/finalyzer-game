import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:anlage_app_game/api/api_caller.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/env/_base.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util.dart';

const endpoint = 'https://api.anlage.app/api';

class TestEnv extends Env {
  TestEnv() : super(EnvType.development);

  @override
  String get baseUrl => 'http://api.anlage.app';

  @override
  Color get primarySwatch => null;
}

class MemorySessionStore implements SessionStore {
  String _session;

  @override
  Future<String> loadSession() async => _session;

  @override
  Future<void> writeSession(String gameSession) async => _session = gameSession;
}

void main() {
  group('real api test', () {
    ApiCaller apiCaller;
    setUp(() {
      apiCaller = ApiCaller(TestEnv(), sessionStore: MemorySessionStore());
    });

    test('get simple game set', () async {
      final game = await apiCaller.get(GameSimpleSetLocation());
      expect(game.simpleGame, hasLength(4));
      final random = Random();
      final request = GameSimpleSetVerifyRequest(
        game.gameTurnId,
        game.simpleGame.map((dto) => GameSimpleSetGuessDto(dto.instrumentKey, 1000.0 + random.nextInt(10000))).toList(),
      );
      final response = await apiCaller.post(GameSimpleSetLocation(), request);
      expect(response.actual, hasLength(game.simpleGame.length));
//      print(json.encode(response.toJson()));
      await (await TestUtil.testFilePath('_sampledata/example_details.json'))
          .writeAsString(json.encode(response.details.first));
      await (await TestUtil.testFilePath('_sampledata/example_logo.json'))
          .writeAsString(json.encode(game.simpleGame.first.logo));
    });
  }, skip: 'run only manually');
}
