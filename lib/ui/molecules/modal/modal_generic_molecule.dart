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
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 🔥 importante
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AppSafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// 🔥 HANDLE (UX premium)
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🔥 ICON
                      if (icon != null)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (iconColor ?? (isDanger ? theme.colorScheme.error : theme.colorScheme.primary)).withOpacity(0.1),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 28,
                            color: iconColor ?? (isDanger ? theme.colorScheme.error : theme.colorScheme.primary),
                          ),
                        ),

                      if (icon != null) const SizedBox(height: 16),

                      /// 🔥 TITLE
                      Text(
                        title ?? 'Atenção',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// 🔥 DESCRIPTION
                      Text(
                        description ?? 'Ao confirmar, a ação será executada imediatamente.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),

                      if (body != null) ...[
                        const SizedBox(height: 20),
                        body,
                      ],

                      const SizedBox(height: 24),

                      /// 🔥 BUTTONS
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                primaryMethod();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDanger ? theme.colorScheme.error : theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(successTextButton ?? 'Confirmar'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                secondyMethod();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.dividerColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
          ),
        );
      },
    );
  }
}
