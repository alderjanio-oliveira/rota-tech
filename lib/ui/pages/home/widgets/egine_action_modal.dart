import 'package:app_tracking/core/ui/drawer/scaffold/safe_area/app_safe_area.dart';
import 'package:flutter/material.dart';

class EngineActionModal {
  static Future<void> show({required BuildContext context, required VoidCallback onEngineOn, required VoidCallback onEngineOff}) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return AppSafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Estado do motor indefinido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('O que você deseja fazer?', textAlign: TextAlign.center),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Ligar motor'),
                        onPressed: () {
                          Navigator.pop(context);
                          onEngineOn();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock),
                        label: const Text('Desligar motor'),
                        onPressed: () {
                          Navigator.pop(context);
                          onEngineOff();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
