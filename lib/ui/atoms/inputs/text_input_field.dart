// lib/ui/atoms/inputs/text_input_field.dart
import 'package:flutter/material.dart';

class TextInputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final bool autofocus;
  final VoidCallback? onEditingComplete;

  const TextInputField({
    super.key,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.errorText,
    this.controller,
    this.suffixIcon,
    this.autofocus = false,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      autofocus: autofocus,
      onEditingComplete: onEditingComplete,
      style: theme.textTheme.bodyMedium,

      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,

        /// ICON
        suffixIcon: suffixIcon,

        /// 🔥 PADDING
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        /// 🔥 ESTILO BASE
        filled: true,
        fillColor: theme.cardColor,

        /// 🔥 BORDA PADRÃO
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        /// 🔥 FOCO
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),

        /// 🔥 ERRO
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.5,
          ),
        ),

        /// 🔥 LABEL STYLE
        labelStyle: TextStyle(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}
