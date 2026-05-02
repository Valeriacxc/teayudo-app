// lib/data/store.dart
import 'package:hive_flutter/hive_flutter.dart';

class Store {
  static final _entries  = Hive.box('entries');
  static final _routines = Hive.box('routines');
  static final _contacts = Hive.box('contacts');
  static final _settings = Hive.box('settings'); // nombre, tema, etc.
  static final _app      = Hive.box('app');      // flags (tips_done, etc.)

  // ======== Perfil / UX ========
  static String? getUserName() => _settings.get('user_name') as String?;
  static Future<void> setUserName(String name) async =>
      _settings.put('user_name', name.trim());

  static bool getTipsDone() => (_app.get('tips_done') as bool?) ?? false;
  static Future<void> setTipsDone(bool v) async => _app.put('tips_done', v);

  // ======== ENTRIES (emociones/acciones/diario) ========
  /// Ahora cada entrada viene con un campo especial '_key'
  /// que es la clave real de Hive para poder editar / borrar.
  static Future<List<Map<String, dynamic>>> getEntries() async {
    final List<Map<String, dynamic>> out = [];

    for (final key in _entries.keys) {
      final raw = _entries.get(key);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(
          raw.cast<String, dynamic>(),
        );
        map['_key'] = key; // 👈 ESTA ES LA CLAVE QUE USAN EL HISTORIAL Y EL EDITAR
        out.add(map);
      }
    }

    return out;
  }

  /// notes es opcional (para la descripción libre)
  static Future<void> addEntry({
    required String emotion,
    required String action,
    String? notes,
  }) async {
    await _entries.add({
      'ts': DateTime.now().toIso8601String(),
      'emotion': emotion,
      'action': action,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  /// 👉 actualizar sólo las notas de una entrada usando la key de Hive
  static Future<void> updateEntryNotes(dynamic key, String newNotes) async {
    if (!_entries.containsKey(key)) return;

    final raw = _entries.get(key);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(
        raw.cast<String, dynamic>(),
      );

      final cleaned = newNotes.trim();
      if (cleaned.isEmpty) {
        // si queda vacío, borramos el campo notes
        map.remove('notes');
      } else {
        map['notes'] = cleaned;
      }

      await _entries.put(key, map);
    }
  }

  /// 👉 eliminar una entrada específica del historial por key
  static Future<void> deleteEntryByKey(dynamic key) async {
    if (!_entries.containsKey(key)) return;
    await _entries.delete(key);
  }

  // ======== RUTINAS ========
  static Future<List<Map<String, dynamic>>> getRoutines() async {
    return _routines.values
        .map(
          (e) => Map<String, dynamic>.from(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  /// Ahora la rutina puede tener una canción opcional (songPath)
  static Future<void> addRoutine(
    String name,
    List<String> steps, {
    String? songPath,
  }) async {
    final map = <String, dynamic>{
      'name': name,
      'steps': steps,
    };

    if (songPath != null && songPath.trim().isNotEmpty) {
      map['songPath'] = songPath.trim();
    }

    await _routines.add(map);
  }

  static Future<void> saveRoutines(List<Map<String, dynamic>> routines) async {
    await _routines.clear();
    for (final r in routines) {
      await _routines.add(r);
    }
  }

  static Future<void> removeRoutineAt(int index) async {
    if (index < 0 || index >= _routines.length) return;
    final key = _routines.keyAt(index);
    await _routines.delete(key);
  }

  // ======== CONTACTOS (máx. 3) ========
  static Future<List<Map<String, String>>> getContacts() async {
    return _contacts.values
        .map(
          (e) => Map<String, String>.from(
            (e as Map).cast<String, String>(),
          ),
        )
        .toList();
  }

  static Future<void> addContact(String name, String phone) async {
    final list = await getContacts();
    if (list.length >= 3) return;
    await _contacts.add({'name': name, 'phone': phone});
  }

  static Future<void> removeContactAt(int index) async {
    if (index < 0 || index >= _contacts.length) return;
    final key = _contacts.keyAt(index);
    await _contacts.delete(key);
  }
}





