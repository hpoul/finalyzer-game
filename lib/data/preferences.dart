import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_json_persistence/simple_json_persistence.dart';

part 'preferences.g.dart';

final _logger = Logger('app.anlage.game.api.preferences');

abstract class Preferences implements Built<Preferences, PreferencesBuilder>, HasToJson {
  factory Preferences([void updates(PreferencesBuilder b)]) = _$Preferences;
  Preferences._();
  static Serializer<Preferences> get serializer => _$preferencesSerializer;

  @override
  Map<String, dynamic> toJson() => serializers.serialize(this) as Map<String, dynamic>;

  @nullable
  DateTime get askedForPushPermissionAt;
}

@SerializersFor([
  Preferences,
])
Serializers serializers = (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

//class Preferences {
//  const Preferences();
//  static const askedForPushPermission = _BoolPreference('asked_for_push');
//}

class PreferenceStore {
  PreferenceStore() {
    Future<void>.delayed(const Duration(seconds: 3)).then((_) => _migrateOldData());
  }

  final store = SimpleJsonPersistence<Preferences>.forType(
      (json) => serializers.deserializeWith(Preferences.serializer, json),
      defaultCreator: () => Preferences());

  Future<void> _migrateOldData() async {
    // we previously used shared preferences with only a single option, let's migrate it.
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('asked_for_push');
    if (value != null) {
      await update((b) => b..askedForPushPermissionAt = DateTime.now().toUtc());
      await prefs.remove('asked_for_push');
      _logger.info('Migrated asked_for_push ($value)');
    }
  }

  Future<Preferences> update(dynamic Function(PreferencesBuilder builder) updater) async {
    final newValue = (await store.load()).rebuild(updater);
    await store.save(newValue);
    return newValue;
  }
}
