import 'package:app_tracking/utils/utils.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool? locked;

  const ActionButton({super.key, required this.tooltip, required this.icon, required this.onPressed, this.locked});

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      icon: Icon(icon, color: Utils().choiceColorStatus(locked)),
      onPressed: onPressed,
    );
  }
}
