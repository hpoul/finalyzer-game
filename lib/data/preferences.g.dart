// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (new Serializers().toBuilder()..add(Preferences.serializer)).build();
Serializer<Preferences> _$preferencesSerializer = new _$PreferencesSerializer();

class _$PreferencesSerializer implements StructuredSerializer<Preferences> {
  @override
  final Iterable<Type> types = const [Preferences, _$Preferences];
  @override
  final String wireName = 'Preferences';

  @override
  Iterable<Object> serialize(Serializers serializers, Preferences object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.askedForPushPermissionAt != null) {
      result
        ..add('askedForPushPermissionAt')
        ..add(serializers.serialize(object.askedForPushPermissionAt,
            specifiedType: const FullType(DateTime)));
    }
    return result;
  }

  @override
  Preferences deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PreferencesBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'askedForPushPermissionAt':
          result.askedForPushPermissionAt = serializers.deserialize(value,
              specifiedType: const FullType(DateTime)) as DateTime;
          break;
      }
    }

    return result.build();
  }
}

class _$Preferences extends Preferences {
  @override
  final DateTime askedForPushPermissionAt;

  factory _$Preferences([void Function(PreferencesBuilder) updates]) =>
      (new PreferencesBuilder()..update(updates)).build();

  _$Preferences._({this.askedForPushPermissionAt}) : super._();

  @override
  Preferences rebuild(void Function(PreferencesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PreferencesBuilder toBuilder() => new PreferencesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Preferences &&
        askedForPushPermissionAt == other.askedForPushPermissionAt;
  }

  @override
  int get hashCode {
    return $jf($jc(0, askedForPushPermissionAt.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Preferences')
          ..add('askedForPushPermissionAt', askedForPushPermissionAt))
        .toString();
  }
}

class PreferencesBuilder implements Builder<Preferences, PreferencesBuilder> {
  _$Preferences _$v;

  DateTime _askedForPushPermissionAt;
  DateTime get askedForPushPermissionAt => _$this._askedForPushPermissionAt;
  set askedForPushPermissionAt(DateTime askedForPushPermissionAt) =>
      _$this._askedForPushPermissionAt = askedForPushPermissionAt;

  PreferencesBuilder();

  PreferencesBuilder get _$this {
    if (_$v != null) {
      _askedForPushPermissionAt = _$v.askedForPushPermissionAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Preferences other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Preferences;
  }

  @override
  void update(void Function(PreferencesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Preferences build() {
    final _$result = _$v ??
        new _$Preferences._(askedForPushPermissionAt: askedForPushPermissionAt);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
