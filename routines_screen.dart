// lib/screens/routines_screen.dart 
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/store.dart';
import 'run_routine_screen.dart';
import '../widgets/app_logo_title.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});
  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  Future<void> _createRoutineDialog() async {
    final scheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController();

    // Tipos de pasos disponibles
    final steps = <String, bool>{
      'Respirar (4-2-6)': true, // default
      'Respirar (4-4)': false,
      'Respirar (3-3-3)': false,
      'Grounding 5-4-3-2-1': true,
      'Frase calmante': false,
    };

    String customPhrase = '';
    String? songPath;
    String? songLabel; // nombre amigable para mostrar

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Icon(
                    Icons.loop,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  // 👇 Esto evita el overflow amarillo
                  Expanded(
                    child: const Text(
                      'Nueva rutina (máx. 3 pasos)',
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de la rutina
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la rutina',
                        hintText: 'Ej: Respiración para momentos difíciles',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Título sección pasos
                    Text(
                      'Elige los pasos (máx. 3):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Caja de pasos
                    Card(
                      margin: EdgeInsets.zero,
                      color: scheme.surface.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            ...steps.keys.map(
                              (k) => CheckboxListTile(
                                value: steps[k]!,
                                title: Text(k),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (v) {
                                  setDialogState(() {
                                    steps[k] = v ?? false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Campo para frase calmante personalizada
                    if (steps['Frase calmante'] == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Tu frase calmante:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Escribe la frase que quieres recordar',
                          hintText:
                              'Ej: “Estoy a salvo, esto que siento va a pasar”.',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          setDialogState(() {
                            customPhrase = v;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    Divider(color: scheme.outline.withOpacity(0.5)),
                    const SizedBox(height: 8),

                    // Sección canción opcional
                    Text(
                      'Canción opcional:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Card(
                      margin: EdgeInsets.zero,
                      color: scheme.surface.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.music_note_outlined,
                          color: scheme.primary,
                        ),
                        title: Text(
                          songLabel ?? 'Agregar canción (opcional)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          songPath == null
                              ? 'Archivo de audio guardado en tu celular'
                              : 'Se reproducirá al iniciar la rutina',
                        ),
                        trailing: songPath != null
                            ? Icon(
                                Icons.check_circle,
                                color: scheme.primary,
                              )
                            : null,
                        onTap: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.audio,
                          );
                          if (res == null || res.files.single.path == null) {
                            return;
                          }
                          setDialogState(() {
                            songPath = res.files.single.path!;
                            songLabel = res.files.single.name;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final chosen =
        steps.entries.where((e) => e.value).map((e) => e.key).toList();
    final name = nameCtrl.text.trim();

    if (name.isEmpty || chosen.isEmpty || chosen.length > 3) {
      if (!mounted) return;

      final msg = name.isEmpty
          ? 'Ponle un nombre a la rutina'
          : (chosen.isEmpty
              ? 'Selecciona al menos un paso'
              : 'Máximo 3 pasos por rutina');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: scheme.errorContainer,
          content: Text(
            msg,
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    // Si el usuario seleccionó "Frase calmante", usamos la frase que escribió
    if (steps['Frase calmante'] == true) {
      final phrase = customPhrase.trim();
      if (phrase.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: scheme.errorContainer,
            content: Text(
              'Escribe tu frase calmante o desmarca esa opción',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        return;
      }
      // Reemplazamos el texto genérico por la frase personalizada
      chosen.remove('Frase calmante');
      chosen.add(phrase);
    }

    await Store.addRoutine(
      name,
      chosen,
      songPath: songPath,
    );

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rutina creada ✅')),
    );
  }

  Future<void> _runRoutine(Map<String, dynamic> routine) async {
    final steps = List<String>.from(routine['steps']);
    final name = routine['name'] as String;
    final songPath = routine['songPath'] as String?;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RunRoutineScreen(
          name: name,
          steps: steps,
          songPath: songPath,
        ),
      ),
    );

    await Store.addEntry(emotion: 'N/A', action: 'rutina:$name');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rutina "$name" registrada ✅')),
    );
  }

  Future<void> _confirmDelete(int index, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: Text('¿Eliminar "$name"?'),
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
    );
    if (ok == true) {
      await Store.removeRoutineAt(index);
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(subtitle: 'Rutinas preventivas'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRoutineDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Store.getRoutines(),
        builder: (context, snap) {
          final routines = snap.data ?? [];

          if (routines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crea tu primera rutina con el botón "Nueva".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _createRoutineDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear rutina'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = routines[i];
              final name = (r['name'] ?? '') as String;
              final steps = (r['steps'] as List).join(' • ');
              final hasSong = (r['songPath'] as String?) != null;

              return Card(
                color: scheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    hasSong ? '$steps\nIncluye canción 🎧' : steps,
                  ),
                  isThreeLine: hasSong,
                  onTap: () => _runRoutine(r),
                  trailing: IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(i, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}









