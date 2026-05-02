//este es mi tips_screen.dart                                                                                                             
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../widgets/app_logo_title.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // Tips por defecto (los mismos que tenías antes)
  static const List<String> _defaultTips = [
    '🌿 Respira profundo y cuenta hasta 4. Repite lentamente.',
    '💭 Recuerda: lo que sientes ahora no durará para siempre.',
    '🧘‍♀️ Haz una pausa: cierra los ojos y nota tu respiración.',
    '📋 Usa “Registrar cómo me siento” para liberar tensión mental.',
    '🎧 Escucha un audio de tu caja de ayuda o una canción tranquila.',
    '🚶‍♂️ Da un paseo corto o mueve el cuerpo unos minutos.',
    '☀️ Observa algo a tu alrededor que te dé calma o curiosidad.',
  ];

  List<String> _customTips = [];
  Box? _appBox;

  @override
  void initState() {
    super.initState();
    // Leer tips personalizados guardados en el box "app"
    try {
      _appBox = Hive.box('app');
      final dynamic stored = _appBox!.get('customTips');
      if (stored is List) {
        _customTips = stored.cast<String>();
      }
    } catch (_) {
      _customTips = [];
    }
  }

  Future<void> _saveCustomTips() async {
    try {
      await _appBox?.put('customTips', _customTips);
    } catch (_) {}
  }

  Future<void> _addTipDialog() async {
    final controller = TextEditingController();

    final String? newTip = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar tip propio'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Escribe un mensaje que te calme o te ayude…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newTip != null && newTip.isNotEmpty) {
      setState(() {
        _customTips.add(newTip);
      });
      await _saveCustomTips();
    }
  }

  Future<void> _removeCustomTip(int index) async {
    setState(() {
      _customTips.removeAt(index);
    });
    await _saveCustomTips();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Total de ítems: primeros los tips por defecto, luego los personalizados
    final int totalCount = _defaultTips.length + _customTips.length;

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(subtitle: 'Tips de bienestar'),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: cs.surfaceContainerHighest.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView.separated(
            itemCount: totalCount,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final bool isDefault = i < _defaultTips.length;
              final String text = isDefault
                  ? _defaultTips[i]
                  : _customTips[i - _defaultTips.length];

              return ListTile(
                tileColor: cs.primaryContainer.withOpacity(0.25),
                leading: Icon(
                  Icons.self_improvement_outlined,
                  size: 30,
                  color: cs.primary,
                ),
                title: Text(
                  text,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // Solo los tips personalizados se pueden borrar
                trailing: isDefault
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: cs.onSurface.withOpacity(0.7),
                        tooltip: 'Eliminar este tip',
                        onPressed: () =>
                            _removeCustomTip(i - _defaultTips.length),
                      ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTipDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar tip'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }
}


