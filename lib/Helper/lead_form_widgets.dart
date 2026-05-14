import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

class LeadSectionLabel extends StatelessWidget {
  const LeadSectionLabel({
    super.key,
    required this.text,
    required this.accentColor,
  });

  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.gray300,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class LeadTextFormField extends StatelessWidget {
  const LeadTextFormField({
    super.key,
    required this.controller,
    this.label,
    required this.svgIcon,
    required this.accentColor,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.prefixText,
    this.prefixStyle,
    this.counterText,
    this.focusedErrorBorder = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.hintText,
    this.suffixIcon,
    this.suffixText,
    this.fillColor,
    this.bottomSpacing = 10,
  });

  final TextEditingController controller;
  final String? label;
  final String svgIcon;
  final Color accentColor;
  final bool required;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final String? counterText;
  final bool focusedErrorBorder;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final String? hintText;
  final Widget? suffixIcon;
  final String? suffixText;
  final Color? fillColor;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        enabled: enabled,
        autofocus: autofocus,
        onTap: onTap,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 13.5, color: AppColors.gray300),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.gray300),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: AppSvgIcon(
              svgIcon,
              size: 16,
              color:  AppColors.gray300,
            ),
          ),
          suffixIcon: suffixIcon,
          suffixText: suffixText,
          prefixText: prefixText,
          prefixStyle: prefixStyle,
          counterText: counterText,
          filled: true,
          fillColor: fillColor ?? Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.gray300),
          ),
          focusedErrorBorder: focusedErrorBorder
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.gray300,
                    width: 1.5,
                  ),
                )
              : null,
        ),
        validator:
            validator ??
            (required
                ? (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null
                : null),
      ),
    );
  }
}

class LeadDropdownField extends StatelessWidget {
  const LeadDropdownField({
    super.key,
    required this.label,
    required this.svgIcon,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.required = false,
    this.validator,
  });

  final String label;
  final String svgIcon;
  final List<String> items;
  final String? value;
  final void Function(String?) onChanged;
  final Color accentColor;
  final bool required;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        icon: const AppSvgIcon(
          AppSvgAssets.chevronDown,
          size: 18,
          color: AppColors.gray300,
        ),
        style: const TextStyle(fontSize: 13.5, color: AppColors.gray300),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.gray300),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: AppSvgIcon(
              svgIcon,
              size: 16,
              color:  AppColors.gray300,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13.5)),
              ),
            )
            .toList(),
        validator:
            validator ??
            (required
                ? (selected) => selected == null ? 'Please select one' : null
                : null),
      ),
    );
  }
}

class LeadSubmitButton extends StatelessWidget {
  const LeadSubmitButton({
    super.key,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
          shadowColor: color.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ── Label builder ─────────────────────────────────────────────────────────
Widget buildLabel(String text, {bool required = false}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: AppColors.gray300,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : [],
      ),
    ),
    const SizedBox(height: 6),
  ],
);





