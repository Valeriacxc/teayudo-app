// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/theme_notifier.dart';
import '../data/backup.dart';
import '../widgets/app_logo_title.dart';
import '../data/user_prefs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final isDark = notifier.mode == ThemeMode.dark;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color surfaceContainerHi =
        (scheme as dynamic).surfaceContainerHighest ?? scheme.surfaceContainerHighest;

    final Color secondaryText =
        scheme.onSurface.withOpacity(0.7);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(subtitle: 'Ajustes'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          // ---- PERFIL / NOMBRE ----
          Text(
            'Tu perfil',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: surfaceContainerHi.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ValueListenableBuilder<Box>(
              valueListenable:
                  Hive.box('settings').listenable(keys: ['user_name']),
              builder: (_, box, __) {
                final current = (box.get('user_name') as String?)?.trim();
                final shown =
                    (current == null || current.isEmpty) ? 'Sin nombre' : current;
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Nombre del usuario'),
                  subtitle: Text(shown),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final ctrl = TextEditingController(text: current ?? '');
                    final newName = await showDialog<String?>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cambiar nombre'),
                        content: TextField(
                          controller: ctrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Tu nombre',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                          onSubmitted: (_) =>
                              Navigator.pop(context, ctrl.text),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, ctrl.text),
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    );
                    if (newName != null && newName.trim().isNotEmpty) {
                      final name = newName.trim();

                      // helper
                      await UserPrefs.setName(name);

                      // sincronizar ambas cajas
                      final settingsBox = Hive.box('settings');
                      final appBox = Hive.box('app');
                      await settingsBox.put('user_name', name);
                      await appBox.put('userName', name);

                      _toast(context, 'Nombre actualizado ✅');
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca el ícono de lápiz para cambiar el nombre que aparece en el inicio de la app.',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          // ---- PERSONALIZACIÓN ----
          Text(
            'Personalización',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: surfaceContainerHi.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              title: const Text('Modo oscuro real'),
              subtitle: const Text(
                'Activa el tema oscuro en toda la app, incluso si tu celular está en modo claro.',
              ),
              value: isDark,
              activeThumbColor: scheme.primary,
              onChanged: (v) => v ? notifier.setDark() : notifier.setLight(),
            ),
          ),

          const SizedBox(height: 24),

          // ---- RESPALDOS ----
          Text(
            'Respaldo de datos',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: surfaceContainerHi.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Exportar respaldo (.json)'),
                  subtitle: const Text(
                    'Guarda tus datos en un archivo para no perder tu información.',
                  ),
                  onTap: () async {
                    await BackupService.exportAll();
                    _toast(context, 'Respaldo exportado ✅');
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Importar respaldo (.json)'),
                  subtitle: const Text(
                    'Restaura tus datos desde un archivo de respaldo guardado antes.',
                  ),
                  onTap: () async {
                    final ok = await BackupService.importAll();
                    _toast(
                      context,
                      ok ? 'Respaldo importado ✅' : 'Archivo inválido ❌',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consejo: guarda tu archivo de respaldo en la nube (Drive, correo, etc.) por si cambias de celular.',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          // ---- ZONA DE PELIGRO ----
          Text(
            'Zona de peligro',
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Borrar todo'),
                  content: const Text(
                    'Se borrarán tu historial, rutinas, contactos y caja de ayuda.\n\n'
                    'Esta acción no se puede deshacer. ¿Quieres continuar?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await BackupService.wipeAll();
                _toast(context, 'Datos borrados ✅');
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Borrar todos los datos'),
          ),
          const SizedBox(height: 6),
          Text(
            'Usa esta opción solo si quieres empezar desde cero con la app.',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 30),
          const Center(
            child: Text(
              'Versión 1.0 • TeAyudo 💙',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}







