// lib/widgets/big_button.dart
import 'package:flutter/material.dart';

class BigButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;       // color de fondo opcional
  final Color? textColor;   // color del texto opcional

  const BigButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
  });

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97, // nivel mínimo del rebote
      upperBound: 1.0,  // nivel normal
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animatePress() async {
    await _controller.reverse();
    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final background = widget.color ?? cs.primary;
    final textClr = widget.textColor ??
        (ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black);

    return ScaleTransition(
      scale: _controller.drive(Tween(begin: 1.0, end: 0.97)),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: textClr,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
          onPressed: () {
            _animatePress();
            widget.onPressed();
          },
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}




