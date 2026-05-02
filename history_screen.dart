// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import 'entry_detail_screen.dart';
import '../widgets/heart_with_patch_image.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _futureEntries;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  String? _emotionFilter; // null = todos
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _futureEntries = Store.getEntries();
    _searchCtrl.addListener(() {
      setState(() {
        _searchText = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$d/$m/$y · $h:$min";
  }

  Color _emotionColor(BuildContext context, String? emotionRaw) {
    final emotion = (emotionRaw ?? '').toLowerCase();
    final cs = Theme.of(context).colorScheme;

    if (emotion.contains('calm') || emotion.contains('tranq')) {
      return cs.tertiary.withOpacity(0.9);
    }
    if (emotion.contains('ans') || emotion.contains('panic')) {
      return Colors.orange.shade400;
    }
    if (emotion.contains('trist') || emotion.contains('down')) {
      return Colors.blueGrey.shade400;
    }
    if (emotion.contains('eno') || emotion.contains('rab')) {
      return Colors.red.shade400;
    }
    return cs.primary.withOpacity(0.85);
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> entries,
  ) {
    var result = List<Map<String, dynamic>>.from(entries);

    // Filtro por texto
    if (_searchText.isNotEmpty) {
      result = result.where((e) {
        final emotion = (e['emotion'] ?? '').toString().toLowerCase();
        final action = (e['action'] ?? '').toString().toLowerCase();
        final notes = (e['notes'] ?? '').toString().toLowerCase();
        return emotion.contains(_searchText) ||
            action.contains(_searchText) ||
            notes.contains(_searchText);
      }).toList();
    }

    // Filtro por emoción
    if (_emotionFilter != null && _emotionFilter!.isNotEmpty) {
      final filterLower = _emotionFilter!.toLowerCase();
      result = result.where((e) {
        final emotion = (e['emotion'] ?? '').toString().toLowerCase();
        return emotion == filterLower;
      }).toList();
    }

    // Filtro por rango de fechas
    if (_dateRange != null) {
      result = result.where((e) {
        final dt = DateTime.tryParse(e['ts'] ?? '');
        if (dt == null) return false;
        return dt.isAfter(
              _dateRange!.start.subtract(const Duration(seconds: 1)),
            ) &&
            dt.isBefore(
              _dateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return result;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialFirst =
        _dateRange?.start ?? now.subtract(const Duration(days: 7));
    final initialLast = _dateRange?.end ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialFirst, end: initialLast),
      helpText: 'Selecciona un rango de fechas',
      locale: const Locale('es', 'CL'),
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
    });
  }

  Future<void> _exportEntries(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para exportar')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Historial TeAyudo');
    buffer.writeln('=================');
    buffer.writeln('');

    for (final e in list) {
      final dt = DateTime.tryParse(e['ts'] ?? '') ?? DateTime.now();
      final emotion = e['emotion'] ?? '';
      final action = e['action'] ?? '';
      final notes = (e['notes'] ?? '').toString().trim();

      buffer.writeln('Fecha: ${_fmt(dt)}');
      buffer.writeln('Estado: $emotion');
      buffer.writeln('Acción: $action');
      if (notes.isNotEmpty) {
        buffer.writeln('Notas: $notes');
      }
      buffer.writeln('--------------------------');
    }

    await Share.share(
      buffer.toString(),
      subject: 'Historial TeAyudo',
    );
  }

  Future<void> _refreshEntries() async {
    setState(() {
      _futureEntries = Store.getEntries();
    });
  }

  Future<void> _editEntryNotes(Map<String, dynamic> entry) async {
    final key = entry['_key'];
    final currentNotes = (entry['notes'] ?? '').toString();
    final controller = TextEditingController(text: currentNotes);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar notas'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Notas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await Store.updateEntryNotes(key, controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada actualizada ✅')),
      );
      await _refreshEntries();
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final key = entry['_key'];

    final confirm = await showDialog<bool>(
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Store.deleteEntryByKey(key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado ✅')),
      );
      await _refreshEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores adaptados a modo claro/oscuro
    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : Colors.black.withOpacity(0.65);
    final Color cardColor =
        isDark ? const Color(0xFF1F2A33) : const Color(0xFFEAF5FB);
    final Color avatarBg =
        isDark ? Colors.black : Colors.white;
    final Color searchFill =
        isDark ? const Color(0xFF111822) : const Color(0xFFF5F9FC);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeartWithPatchImage(size: 24),
            const SizedBox(width: 8),
            Text(
              'Historial',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEntries,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final originalList = snap.data ?? [];
          if (originalList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Aún no tienes registros.\nCuando guardes uno, aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          final filtered = _applyFilters(originalList);

          final emotions = originalList
              .map((e) => (e['emotion'] ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              // 🔍 BUSCADOR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar por emoción, acción o notas',
                    hintStyle: TextStyle(
                      color: secondaryTextColor.withOpacity(0.8),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // FILTROS: FECHA + EXPORTAR
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _dateRange == null
                              ? 'Filtrar por fecha'
                              : 'Del ${_fmt(_dateRange!.start)}\nAl  ${_fmt(_dateRange!.end)}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTextColor,
                          side:
                              const BorderSide(color: Color(0xFF78C1E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_dateRange != null)
                      IconButton(
                        tooltip: 'Quitar filtro de fecha',
                        onPressed: _clearDateRange,
                        icon: Icon(
                          Icons.close,
                          color: primaryTextColor,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Exportar historial filtrado',
                      onPressed: () => _exportEntries(filtered),
                      icon: Icon(
                        Icons.ios_share,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 🎯 CHIPS DE ESTADOS DE ÁNIMO
              if (emotions.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('Todos'),
                          selected: _emotionFilter == null ||
                              _emotionFilter!.isNotEmpty == false,
                          onSelected: (_) {
                            setState(() => _emotionFilter = null);
                          },
                        ),
                      ),
                      ...emotions.map((emo) {
                        final selected = _emotionFilter != null &&
                            _emotionFilter!.toLowerCase() ==
                                emo.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(emo),
                            selected: selected,
                            selectedColor:
                                const Color(0xFF78C1E0).withOpacity(0.2),
                            onSelected: (_) {
                              setState(() => _emotionFilter = emo);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 4),

              // 📜 LISTA
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'No hay registros que coincidan con los filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = filtered[i];
                          final dt =
                              DateTime.tryParse(e['ts'] ?? '') ??
                                  DateTime.now();
                          final emotion = e['emotion'] ?? '';
                          final action = e['action'] ?? '';
                          final title = '$emotion • $action';

                          final color =
                              _emotionColor(context, emotion)
                                  .withOpacity(0.9);

                          return Card(
                            color: cardColor,
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: avatarBg,
                                radius: 18,
                                child: Icon(
                                  Icons.favorite,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              subtitle: Text(
                                _fmt(dt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EntryDetailScreen(entry: e),
                                  ),
                                );
                              },
                              // 👇 menú de 3 puntos: editar / eliminar
                              trailing: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: secondaryTextColor,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editEntryNotes(e);
                                  } else if (value == 'delete') {
                                    _deleteEntry(e);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar notas'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}








