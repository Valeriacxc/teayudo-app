// lib/widgets/app_logo_title.dart
import 'package:flutter/material.dart';

class AppLogoTitle extends StatelessWidget {
  final String? subtitle; // 👈 subtítulo opcional

  const AppLogoTitle({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Colores marcados y legibles
    const titleColor = Color(0xFF2E3A45);
    final subtitleColor = cs.onSurface.withOpacity(0.7);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 26,
              height: 26,
              fit: BoxFit.cover,
              // 👇 Evita el recuadro rojo si el asset no se encuentra
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE3F3FB),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 18,
                    color: Color(0xFF78C1E0),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'TeAyudo',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: titleColor, // 👈 más oscuro y constante
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}


