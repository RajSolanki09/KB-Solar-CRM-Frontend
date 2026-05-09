import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';

class AppInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String svgIcon;

  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.svgIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: AppSvgIcon(svgIcon, size: 20, color: Colors.grey.shade600),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
