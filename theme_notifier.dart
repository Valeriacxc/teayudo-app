import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Clase que gestiona el tema de la app (claro / oscuro / sistema)
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeNotifier() {
    _loadFromHive();
  }

  /// Carga el modo de tema almacenado en Hive (si existe)
  void _loadFromHive() {
    final box = Hive.box('settings');
    final saved = box.get('theme', defaultValue: 'system') as String;
    _mode = _fromString(saved);
  }

  /// Cambia el modo de tema y guarda la preferencia
  void setLight() {
    _mode = ThemeMode.light;
    _saveToHive('light');
  }

  void setDark() {
    _mode = ThemeMode.dark;
    _saveToHive('dark');
  }

  void setSystem() {
    _mode = ThemeMode.system;
    _saveToHive('system');
  }

  /// Guarda la preferencia y notifica a la app
  void _saveToHive(String value) {
    final box = Hive.box('settings');
    box.put('theme', value);
    notifyListeners();
  }

  /// Convierte un String en ThemeMode
  ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}



