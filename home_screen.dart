// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../widgets/heart_with_patch_image.dart';
import '../widgets/calm_heart_advice.dart';
import '../data/store.dart';          // 👈 para leer el historial
import 'crisis_screen.dart';
import 'history_screen.dart';
import 'help_box_screen.dart';
import 'routines_screen.dart';
import 'contacts_screen.dart';
import 'tips_screen.dart';
import 'settings_screen.dart';
import 'diary_screen.dart';          // pantalla "Mi diario"

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String> _getUserName() async {
    try {
      final box = Hive.box('app');
      final name = box.get('userName');
      return name is String ? name : '';
    } catch (_) {
      return '';
    }
  }

  // 👇 Frase que cambia según la hora del día
  String _subtitleByTime() {
    final h = DateTime.now().hour;
    if (h < 12) {
      return 'Que tu mañana sea un poco más ligera, estoy aquí contigo.';
    } else if (h < 19) {
      return 'Tomemos una pausa en tu día, estoy aquí para acompañarte.';
    } else {
      return 'Llegaste hasta aquí hoy, descansa un poco, estoy contigo.';
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
        actions: [
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
      // 🔹 Ahora usamos ValueListenableBuilder para que el nombre se actualice solo
      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box('app').listenable(keys: ['userName']),
        builder: (context, box, _) {
          final dynamic raw = box.get('userName');
          final String userName = (raw is String ? raw : '').trim();

          return SafeArea(
            // 🔹 Toda la pantalla es desplazable
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ──────────────── SALUDO ────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName.isNotEmpty ? 'Hola, $userName' : 'Hola',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleByTime(),
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

                  const SizedBox(height: 18),

                  // 💙 Corazón con ojos + frases
                  const CalmHeartAdvice(),
                  const SizedBox(height: 16),

                  // ──────────────── MINI RESUMEN DEL HISTORIAL ────────────────
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Store.getEntries(),
                    builder: (context, snap) {
                      if (!snap.hasData || (snap.data?.isEmpty ?? true)) {
                        return const SizedBox.shrink();
                      }

                      final entries = snap.data!;
                      final now = DateTime.now();

                      // registros últimos 7 días
                      final recentCount = entries.where((e) {
                        final ts = DateTime.tryParse(e['ts'] ?? '');
                        if (ts == null) return false;
                        return now.difference(ts).inDays <= 7;
                      }).length;

                      // última entrada de diario
                      final diaryEntries = entries.where((e) {
                        final emo =
                            (e['emotion'] ?? '').toString().toLowerCase();
                        return emo == 'diario';
                      }).toList();

                      String lastDiaryText = 'Sin entradas de diario aún';
                      if (diaryEntries.isNotEmpty) {
                        diaryEntries.sort((a, b) {
                          final ta = DateTime.tryParse(a['ts'] ?? '') ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                        final tb = DateTime.tryParse(b['ts'] ?? '') ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return tb.compareTo(ta);
                        });
                        final last = DateTime.tryParse(diaryEntries.first['ts'] ?? '');
                        if (last != null) {
                          final diffDays = now.difference(last).inDays;
                          if (diffDays == 0) {
                            lastDiaryText = 'Última entrada de diario: hoy';
                          } else if (diffDays == 1) {
                            lastDiaryText = 'Última entrada de diario: ayer';
                          } else {
                            final d = last.day.toString().padLeft(2, '0');
                            final m = last.month.toString().padLeft(2, '0');
                            final y = last.year;
                            lastDiaryText =
                                'Última entrada de diario: $d/$m/$y';
                          }
                        }
                      }

                      final Color cardBg = isDark
                          ? const Color(0xFF111822)
                          : const Color(0xFFEAF5FB);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF78C1E0).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.insights_outlined,
                                color: Color(0xFF78C1E0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen de tu semana',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Registros en los últimos 7 días: $recentCount',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastDiaryText,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ──────────────── GRID DE BOTONES ────────────────
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

                      // 🔹 Placeholder vacío para centrar "Mi diario"
                      const SizedBox.shrink(),

                      // 👇 BOTÓN: MI DIARIO (centrado en la última fila)
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
          );
        },
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























