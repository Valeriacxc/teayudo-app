import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  /// Exporta todas las cajas a un JSON y ofrece compartir el archivo.
  static Future<void> exportAll() async {
    final entries = Hive.box('entries').values.toList();
    final routines = Hive.box('routines').values.toList();
    final contacts = Hive.box('contacts').values.toList();

    final payload = {
      'version': 1,
      'generatedAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'routines': routines,
      'contacts': contacts,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/teayudo_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr, flush: true);

    await Share.shareXFiles([XFile(file.path)], text: 'Respaldo TeAyudo');
  }

  /// Importa un archivo .json y restaura las cajas.
  static Future<bool> importAll() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final text = await file.readAsString();
    final data = jsonDecode(text) as Map;

    // Validación simple
    if (!data.containsKey('entries') || !data.containsKey('routines') || !data.containsKey('contacts')) {
      return false;
    }

    final entriesBox = Hive.box('entries');
    final routinesBox = Hive.box('routines');
    final contactsBox = Hive.box('contacts');

    await entriesBox.clear();
    await routinesBox.clear();
    await contactsBox.clear();

    for (final e in (data['entries'] as List)) {
      await entriesBox.add(Map<String, dynamic>.from((e as Map).cast<String, dynamic>()));
    }
    for (final r in (data['routines'] as List)) {
      await routinesBox.add(Map<String, dynamic>.from((r as Map).cast<String, dynamic>()));
    }
    for (final c in (data['contacts'] as List)) {
      await contactsBox.add(Map<String, String>.from((c as Map).cast<String, String>()));
    }

    return true;
  }

  /// Borra todas las cajas (con confirmación desde UI).
  static Future<void> wipeAll() async {
    await Hive.box('entries').clear();
    await Hive.box('routines').clear();
    await Hive.box('contacts').clear();
  }
}
