// lib/screens/entry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart'; // para poder borrar en Hive

import '../widgets/heart_with_patch_image.dart';

class EntryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const EntryDetailScreen({super.key, required this.entry});

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$d/$m/$y · $h:$min";
  }

  Future<void> _shareEntry() async {
    final emotion = entry['emotion'] ?? '';
    final action = entry['action'] ?? '';
    final notes = (entry['notes'] ?? '').toString().trim();
    final dt = DateTime.tryParse(entry['ts'] ?? '') ?? DateTime.now();

    final buffer = StringBuffer();
    buffer.writeln('Registro TeAyudo');
    buffer.writeln('================');
    buffer.writeln('Fecha: ${_fmt(dt)}');
    buffer.writeln('Estado: $emotion');
    buffer.writeln('Acción: $action');
    if (notes.isNotEmpty) {
      buffer.writeln('Notas: $notes');
    }

    await Share.share(
      buffer.toString(),
      subject: 'Registro TeAyudo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Colores que respetan el tema
    final Color scaffoldBg = theme.scaffoldBackgroundColor;
    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : cs.onSurface.withOpacity(0.7);
    const Color accentBlue = Color(0xFF78C1E0);

    // Fondo de la tarjeta
    final Color cardBg = isDark ? const Color(0xFF0D1A21) : Colors.white;

    final emotion = (entry['emotion'] ?? '').toString();
    final action = (entry['action'] ?? '').toString();
    final notes = (entry['notes'] ?? '').toString().trim();
    final dt = DateTime.tryParse(entry['ts'] ?? '') ?? DateTime.now();

    return Scaffold(
      // respeta modo claro/oscuro
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTextColor),

        // 🔥 AQUÍ ES DONDE CAMBIAMOS EL LAYOUT DEL TÍTULO
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HeartWithPatchImage(size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Detalle del registro',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        actions: [
          // compartir (igual que antes)
          IconButton(
            tooltip: 'Compartir este registro',
            icon: Icon(
              Icons.ios_share,
              color: primaryTextColor,
            ),
            onPressed: _shareEntry,
          ),
          // 🗑️ eliminar registro (igual que ya tenías)
          IconButton(
            tooltip: 'Eliminar este registro',
            icon: Icon(
              Icons.delete_outline,
              color: primaryTextColor,
            ),
            onPressed: () async {
              final key = entry['key'];

              // si no tenemos key, no intentamos borrar
              if (key == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo eliminar este registro (falta identificador).',
                      ),
                    ),
                  );
                }
                return;
              }

              final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar registro'),
                      content: const Text(
                        '¿Seguro que quieres eliminar este registro del historial?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (!ok) return;

              final box = Hive.box('entries');
              await box.delete(key);

              if (context.mounted) {
                Navigator.pop(context); // cerramos detalle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro eliminado'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              // borde celeste siempre
              side: const BorderSide(
                color: accentBlue,
                width: 1.4,
              ),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado de ánimo grande
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const HeartWithPatchImage(size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          emotion.isEmpty
                              ? 'Estado no especificado'
                              : emotion,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fmt(dt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 18),
                  Divider(
                    color: accentBlue.withOpacity(0.4),
                    thickness: 0.7,
                  ),

                  // Acción realizada
                  const SizedBox(height: 8),
                  Text(
                    'Acción realizada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            action.isEmpty
                                ? 'Sin acción registrada'
                                : action,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notas
                  const SizedBox(height: 18),
                  Text(
                    'Notas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (notes.isEmpty)
                    Text(
                      'No agregaste notas en este registro.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF10232C)
                            : const Color(0xFFEAF5FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notes,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primaryTextColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}






