// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_info_store.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CompanyInfoData extends CompanyInfoData {
  @override
  final BuiltMap<String, CompanyInfoWrapper> companyInfos;
  @override
  final BuiltList<HistoryGameSet> history;

  factory _$CompanyInfoData([void Function(CompanyInfoDataBuilder) updates]) =>
      (new CompanyInfoDataBuilder()..update(updates)).build();

  _$CompanyInfoData._({this.companyInfos, this.history}) : super._() {
    if (companyInfos == null) {
      throw new BuiltValueNullFieldError('CompanyInfoData', 'companyInfos');
    }
    if (history == null) {
      throw new BuiltValueNullFieldError('CompanyInfoData', 'history');
    }
  }

  @override
  CompanyInfoData rebuild(void Function(CompanyInfoDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CompanyInfoDataBuilder toBuilder() =>
      new CompanyInfoDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CompanyInfoData &&
        companyInfos == other.companyInfos &&
        history == other.history;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, companyInfos.hashCode), history.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CompanyInfoData')
          ..add('companyInfos', companyInfos)
          ..add('history', history))
        .toString();
  }
}

class CompanyInfoDataBuilder
    implements Builder<CompanyInfoData, CompanyInfoDataBuilder> {
  _$CompanyInfoData _$v;

  MapBuilder<String, CompanyInfoWrapper> _companyInfos;
  MapBuilder<String, CompanyInfoWrapper> get companyInfos =>
      _$this._companyInfos ??= new MapBuilder<String, CompanyInfoWrapper>();
  set companyInfos(MapBuilder<String, CompanyInfoWrapper> companyInfos) =>
      _$this._companyInfos = companyInfos;

  ListBuilder<HistoryGameSet> _history;
  ListBuilder<HistoryGameSet> get history =>
      _$this._history ??= new ListBuilder<HistoryGameSet>();
  set history(ListBuilder<HistoryGameSet> history) => _$this._history = history;

  CompanyInfoDataBuilder();

  CompanyInfoDataBuilder get _$this {
    if (_$v != null) {
      _companyInfos = _$v.companyInfos?.toBuilder();
      _history = _$v.history?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CompanyInfoData other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CompanyInfoData;
  }

  @override
  void update(void Function(CompanyInfoDataBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$CompanyInfoData build() {
    _$CompanyInfoData _$result;
    try {
      _$result = _$v ??
          new _$CompanyInfoData._(
              companyInfos: companyInfos.build(), history: history.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'companyInfos';
        companyInfos.build();
        _$failedField = 'history';
        history.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'CompanyInfoData', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$CompanyInfoWrapper extends CompanyInfoWrapper {
  @override
  final CompanyInfoDetails details;
  @override
  final InstrumentImageDto logo;

  factory _$CompanyInfoWrapper(
          [void Function(CompanyInfoWrapperBuilder) updates]) =>
      (new CompanyInfoWrapperBuilder()..update(updates)).build();

  _$CompanyInfoWrapper._({this.details, this.logo}) : super._() {
    if (details == null) {
      throw new BuiltValueNullFieldError('CompanyInfoWrapper', 'details');
    }
    if (logo == null) {
      throw new BuiltValueNullFieldError('CompanyInfoWrapper', 'logo');
    }
  }

  @override
  CompanyInfoWrapper rebuild(
          void Function(CompanyInfoWrapperBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CompanyInfoWrapperBuilder toBuilder() =>
      new CompanyInfoWrapperBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CompanyInfoWrapper &&
        details == other.details &&
        logo == other.logo;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, details.hashCode), logo.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CompanyInfoWrapper')
          ..add('details', details)
          ..add('logo', logo))
        .toString();
  }
}

class CompanyInfoWrapperBuilder
    implements Builder<CompanyInfoWrapper, CompanyInfoWrapperBuilder> {
  _$CompanyInfoWrapper _$v;

  CompanyInfoDetails _details;
  CompanyInfoDetails get details => _$this._details;
  set details(CompanyInfoDetails details) => _$this._details = details;

  InstrumentImageDto _logo;
  InstrumentImageDto get logo => _$this._logo;
  set logo(InstrumentImageDto logo) => _$this._logo = logo;

  CompanyInfoWrapperBuilder();

  CompanyInfoWrapperBuilder get _$this {
    if (_$v != null) {
      _details = _$v.details;
      _logo = _$v.logo;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CompanyInfoWrapper other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CompanyInfoWrapper;
  }

  @override
  void update(void Function(CompanyInfoWrapperBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$CompanyInfoWrapper build() {
    final _$result =
        _$v ?? new _$CompanyInfoWrapper._(details: details, logo: logo);
    replace(_$result);
    return _$result;
  }
}

class _$HistoryGameSet extends HistoryGameSet {
  @override
  final DateTime playAt;
  @override
  final BuiltSet<String> instruments;
  @override
  final String turnId;
  @override
  final int points;

  factory _$HistoryGameSet([void Function(HistoryGameSetBuilder) updates]) =>
      (new HistoryGameSetBuilder()..update(updates)).build();

  _$HistoryGameSet._({this.playAt, this.instruments, this.turnId, this.points})
      : super._() {
    if (playAt == null) {
      throw new BuiltValueNullFieldError('HistoryGameSet', 'playAt');
    }
    if (instruments == null) {
      throw new BuiltValueNullFieldError('HistoryGameSet', 'instruments');
    }
    if (turnId == null) {
      throw new BuiltValueNullFieldError('HistoryGameSet', 'turnId');
    }
    if (points == null) {
      throw new BuiltValueNullFieldError('HistoryGameSet', 'points');
    }
  }

  @override
  HistoryGameSet rebuild(void Function(HistoryGameSetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HistoryGameSetBuilder toBuilder() =>
      new HistoryGameSetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HistoryGameSet &&
        playAt == other.playAt &&
        instruments == other.instruments &&
        turnId == other.turnId &&
        points == other.points;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, playAt.hashCode), instruments.hashCode),
            turnId.hashCode),
        points.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('HistoryGameSet')
          ..add('playAt', playAt)
          ..add('instruments', instruments)
          ..add('turnId', turnId)
          ..add('points', points))
        .toString();
  }
}

class HistoryGameSetBuilder
    implements Builder<HistoryGameSet, HistoryGameSetBuilder> {
  _$HistoryGameSet _$v;

  DateTime _playAt;
  DateTime get playAt => _$this._playAt;
  set playAt(DateTime playAt) => _$this._playAt = playAt;

  SetBuilder<String> _instruments;
  SetBuilder<String> get instruments =>
      _$this._instruments ??= new SetBuilder<String>();
  set instruments(SetBuilder<String> instruments) =>
      _$this._instruments = instruments;

  String _turnId;
  String get turnId => _$this._turnId;
  set turnId(String turnId) => _$this._turnId = turnId;

  int _points;
  int get points => _$this._points;
  set points(int points) => _$this._points = points;

  HistoryGameSetBuilder();

  HistoryGameSetBuilder get _$this {
    if (_$v != null) {
      _playAt = _$v.playAt;
      _instruments = _$v.instruments?.toBuilder();
      _turnId = _$v.turnId;
      _points = _$v.points;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HistoryGameSet other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$HistoryGameSet;
  }

  @override
  void update(void Function(HistoryGameSetBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$HistoryGameSet build() {
    _$HistoryGameSet _$result;
    try {
      _$result = _$v ??
          new _$HistoryGameSet._(
              playAt: playAt,
              instruments: instruments.build(),
              turnId: turnId,
              points: points);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'instruments';
        instruments.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'HistoryGameSet', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
