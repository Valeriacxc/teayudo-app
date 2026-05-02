// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart'; // para ValueListenableBuilder

import '../widgets/heart_with_patch_image.dart';
import '../widgets/calm_heart_advice.dart';
import 'crisis_screen.dart';
import 'history_screen.dart';
import 'help_box_screen.dart';
import 'routines_screen.dart';
import 'contacts_screen.dart';
import 'tips_screen.dart';
import 'settings_screen.dart'; // para el botón de herramientas
import 'diary_screen.dart';   // 👈 NUEVO: Mi diario

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _userName = '';
  bool _welcomePopupShown = false;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Leer nombre guardado (si existe)
    try {
      final box = Hive.box('app');
      final value = box.get('userName');
      if (value is String && value.trim().isNotEmpty) {
        _userName = value.trim();
        _nameCtrl.text = _userName;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe tu nombre 🙂')),
      );
      return;
    }

    try {
      final box = Hive.box('app');
      await box.put('userName', name);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el nombre')),
      );
      return;
    }

    setState(() {
      _userName = name;
      _welcomePopupShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF5A6B75);

    // Pop-up de bienvenida cuando hay nombre
    if (_userName.isNotEmpty && !_welcomePopupShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent != true) return;
        _welcomePopupShown = true;
        showDialog(
          context: context,
          builder: (_) => _WelcomePopup(name: _userName),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeartWithPatchImage(size: 32),
            const SizedBox(width: 8),
            Text(
              'TeAyudo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF2E3A45),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ──────────────── SALUDO + CORAZÓN + HERRAMIENTAS ────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ValueListenableBuilder<Box>(
                                valueListenable:
                                    Hive.box('app').listenable(keys: ['userName']),
                                builder: (_, box, __) {
                                  final dynamic raw = box.get('userName');
                                  final String name =
                                      (raw is String ? raw : '').trim();
                                  return Text(
                                    name.isNotEmpty ? 'Hola, $name' : 'Hola',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estoy aquí para acompañarte.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFF78C1E0),
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Configuración',
                    icon: Icon(
                      Icons.settings_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const CalmHeartAdvice(),
              const SizedBox(height: 20),

              // PEDIR NOMBRE SI NO HAY
              if (_userName.isEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 1.5,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antes de seguir…',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '¿Cómo te llamas? Así puedo saludarte por tu nombre 🫶',
                          style: TextStyle(
                            color: secondaryTextColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tu nombre',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: FilledButton(
                            onPressed: _saveName,
                            child: const Text('Guardar mi nombre'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // GRID DE BOTONES
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _HomeButton(
                    label: 'Crisis',
                    icon: Icons.local_hospital,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CrisisScreen(),
                        ),
                      );
                    },
                  ),
                  _HomeButton(
                    label: 'Historial',
                    icon: Icons.favorite,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _HomeButton(
                    label: 'Caja de ayuda',
                    icon: Icons.lightbulb_outline,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpBoxScreen(),
                        ),
                      );
                    },
                  ),
                  _HomeButton(
                    label: 'Rutinas',
                    icon: Icons.loop,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoutinesScreen(),
                        ),
                      );
                    },
                  ),
                  _HomeButton(
                    label: 'Contactos',
                    icon: Icons.contact_phone,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactsScreen(),
                        ),
                      );
                    },
                  ),
                  _HomeButton(
                    label: 'Tips',
                    icon: Icons.psychology,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TipsScreen(),
                        ),
                      );
                    },
                  ),
                  _HomeButton(
                    label: 'Mi diario',
                    icon: Icons.menu_book_outlined,
                    bg: const Color(0xFF78C1E0).withOpacity(0.18),
                    iconColor: const Color(0xFF78C1E0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DiaryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: iconColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePopup extends StatelessWidget {
  final String name;
  const _WelcomePopup({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: const HeartWithPatchImage(size: 56),
            ),
            const SizedBox(height: 14),
            
            // 👇 SALUDO NEUTRO
            Text(
              'Hola, $name 💙',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Me alegra que estés aquí.\n'
              'Podemos ir paso a paso, a tu ritmo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.8),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


























