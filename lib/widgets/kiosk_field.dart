import 'package:flutter/material.dart';

class KioskField extends StatelessWidget {
  const KioskField({
    super.key,
    required this.controller,
    required this.title,
    this.helpText,
    this.hintText,
    this.keyboardType,
    this.autofill,
    this.validator,
    this.required = false,
    this.prefixIcon,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String title;                  // Title
  final String? helpText;              // Help Text
  final String? hintText;              // inside the Input
  final TextInputType? keyboardType;
  final Iterable<String>? autofill;
  final String? Function(String?)? validator;
  final bool required;                 // require or not = *
  final IconData? prefixIcon;
  final TextInputAction textInputAction;
  final bool obscure;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(title, style: tt.titleSmall)),
              if (required) ...[
                const SizedBox(width: 4),
                Text('*', style: tt.titleSmall?.copyWith(color: cs.error)),
              ],
            ],
          ),
        ),

        // explain text
        if (helpText != null && helpText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helpText!,
              style: tt.bodyMedium?.copyWith(color: cs.tertiary),
            ),
          ),

        const SizedBox(height: 12),

        // text input
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          autofillHints: autofill,
          validator: validator,
          obscureText: obscure,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            errorMaxLines: 3,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
