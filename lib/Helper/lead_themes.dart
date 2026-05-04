import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_colors.dart';

class LeadTheme {
  // ─────────────────────────────────────────
  // LIGHT CRM BACKGROUND (Compact Friendly)
  // ─────────────────────────────────────────
  static const Color bg = AppColors.bgSecondary;
  static const Color surface = Colors.white;
  static const Color surfaceDeep = Colors.white;
  static const Color border = AppColors.borderLight;

  // ─────────────────────────────────────────
  // BRAND COLORS
  // ─────────────────────────────────────────
  static const Color primary = AppColors.lightPurple; // Purple
  static const Color secondary = AppColors.lightPurple; // Use uniform brand purple
  static const Color warning = AppColors.lightPurple;
  static const Color danger = AppColors.lightPurple;
  static const Color success = AppColors.lightPurple;
  static const Color orange = AppColors.lightPurple;

  // ─────────────────────────────────────────
  // TEXT COLORS (DARK TEXT)
  // ─────────────────────────────────────────
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;

  // ─────────────────────────────────────────
  // COMPACT SPACING (IMPORTANT)
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
        return secondary;
      case 'Visit Scheduled':
        return warning;
      case 'Visited':
        return primary;
      case 'Quotation Sent':
        return warning;
      case 'Followup':
        return warning;
      case 'Deal Closed':
        return success;
      case 'Portal Submitted':
        return secondary;
      case 'Installed':
        return primary;
      case 'Meter Installed':
        return warning;
      case 'Subsidy Completed':
        return success;
      case 'Payment Completed':
        return success;
      case 'Payment Remaining':
        return warning;
      case 'Project Completed':
        return success;
      case 'Cancelled':
        return danger;
      default:
        return secondary;
    }
  }

  // ─────────────────────────────────────────
  // PRIORITY COLORS
  // ─────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return danger;
      case 'Medium':
        return warning;
      case 'Low':
        return success;
      default:
        return secondary;
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


