import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/data/company_info_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util.dart';

void main() {
  setUp(() async {
    await TestUtil.mockPathProvider();
  });
  test('serialize test', () async {
    final store = CompanyInfoStore();
    final data = await store.store.load();
    expect(data, isNotNull);
    expect(data.history, isEmpty);

    final exampleCompany = await _exampleCompanyInfo();
    final exampleLogo = await _exampleLogo();
    await store.update((b) => b
      ..history.add(HistoryGameSet(
        (hb) => hb
          ..turnId = '1'
          ..instruments.add('test')
          ..points = 0
          ..playAt = DateTime(2019, 1, 1).toUtc(),
      ))
      ..companyInfos['test'] = CompanyInfoWrapper(
        (cib) => cib
          ..details = exampleCompany
          ..logo = exampleLogo,
      ));

    await TestUtil.expectJsonContent('_sampledata/company_info_store', (await store.store.load()).toJson());
  });
  test('deserialize company_info_store', () async {
    final data = CompanyInfoData.fromJson(await TestUtil.readTestFileJson('_sampledata/company_info_store.json'));
    expect(data.history, hasLength(1));
  });
}

Future<CompanyInfoDetails> _exampleCompanyInfo() async =>
    CompanyInfoDetails.fromJson(await TestUtil.readTestFileJson('_sampledata/example_details.json'));
Future<InstrumentImageDto> _exampleLogo() async =>
    InstrumentImageDto.fromJson(await TestUtil.readTestFileJson('_sampledata/example_logo.json'));
