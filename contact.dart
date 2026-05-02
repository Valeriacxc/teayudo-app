import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 7) // mismo ID que registras en main.dart
class Contact extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Teléfono SIEMPRE en formato internacional (+569…)
  @HiveField(2)
  String phoneIntl;

  /// Etiqueta opcional: "Mamá", "Psicólogo", etc.
  @HiveField(3)
  String? label;

  /// true = contacto de emergencia
  @HiveField(4)
  bool isEmergency;

  /// Fecha en que se creó el contacto
  @HiveField(5)
  DateTime createdAt;

  /// Notas opcionales (usadas en ContactEditScreen)
  @HiveField(6)
  String? notes;

  Contact({
    required this.id,
    required this.name,
    required this.phoneIntl,
    this.label,
    this.isEmergency = false,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();
}
