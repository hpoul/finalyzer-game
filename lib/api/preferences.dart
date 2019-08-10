import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger('app.anlage.game.api.preferences');

abstract class _Preference<T> {
  final String name;

  const _Preference(this.name);

  Future<T> get(SharedPreferences prefs);

  Future<bool> set(SharedPreferences prefs, T value);
}

// ignore: unused_element
class _StringPreference extends _Preference<String> {
  const _StringPreference(String name) : super(name);

  @override
  Future<String> get(SharedPreferences prefs) {
    return Future.value(prefs.getString(name));
  }

  @override
  Future<bool> set(SharedPreferences prefs, value) {
    return prefs.setString(name, value);
  }
}

class _BoolPreference extends _Preference<bool> {
  const _BoolPreference(String name) : super(name);

  @override
  Future<bool> get(SharedPreferences prefs) {
    final dynamic val = prefs.get(name);
    _logger.fine('Value for $name = $val');
    return Future.value(val is bool && val);
  }

  @override
  Future<bool> set(SharedPreferences prefs, bool value) {
    return prefs.setBool(name, value);
  }
}

class Preferences {
  static const askedForPushPermission = _BoolPreference("asked_for_push");

  const Preferences();
}

class PreferenceStore {
  const PreferenceStore();

  Future<T> getValue<T>(_Preference<T> pref) {
    return SharedPreferences.getInstance().then((prefs) => pref.get(prefs));
  }

  Future<bool> setValue<T>(_Preference<T> pref, T value) {
    return SharedPreferences.getInstance().then((prefs) => pref.set(prefs, value));
  }
}
