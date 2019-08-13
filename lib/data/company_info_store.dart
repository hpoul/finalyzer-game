import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:simple_json_persistence/simple_json_persistence.dart';

part 'company_info_store.g.dart';

abstract class CompanyInfoData implements Built<CompanyInfoData, CompanyInfoDataBuilder>, HasToJson {
  factory CompanyInfoData([void updates(CompanyInfoDataBuilder b)]) = _$CompanyInfoData;
  CompanyInfoData._();
  factory CompanyInfoData.fromJson(Map<String, dynamic> json) => CompanyInfoData(
        (b) => b
          ..companyInfos.addAll((json['companyInfos'] as Map<String, dynamic>).map(
            (k, dynamic v) => MapEntry(
              k,
              CompanyInfoWrapper.fromJson(v as Map<String, dynamic>),
            ),
          ))
          ..history.addAll((json['history'] as List<dynamic>)
              .map((dynamic history) => HistoryGameSet.fromJson(history as Map<String, dynamic>))),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'companyInfos': companyInfos.toMap(),
        'history': history.map((item) => item.toJson()).toList(growable: false),
      };

  BuiltMap<String, CompanyInfoWrapper> get companyInfos;
  BuiltList<HistoryGameSet> get history;
}

abstract class CompanyInfoWrapper implements Built<CompanyInfoWrapper, CompanyInfoWrapperBuilder> {
  factory CompanyInfoWrapper([void updates(CompanyInfoWrapperBuilder b)]) = _$CompanyInfoWrapper;
  CompanyInfoWrapper._();
  factory CompanyInfoWrapper.fromJson(Map<String, dynamic> json) => CompanyInfoWrapper(
        (b) => b
          ..details = CompanyInfoDetails.fromJson(json['details'] as Map<String, dynamic>)
          ..logo = InstrumentImageDto.fromJson(json['logo'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'details': details,
        'logo': logo,
      };

  CompanyInfoDetails get details;
  InstrumentImageDto get logo;
}

abstract class HistoryGameSet implements Built<HistoryGameSet, HistoryGameSetBuilder> {
  factory HistoryGameSet([void updates(HistoryGameSetBuilder b)]) = _$HistoryGameSet;
  HistoryGameSet._();
  factory HistoryGameSet.fromJson(Map<String, dynamic> json) => HistoryGameSet(
        (b) => b
          ..playAt = DateTime.fromMicrosecondsSinceEpoch(json['playAt'] as int, isUtc: true)
          ..instruments.addAll((json['instruments'] as List<dynamic>).map((dynamic key) => key as String))
          ..turnId = json['turnId'] as String
          ..points = json['points'] as int,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playAt': playAt.toUtc().millisecondsSinceEpoch,
        'instruments': instruments.toList(),
        'turnId': turnId,
        'points': points,
      };

  DateTime get playAt;
  BuiltSet<String> get instruments;
  String get turnId;
  int get points;
}

class CompanyInfoStore {
  final store = SimpleJsonPersistence<CompanyInfoData>.forType((json) => CompanyInfoData.fromJson(json),
      defaultCreator: () => CompanyInfoData());

  Future<CompanyInfoData> update(dynamic Function(CompanyInfoDataBuilder builder) updater) async {
    final newValue = (await store.load()).rebuild(updater);
    await store.save(newValue);
    return newValue;
  }
}
