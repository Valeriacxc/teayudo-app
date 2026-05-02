// lib/screens/diary_screen.dart 
import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/heart_with_patch_image.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo antes de guardar 🙂')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // Guardamos en el mismo formato que usa el historial
      await Store.addEntry(
        emotion: 'Diario',       // 👈 así se verá más bonito en el historial
        action: 'Mi diario',     // título que se muestra en historial
        notes: text,
      );

      if (!mounted) return;

      _ctrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada guardada en el historial 💙')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la entrada')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF5A6B75);
    final Color cardColor =
        isDark ? const Color(0xFF1F2A33) : const Color(0xFFEAF5FB);

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
              'Mi diario',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Títulos
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Text(
                'Escribe cómo te sientes hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Tu entrada quedará guardada en el historial con fecha y hora.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cuadro grande para escribir
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe aquí lo que quieras recordar de hoy…',
                      hintStyle: TextStyle(
                        color: secondaryTextColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Botón abajo, dentro del SafeArea y con padding
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Guardando…' : 'Guardar en el historial',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF78C1E0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


