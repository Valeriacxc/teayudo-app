// lib/screens/run_routine_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../widgets/app_logo_title.dart';
import '../widgets/heart_with_patch_image.dart';

class RunRoutineScreen extends StatefulWidget {
  final String name;
  final List<String> steps;
  final String? songPath; // puede ser null

  const RunRoutineScreen({
    super.key,
    required this.name,
    required this.steps,
    this.songPath,
  });

  @override
  State<RunRoutineScreen> createState() => _RunRoutineScreenState();
}

class _RunRoutineScreenState extends State<RunRoutineScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _audioReady = false;
  bool _loadingAudio = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final path = widget.songPath;
    if (path == null || path.trim().isEmpty) return;
    if (!File(path).existsSync()) return;

    setState(() => _loadingAudio = true);

    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(path)),
      );
      _audioReady = true;
    } catch (_) {
      _audioReady = false;
    } finally {
      if (mounted) {
        setState(() => _loadingAudio = false);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_audioReady) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF2E3A45);
    final Color secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF5A6B75);
    final Color cardColor =
        isDark ? const Color(0xFF111822) : const Color(0xFFEAF5FB);

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(subtitle: widget.name),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 💙 Corazón celeste animado
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1.05),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  // Volvemos a iniciar la animación
                  onEnd: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const HeartWithPatchImage(size: 70),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Respira y sigue estos pasos a tu ritmo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🎧 Tarjeta de audio (si hay canción)
              if (widget.songPath != null &&
                  widget.songPath!.trim().isNotEmpty) ...[
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: cs.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _audioReady
                                ? 'Canción para acompañar la rutina'
                                : 'Cargando audio…',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_loadingAudio)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_audioReady)
                          IconButton(
                            onPressed: _togglePlay,
                            icon: Icon(
                              _player.playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                            ),
                            color: cs.primary,
                            iconSize: 32,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 📝 Tarjeta con TODOS los pasos
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pasos de la rutina',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: widget.steps.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final step = widget.steps[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 24,
                                width: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.primary.withOpacity(
                                      isDark ? 0.35 : 0.25),
                                ),
                                child: const FittedBox(
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón terminar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Terminar rutina',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}







