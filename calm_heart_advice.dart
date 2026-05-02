// lib/widgets/calm_heart_advice.dart
import 'package:flutter/material.dart';

class CalmHeartAdvice extends StatefulWidget {
  const CalmHeartAdvice({super.key});

  @override
  State<CalmHeartAdvice> createState() => _CalmHeartAdviceState();
}

class _CalmHeartAdviceState extends State<CalmHeartAdvice> {
  int _index = 0;

  final List<String> _phrases = const [
    'Respira profundo, esto va a pasar 💙',
    'No tienes que poder con todo hoy.',
    'Ve paso a paso, está bien ir lento.',
    'Pide ayuda si lo necesitas, no estás sola/o.',
    'Tu cuerpo y tu mente están haciendo lo mejor que pueden.',
  ];

  void _nextPhrase() {
    setState(() {
      _index = (_index + 1) % _phrases.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const blue = Color(0xFF78C1E0);

    final Color bubbleColor =
        isDark ? const Color(0xFF121826) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.5)
        : Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Corazón celeste con ojitos y sonrisa
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: blue.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        blue.withOpacity(0.95),
                        blue.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white.withOpacity(0.98),
                ),
                // Ojitos
                const Positioned(
                  top: 30,
                  left: 30,
                  child: _HeartEye(),
                ),
                const Positioned(
                  top: 30,
                  right: 30,
                  child: _HeartEye(),
                ),
                
                Positioned(
                  bottom: 26,
                  child: CustomPaint(
                    size: const Size(32, 14),
                    painter: _SmilePainter(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Viñeta con la frase 
        GestureDetector(
          onTap: _nextPhrase,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _phrases[_index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: textColor, // bien negro en claro, bien blanco en oscuro
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartEye extends StatelessWidget {
  const _HeartEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    const startAngle = 3.4;
    const sweepAngle = -1.6;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

