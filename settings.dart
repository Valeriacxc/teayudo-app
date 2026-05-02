import 'package:hive_flutter/hive_flutter.dart';

class Settings {
  static final _box = Hive.box('settings');

  static bool isDark() => _box.get('darkMode', defaultValue: false) as bool;
  static Future<void> setDark(bool v) => _box.put('darkMode', v);

  static bool welcomeSeen() => _box.get('welcomeSeen', defaultValue: false) as bool;
  static Future<void> setWelcomeSeen() => _box.put('welcomeSeen', true);
}
