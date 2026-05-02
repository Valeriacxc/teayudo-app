// lib/data/user_prefs.dart
import 'package:hive_flutter/hive_flutter.dart';

/// Clase simple para gestionar las preferencias del usuario.
/// Guarda cosas como el nombre, y en el futuro podrías añadir más (idioma, etc.)
class UserPrefs {
  static const String _boxName = 'settings';
  static const String _keyName = 'user_name';

  /// Guarda el nombre del usuario en Hive.
  static Future<void> setName(String name) async {
    final box = Hive.box(_boxName);
    await box.put(_keyName, name.trim());
  }

  /// Devuelve el nombre guardado, o null si aún no hay uno.
  static String? get name {
    final box = Hive.box(_boxName);
    final value = box.get(_keyName);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  /// Borra el nombre guardado (si el usuario quiere restablecerlo).
  static Future<void> clearName() async {
    final box = Hive.box(_boxName);
    await box.delete(_keyName);
  }
}

