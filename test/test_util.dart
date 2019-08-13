import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' show join, dirname, basename;

final _logger = Logger('test_util');

class TestUtil {
  static Future<void> mockPathProvider() async {
    // Create a temporary directory.
    final directory = await Directory.systemTemp.createTemp('flutter_finalyzer_game_tmp');

    // Mock out the MethodChannel for the path_provider plugin.
    const MethodChannel('plugins.flutter.io/path_provider').setMockMethodCallHandler((MethodCall methodCall) async {
      // If you're getting the apps documents directory, return the path to the
      // temp directory on the test environment instead.
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        _logger.info('Using app directory $directory');
        return directory.path;
      }
      return null;
    });
  }

  static Future<File> testFilePath(String fileName) async {
    _logger.fine('dirname: ${dirname(Platform.script.toString())} (script: ${Platform.script})');
    final baseDir = basename(dirname(Platform.script.toString())) == 'test' ? '..' : '.';
    return File(join(baseDir, 'test', fileName));
  }

  static Future<void> writeTestFileJson(String fileName, Map<String, dynamic> jsonData) async {
    await testFilePath(fileName).then((file) => file.writeAsString(json.encode(jsonData)));
  }

  static Future<Map<String, dynamic>> readTestFileJson(String fileName) async {
    return json.decode(await (await testFilePath(fileName)).readAsString()) as Map<String, dynamic>;
  }

  static Future<void> expectJsonContent(String fileName, Map<String, dynamic> jsonData) async {
    final newFileName = fileName + '.new.json';
    final oldFileName = fileName + '.json';
    await writeTestFileJson(newFileName, jsonData);
    final newFile = await testFilePath(newFileName);
    final oldFile = await testFilePath(oldFileName);
    expect(await newFile.readAsString(), equals(await oldFile.readAsString()));
  }
}
