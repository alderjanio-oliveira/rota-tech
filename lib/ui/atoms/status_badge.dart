import 'package:flutter/material.dart';

/// Ícone de status (bateria, cadeado, etc.) com cor tri-state: verde, vermelho
/// ou cinza/sem cor quando não há informação disponível.
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const StatusBadge({super.key, required this.icon, required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color ?? Colors.grey.withOpacity(0.45));
  }
}
