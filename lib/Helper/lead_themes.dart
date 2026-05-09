import 'package:flutter/material.dart';
import 'package:solar_project/core/app_colors.dart';

class LeadTheme {
  // ─────────────────────────────────────────
  // BACKGROUND & SURFACE
  // ─────────────────────────────────────────
  static const Color bg = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color surfaceDeep = AppColors.surface;
  static const Color border = AppColors.divider;

  // ─────────────────────────────────────────
  // BRAND COLORS
  // ─────────────────────────────────────────
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.primaryLight;
  static const Color warning = AppColors.warning;       // = primary (0xFF5B4FCF)
  static const Color danger = AppColors.error;
  static const Color success = AppColors.success;       // = primary (0xFF5B4FCF)
  static const Color orange = AppColors.primaryDark;

  // ─────────────────────────────────────────
  // TEXT COLORS
  // ─────────────────────────────────────────
  static const Color textPrimary = AppColors.textDark;
  static const Color textSecondary = AppColors.textGray;
  static const Color textMuted = AppColors.textLight;

  // ─────────────────────────────────────────
  // COMPACT SPACING
  // ─────────────────────────────────────────
  static const double paddingSmall = 6;
  static const double paddingMedium = 10;
  static const double paddingLarge = 14;

  static const double radiusSmall = 6;
  static const double radiusMedium = 10;

  // ─────────────────────────────────────────
  // STATUS COLORS
  // ─────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'New Lead':
        return AppColors.primaryLight;
      case 'Visit Scheduled':
        return AppColors.primary;
      case 'Visited':
        return AppColors.primaryDark;
      case 'Quotation Sent':
        return AppColors.primary;
      case 'Followup':
        return AppColors.primaryLight;
      case 'Deal Closed':
        return AppColors.success;           // = primary
      case 'Portal Submitted':
        return AppColors.primaryTint;
      case 'Installed':
        return AppColors.solar;             // = primary
      case 'Meter Installed':
        return AppColors.primaryDark;
      case 'Subsidy Completed':
        return AppColors.success;
      case 'Payment Completed':
        return AppColors.success;
      case 'Payment Remaining':
        return AppColors.warning;           // = primary
      case 'Project Completed':
        return AppColors.darkNavy;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.primaryLight;
    }
  }

  // ─────────────────────────────────────────
  // PRIORITY COLORS
  // ─────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.primary;
      case 'Low':
        return AppColors.primaryLight;
      default:
        return AppColors.primaryLight;
    }
  }

  // ─────────────────────────────────────────
  // AMOUNT FORMATTER
  // ─────────────────────────────────────────
  static String formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}