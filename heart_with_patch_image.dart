import 'package:flutter/material.dart';

class HeartWithPatchImage extends StatefulWidget {
  final double size;

  const HeartWithPatchImage({
    super.key,
    required this.size,
  });

  @override
  State<HeartWithPatchImage> createState() => _HeartWithPatchImageState();
}

class _HeartWithPatchImageState extends State<HeartWithPatchImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // rebote lento
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size),
        child: Image.asset(
          'assets/icon/icon.png', // tu icon.png con el corazón
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          //  Si por alguna razón el asset falla, NO se muestra el cuadro rojo de error
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size),
                color: const Color(0xFFE3F3FB),
              ),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFF78C1E0),
              ),
            );
          },
        ),
      ),
    );
  }
}



