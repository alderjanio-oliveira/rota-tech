import 'package:flutter/material.dart';

/// Ícone de status (bateria, cadeado, etc.) com cor tri-state: verde, vermelho
/// ou neutro quando não há informação disponível. Sempre num fundo suave da
/// mesma cor — dá peso de "chip" ao ícone em vez de ficar solto no layout.
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const StatusBadge({super.key, required this.icon, required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.35);

    return Container(
      padding: EdgeInsets.all(size * 0.28),
      decoration: BoxDecoration(shape: BoxShape.circle, color: tone.withOpacity(0.12)),
      child: Icon(icon, size: size, color: tone),
    );
  }
}
