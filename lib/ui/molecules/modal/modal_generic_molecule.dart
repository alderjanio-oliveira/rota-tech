import 'package:app_tracking/core/ui/drawer/scaffold/safe_area/app_safe_area.dart';
import 'package:flutter/material.dart';

class GenericModalMolecule {
  static Future<void> show({
    required BuildContext context,
    required VoidCallback primaryMethod,
    required VoidCallback secondyMethod,
    String? successTextButton,
    String? secondyTextButton,
    String? title,
    String? description,
    Widget? body,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ essencial
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // ✅ sobe com teclado
          ),
          child: AppSafeArea(
            top: false,
            child: SingleChildScrollView(
              // ✅ evita overflow
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.help_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      title ?? 'Atenção',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description ?? 'Ao clicar em confirmar, o comando será executado imediatamente.',
                      textAlign: TextAlign.center,
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 16),
                      body,
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: primaryMethod,
                            child: Text(successTextButton ?? 'OK'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: secondyMethod,
                            child: Text(secondyTextButton ?? 'Cancelar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
