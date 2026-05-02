// lib/data/contacts_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'models/contact.dart';

class ContactsProvider extends ChangeNotifier {
  final Box<Contact> _box;
  final Uuid _uuid = const Uuid();

  ContactsProvider(this._box);

  /// Lista ordenada por fecha de creación (más nuevos primero)
  List<Contact> get all {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Solo los contactos marcados como emergencia
  List<Contact> get emergencies => all.where((c) => c.isEmergency).toList();

  Future<void> add({
    required String name,
    required String phoneIntl,
    String? label,
    bool isEmergency = false,
    String? notes,
  }) async {
    final trimmedLabel = label?.trim();
    final trimmedNotes = notes?.trim();

    final c = Contact(
      id: _uuid.v4(),
      name: name.trim(),
      phoneIntl: phoneIntl.trim(),
      label: (trimmedLabel == null || trimmedLabel.isEmpty) ? null : trimmedLabel,
      isEmergency: isEmergency,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
    );

    await _box.put(c.id, c);
    notifyListeners();
  }

  Future<void> update(Contact c) async {
    await _box.put(c.id, c);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}


