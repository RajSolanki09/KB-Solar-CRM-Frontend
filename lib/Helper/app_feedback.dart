import 'package:flutter/material.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';

class AppFeedback {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: null, floating: false);
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    bool floating = true,
    String? svgAsset,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      floating: floating,
      svgAsset: svgAsset,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    bool floating = true,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      floating: floating,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color? backgroundColor,
    required bool floating,
    String? svgAsset,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null || !messenger.mounted) return;

    messenger.hideCurrentSnackBar();

    final content = svgAsset == null
        ? Text(message)
        : Row(
            children: [
              AppSvgIcon(svgAsset, color: AppColors.surface, size: 16),
              const SizedBox(width: 8),
              Text(message),
            ],
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messenger.mounted) return;
      try {
        messenger.showSnackBar(
          SnackBar(
            content: content,
            backgroundColor: backgroundColor,
            behavior: floating ? SnackBarBehavior.floating : null,
            shape: floating
                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                : null,
          ),
        );
      } catch (_) {
        // If a route transition deactivates the messenger during this frame,
        // skip feedback instead of crashing.
      }
    });
  }
}
