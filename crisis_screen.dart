// lib/screens/crisis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/contacts_provider.dart';
import '../data/models/contact.dart';
import '../data/store.dart'; // 👈 para leer rutinas y guardar entrada
import '../widgets/heart_with_patch_image.dart';
import 'contacts_screen.dart';
import 'help_box_screen.dart';
import 'run_routine_screen.dart'; // 👈 para ejecutar la rutina

class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  // ---------- LLAMAR TELÉFONO ----------
  Future<void> _callNumber(BuildContext context, String intlNumber) async {
    final uri = Uri.parse('tel:$intlNumber');
    if (!await canLaunchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el marcador')),
      );
      return;
    }
    await launchUrl(uri);
  }

  // ---------- SHEET: CONTACTOS ----------
  Future<void> _showContactsSheet(BuildContext context) async {
    final cp = context.read<ContactsProvider>();
    final emergencies = cp.emergencies;

    if (emergencies.isEmpty) {
      if (!context.mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sin contactos aún'),
          content: const Text(
            'Todavía no tienes contactos de emergencia guardados.\n\n'
            '¿Quieres ir a agregarlos ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ir a contactos'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ContactsScreen()),
        );
      }
      return;
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Elige a quién llamar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: emergencies.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final Contact c = emergencies[i];
                      final subtitle = [
                        if (c.label?.isNotEmpty == true) c.label,
                        c.phoneIntl,
                      ].join(' • ');

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor:
                            cs.surfaceContainerHighest.withOpacity(0.7),
                        leading: Icon(
                          Icons.phone_outlined,
                          color: cs.onSurface,
                        ),
                        title: Text(
                          c.name,
                          style: TextStyle(color: cs.onSurface),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // cerrar sheet
                          _callNumber(context, c.phoneIntl);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- SHEET: RUTINAS ----------
  Future<void> _runRoutineFromCrisis(
    BuildContext context,
    Map<String, dynamic> routine,
  ) async {
    final name = (routine['name'] ?? '') as String;
    final steps = List<String>.from(routine['steps'] ?? const <String>[]);

    if (name.isEmpty || steps.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RunRoutineScreen(name: name, steps: steps),
      ),
    );

    await Store.addEntry(emotion: 'N/A', action: 'rutina:$name');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rutina "$name" registrada ✅')),
    );
  }

  Future<void> _showRoutinesSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final routines = await Store.getRoutines();
    if (routines.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aún no tienes rutinas guardadas.'),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Elegir una de tus rutinas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: routines.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = routines[i];
                      final name = (r['name'] ?? '') as String;
                      final stepsList = (r['steps'] as List?) ?? const [];
                      final steps = stepsList.join(' • ');

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor:
                            cs.surfaceContainerHighest.withOpacity(0.7),
                        leading: Icon(
                          Icons.self_improvement,
                          color: cs.primary,
                        ),
                        title: Text(
                          name.isEmpty ? 'Rutina ${i + 1}' : name,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          steps,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _runRoutineFromCrisis(context, r);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- SHEET: RESPIRACIÓN ----------
  void _showBreathingSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.self_improvement, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Ejercicio de respiración 4-6',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Inhala por la nariz contando 4 segundos.\n'
                  '• Mantén el aire 2 segundos.\n'
                  '• Exhala lentamente por la boca contando 6 segundos.\n'
                  '• Repite el ciclo al menos 5 veces.\n\n'
                  'No tienes que hacerlo perfecto, solo trata de alargar la exhalación un poquito más que la inhalación.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Puedes cerrar esta ventana cuando quieras.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeartWithPatchImage(size: 26),
            const SizedBox(width: 8),
            Text(
              'Estoy en crisis',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Respira un momento',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Esta pantalla es para cuando te sientas muy mal.\n'
                'Puedes llamar rápido a alguien, usar tu caja de ayuda,\n'
                'hacer una de tus rutinas o un ejercicio de respiración.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 1) Botón: llamar a contacto
              FilledButton.icon(
                onPressed: () => _showContactsSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF78C1E0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.call),
                label: const Text(
                  'Llamar a mis contactos de emergencia',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // 2) Botón: caja de ayuda
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpBoxScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFF78C1E0)),
                  foregroundColor: cs.onSurface,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.inbox_outlined),
                label: const Text(
                  'Abrir mi caja de ayuda',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // 3) Botón: elegir rutina
              OutlinedButton.icon(
                onPressed: () => _showRoutinesSheet(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: cs.primary),
                  foregroundColor: cs.onSurface,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.self_improvement),
                label: const Text(
                  'Hacer una de mis rutinas',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // 4) Botón: respiración
              TextButton.icon(
                onPressed: () => _showBreathingSheet(context),
                icon: Icon(Icons.self_improvement, color: cs.onSurface),
                label: Text(
                  'Hacer un ejercicio de respiración',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                'Si estás en peligro inmediato, intenta llamar a los servicios de emergencia de tu país.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}






