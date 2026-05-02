import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../widgets/app_logo_title.dart';

class HelpBoxScreen extends StatefulWidget {
  const HelpBoxScreen({super.key});
  @override
  State<HelpBoxScreen> createState() => _HelpBoxScreenState();
}

class _HelpBoxScreenState extends State<HelpBoxScreen> {
  late final Box _box;

  bool _isGridView = false; // 👈 para cambiar entre lista y galería

  @override
  void initState() {
    super.initState();
    _box = Hive.box('helpbox');
  }

  // Copia el archivo a la carpeta de la app para asegurar acceso futuro
  Future<File> _copyToAppDir(File f) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/helpbox');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final newPath =
        '${folder.path}/${DateTime.now().millisecondsSinceEpoch}_${f.path.split(Platform.pathSeparator).last}';
    return f.copy(newPath);
  }

  Future<void> _addText() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final Color primaryText =
                isDark ? Colors.white : const Color(0xFF222222);
            final Color secondaryText =
                isDark ? Colors.white70 : const Color(0xFF4A5A68);

            return AlertDialog(
              backgroundColor:
                  isDark ? const Color(0xFF1F2A33) : Colors.white,
              title: Text(
                'Nuevo mensaje',
                style: TextStyle(color: primaryText),
              ),
              content: TextField(
                controller: ctrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Escribe algo que te ayude cuando lo necesites…',
                  hintStyle: TextStyle(color: secondaryText),
                  border: const OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: secondaryText),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || ctrl.text.trim().isEmpty) return;

    await _box.add({
      'type': 'text',
      'text': ctrl.text.trim(),
      'ts': DateTime.now().toIso8601String(),
    });
    if (mounted) setState(() {});
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1800);
    if (x == null) return;
    final f = await _copyToAppDir(File(x.path));
    await _box.add({
      'type': 'image',
      'path': f.path,
      'ts': DateTime.now().toIso8601String(),
    });
    if (mounted) setState(() {});
  }

  Future<void> _addAudio() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res == null || res.files.single.path == null) return;
    final f = await _copyToAppDir(File(res.files.single.path!));
    await _box.add({
      'type': 'audio',
      'path': f.path,
      'ts': DateTime.now().toIso8601String(),
    });
    if (mounted) setState(() {});
  }

  // 👇 NUEVO: agregar video
  Future<void> _addVideo() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video);
    if (res == null || res.files.single.path == null) return;
    final f = await _copyToAppDir(File(res.files.single.path!));
    await _box.add({
      'type': 'video',
      'path': f.path,
      'ts': DateTime.now().toIso8601String(),
    });
    if (mounted) setState(() {});
  }

  Future<void> _removeAt(int index) async {
    final key = _box.keyAt(index);
    final item = _box.get(key) as Map;

    // Si es archivo, borrarlo también del almacenamiento
    final rawPath = item['path'];
    if (rawPath is String && rawPath.isNotEmpty) {
      final file = File(rawPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    await _box.delete(key);
    if (mounted) setState(() {});
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF222222);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF4A5A68);
    final Color tileColor =
        isDark ? const Color(0xFF1F2A33) : const Color(0xFFE3F3FB);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const AppLogoTitle(),
        actions: [
          IconButton(
            tooltip: _isGridView ? 'Ver en lista' : 'Ver en cuadrícula',
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: scheme.primary,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: Icon(
          Icons.add,
          color: scheme.primary,
        ),
        tooltip: 'Agregar a Mi caja de ayuda',
        onSelected: (opt) {
          if (opt == 'text') _addText();
          if (opt == 'image') _addImage();
          if (opt == 'audio') _addAudio();
          if (opt == 'video') _addVideo(); // 👈 nuevo
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'text', child: Text('Agregar texto')),
          PopupMenuItem(value: 'image', child: Text('Agregar imagen')),
          PopupMenuItem(value: 'audio', child: Text('Agregar audio')),
          PopupMenuItem(value: 'video', child: Text('Agregar video')),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo de pantalla
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Mi caja de ayuda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              // 👇 Ahora incluye videos también
              'Guarda mensajes, imágenes, audios o videos que te calman o acompañan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(height: 4),

          // Contenido
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (_, Box box, __) {
                final items = box.values.toList().cast<Map>();

                // 👇 Ordenar por fecha (ts) de más reciente a más antiguo
                items.sort((a, b) {
                  final ta = DateTime.tryParse((a['ts'] ?? '') as String? ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final tb = DateTime.tryParse((b['ts'] ?? '') as String? ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return tb.compareTo(ta);
                });

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aún no tienes elementos.\nToca el botón + para agregar texto, una imagen, un audio o un video.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // ====== MODO LISTA ======
                if (!_isGridView) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final type = (it['type'] as String?) ?? 'text';

                      Widget leading;
                      String title;
                      VoidCallback? onTap;

                      if (type == 'text') {
                        leading = CircleAvatar(
                          backgroundColor:
                              isDark ? const Color(0xFF111822) : Colors.white,
                          child: Icon(
                            Icons.notes,
                            color: scheme.primary,
                          ),
                        );
                        title = (it['text'] as String? ?? '').trim();
                        onTap = () => showDialog(
                              context: context,
                              builder: (_) {
                                final dialogTheme = Theme.of(context);
                                final dark =
                                    dialogTheme.brightness == Brightness.dark;
                                final Color dlgPrimary =
                                    dark ? Colors.white : const Color(0xFF222222);

                                return AlertDialog(
                                  backgroundColor: dark
                                      ? const Color(0xFF1F2A33)
                                      : Colors.white,
                                  title: Text(
                                    'Mensaje',
                                    style: TextStyle(color: dlgPrimary),
                                  ),
                                  content: Text(
                                    title.isEmpty ? '(vacío)' : title,
                                    style: TextStyle(color: dlgPrimary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: Text(
                                        'Cerrar',
                                        style: TextStyle(color: dlgPrimary),
                                      ),
                                    )
                                  ],
                                );
                              },
                            );
                      } else if (type == 'image') {
                        final p = it['path'] as String? ?? '';
                        final exists =
                            p.isNotEmpty && File(p).existsSync();
                        leading = exists
                            ? CircleAvatar(
                                backgroundImage: FileImage(File(p)),
                              )
                            : CircleAvatar(
                                backgroundColor: isDark
                                    ? const Color(0xFF111822)
                                    : Colors.white,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: scheme.primary,
                                ),
                              );
                        title = 'Imagen';

                        onTap = () async {
                          if (p.isEmpty || !await File(p).exists()) {
                            _snack('Archivo no encontrado');
                            return;
                          }
                          if (!mounted) return;
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              child: InteractiveViewer(
                                child: Image.file(File(p)),
                              ),
                            ),
                          );
                        };
                      } else if (type == 'video') {
                        final p = it['path'] as String? ?? '';
                        leading = CircleAvatar(
                          backgroundColor:
                              isDark ? const Color(0xFF111822) : Colors.white,
                          child: Icon(
                            Icons.videocam,
                            color: scheme.primary,
                          ),
                        );
                        title = 'Video';

                        onTap = () async {
                          if (p.isEmpty || !await File(p).exists()) {
                            _snack('Archivo no encontrado');
                            return;
                          }
                          await OpenFilex.open(p);
                        };
                      } else {
                        // audio
                        final p = it['path'] as String? ?? '';
                        leading = CircleAvatar(
                          backgroundColor:
                              isDark ? const Color(0xFF111822) : Colors.white,
                          child: Icon(
                            Icons.audiotrack,
                            color: scheme.primary,
                          ),
                        );
                        title = 'Audio';

                        onTap = () async {
                          if (p.isEmpty || !await File(p).exists()) {
                            _snack('Archivo no encontrado');
                            return;
                          }
                          await OpenFilex.open(p);
                        };
                      }

                      return ListTile(
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: leading,
                        title: Text(
                          title.isEmpty ? '(sin texto)' : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: primaryTextColor),
                        ),
                        trailing: IconButton(
                          tooltip: 'Eliminar',
                          icon: Icon(
                            Icons.delete_outline,
                            color: primaryTextColor,
                          ),
                          onPressed: () => _removeAt(i),
                        ),
                        onTap: onTap,
                      );
                    },
                  );
                }

                // ====== MODO GALERÍA (CUADRÍCULA) ======
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final type = (it['type'] as String?) ?? 'text';

                    String title;
                    Widget preview;
                    VoidCallback? onTap;

                    if (type == 'image') {
                      final p = it['path'] as String? ?? '';
                      final exists =
                          p.isNotEmpty && File(p).existsSync();
                      if (exists) {
                        preview = ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(p),
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        );
                      } else {
                        preview = Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: scheme.primary,
                        );
                      }
                      title = 'Imagen';
                      onTap = () async {
                        if (p.isEmpty || !await File(p).exists()) {
                          _snack('Archivo no encontrado');
                          return;
                        }
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: const EdgeInsets.all(16),
                            child: InteractiveViewer(
                              child: Image.file(File(p)),
                            ),
                          ),
                        );
                      };
                    } else if (type == 'text') {
                      title = 'Texto';
                      final txt = (it['text'] as String? ?? '').trim();
                      preview = Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            txt.isEmpty ? '(vacío)' : txt,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 14,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                      onTap = () => showDialog(
                            context: context,
                            builder: (_) {
                              final dialogTheme = Theme.of(context);
                              final dark =
                                  dialogTheme.brightness == Brightness.dark;
                              final Color dlgPrimary =
                                  dark ? Colors.white : const Color(0xFF222222);

                              return AlertDialog(
                                backgroundColor: dark
                                    ? const Color(0xFF1F2A33)
                                    : Colors.white,
                                title: Text(
                                  'Mensaje',
                                  style: TextStyle(color: dlgPrimary),
                                ),
                                content: Text(
                                  txt.isEmpty ? '(vacío)' : txt,
                                  style: TextStyle(color: dlgPrimary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: Text(
                                      'Cerrar',
                                      style: TextStyle(color: dlgPrimary),
                                    ),
                                  )
                                ],
                              );
                            },
                          );
                    } else if (type == 'video') {
                      final p = it['path'] as String? ?? '';
                      title = 'Video';
                      preview = Icon(
                        Icons.videocam,
                        size: 40,
                        color: scheme.primary,
                      );
                      onTap = () async {
                        if (p.isEmpty || !await File(p).exists()) {
                          _snack('Archivo no encontrado');
                          return;
                        }
                        await OpenFilex.open(p);
                      };
                    } else {
                      final p = it['path'] as String? ?? '';
                      title = 'Audio';
                      preview = Icon(
                        Icons.audiotrack,
                        size: 40,
                        color: scheme.primary,
                      );
                      onTap = () async {
                        if (p.isEmpty || !await File(p).exists()) {
                          _snack('Archivo no encontrado');
                          return;
                        }
                        await OpenFilex.open(p);
                      };
                    }

                    return InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: preview,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: primaryTextColor,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeAt(i),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}





