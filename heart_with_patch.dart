import 'package:flutter/material.dart';

class HeartWithPatch extends StatelessWidget {
  final double size;
  final Color? color;

  const HeartWithPatch({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final heartColor = color ?? cs.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.favorite,
          size: size,
          color: heartColor.withOpacity(0.9),
        ),
        Positioned(
          right: size * 0.02,
          top: size * 0.25,
          child: Icon(
            Icons.local_hospital,
            size: size * 0.45,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ],
    );
  }
}

