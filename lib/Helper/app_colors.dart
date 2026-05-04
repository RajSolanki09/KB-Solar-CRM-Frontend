import 'package:flutter/material.dart';

/// COMPREHENSIVE DESIGN SYSTEM FOR KB SOLAR CRM
/// Based on Logo Color: 0xFF9F5BFF (Primary Purple)
/// All colors are semantic, organized, and consistently applied
///
/// COLOR PHILOSOPHY:
/// - Primary: Logo purple (0xFF9F5BFF) for main actions, buttons, highlights
/// - Light variants: For hover, inactive, subtle backgrounds
/// - Supporting: Gray text scale, status colors (success/error/warning)
/// - Backgrounds: Light purple tints for visual hierarchy
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS (LOGO-BASED PURPLE SPECTRUM)
  // Use for: Main buttons, active states, highlights, primary actions
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color primary = Color(0xFF9F5BFF);              // Logo color - main brand
  static const Color primaryLight = Color(0xFFB08BFF);         // Light variant for hover states
  static const Color primaryLighter = Color(0xFFD4BFFF);       // Lighter for inactive states
  static const Color primaryLightest = Color(0xFFE6D5FF);      // Lightest for page backgrounds
  static const Color primaryDark = Color(0xFF7A3FD8);          // Pressed states, deeper interactions
  static const Color primaryDarker = Color(0xFF5E2FA0);        // Darkest variant, deep interactive states

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // SECONDARY/ACCENT COLORS (COMPLEMENTARY PURPLES)
  // Use for: Alternative highlights, secondary actions, special interactions
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color accent1 = Color(0xFFB08BFF);              // Light purple accent
  static const Color accent1Light = Color(0xFFD4BFFF);         // Light variant
  static const Color accent1Lighter = Color(0xFFE6D5FF);       // Lighter variant

  static const Color accent2 = Color(0xFF7A3FD8);              // Deep purple accent
  static const Color accent2Light = Color(0xFF9056C6);         // Light variant
  static const Color accent2Lighter = Color(0xFFB08BFF);       // Lighter variant

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS (CONSISTENT LIGHT PURPLE TINTS)
  // Use for: Page backgrounds, card backgrounds, subtle fills
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color bgPrimary = Color(0xFFF3E8FF);            // Main page background (very light)
  static const Color bgSecondary = Color(0xFFFAF5FF);          // Alternative background (almost white)
  static const Color bgSurface = Colors.white;                 // Card/elevated surfaces
  static const Color bgHover = Color(0xFFE6D5FF);              // Hover/focus background
  static const Color bgDisabled = Color(0xFFF5F5F5);           // Disabled state background

  // Legacy colors for compatibility
  static const Color purpleBg = Color(0xFFF3E8FF);             // Alias for bgPrimary
  static const Color purpleTint = Color(0xFFE6D5FF);           // Alias for primaryLightest
  static const Color purpleTintLight = Color(0xFFFAF5FF);      // Alias for bgSecondary
  static const Color lightPurple = Color(0xFFB08BFF);          // Alias for accent1
  static const Color deepPurple = Color(0xFF7A3FD8);           // Alias for accent2

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // TEXT COLORS (CONSISTENT GRAY SCALE)
  // Use for: All text content - ensures readability & consistency
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color textPrimary = Color(0xFF1F2937);          // Main heading & body text (dark gray)
  static const Color textSecondary = Color(0xFF6B7280);        // Subheadings, secondary info (medium gray)
  static const Color textTertiary = Color(0xFF9CA3AF);         // Hints, labels, muted text (light gray)
  static const Color textLight = Color(0xFFD1D5DB);            // Disabled text, very light (lighter gray)
  static const Color textInverse = Colors.white;               // Text on dark backgrounds

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // BORDER & DIVIDER COLORS (LIGHT PURPLE TINTS)
  // Use for: Borders, dividers, subtle separators
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color borderPrimary = Color(0xFFD4BFFF);        // Main borders (light purple)
  static const Color borderSecondary = Color(0xFFB08BFF);      // Secondary borders (medium purple)
  static const Color borderLight = Color(0xFFE6D5FF);          // Light borders, subtle divides
  static const Color divider = Color(0xFFE6D5FF);              // Divider lines between sections

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // SIDEBAR SPECIFIC COLORS
  // Use for: Navigation sidebars, menus, navigation items
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color sidebarBg = Color(0xFFF3E8FF);            // Sidebar background
  static const Color sidebarBorder = Color(0xFFD4BFFF);        // Sidebar divider/border
  static const Color sidebarItemActive = Color(0xFF9F5BFF);    // Active nav item (logo color)
  static const Color sidebarItemHover = Color(0xFFE6D5FF);     // Hover background for items
  static const Color sidebarTextActive = Color(0xFF9F5BFF);    // Active nav text
  static const Color sidebarTextInactive = Color(0xFF6B7280);  // Inactive nav text

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // BUTTON COLORS
  // Use for: Action buttons, primary CTAs, interactive elements
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color buttonPrimary = Color(0xFF9F5BFF);        // Main action button (logo color)
  static const Color buttonPrimaryHover = Color(0xFF7A3FD8);   // Button on hover (darker)
  static const Color buttonPrimaryPressed = Color(0xFF5E2FA0); // Button on pressed (darkest)
  static const Color buttonSecondary = Color(0xFFD4BFFF);      // Secondary button background
  static const Color buttonSecondaryText = Color(0xFF9F5BFF);  // Secondary button text
  static const Color buttonText = Colors.white;                // Text on primary button

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // STATUS & STATE COLORS (SEMANTIC COLORS)
  // Use for: Success, error, warning, info indicators
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF10B981);              // Success/checkmark - green
  static const Color successLight = Color(0xFFD1FAE5);         // Success background light
  static const Color error = Color(0xFFEF4444);                // Error/danger - red
  static const Color errorLight = Color(0xFFFEE2E2);           // Error background light
  static const Color warning = Color(0xFFF59E0B);              // Warning/caution - orange
  static const Color warningLight = Color(0xFFFEF3C7);         // Warning background light
  static const Color info = Color(0xFF3B82F6);                 // Info - blue
  static const Color infoLight = Color(0xFFDEEEFF);            // Info background light

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // Use for: SVG icons, icon buttons, icon decorations
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color iconPrimary = Color(0xFF9F5BFF);          // Main icons (logo purple)
  static const Color iconSecondary = Color(0xFF6B7280);        // Secondary icons (muted)
  static const Color iconDisabled = Color(0xFFD1D5DB);         // Disabled icons (light)
  static const Color iconLight = Color(0xFFE6D5FF);            // Light background icons

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // INPUT FIELD COLORS
  // Use for: Text fields, form inputs, search boxes
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color inputBg = Colors.white;                   // Input field background
  static const Color inputBorder = Color(0xFFD4BFFF);          // Input field border (normal)
  static const Color inputBorderFocus = Color(0xFF9F5BFF);     // Input field border on focus
  static const Color inputText = Color(0xFF1F2937);            // Input text color
  static const Color inputPlaceholder = Color(0xFF9CA3AF);     // Placeholder text
  static const Color inputError = Color(0xFFEF4444);           // Input border on error
  static const Color inputSuccess = Color(0xFF10B981);         // Input border on success

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // LOGO & BRAND EFFECTS
  // Use for: Logo shadows, glows, brand effects
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color logoShadow = Color(0xFF9F5BFF);           // Logo shadow/glow color
  static const Color brandGlow = Color(0xFF9F5BFF);            // Brand accent glow

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // UTILITY COLORS
  // Use for: Overlays, transparent elements, special cases
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color overlay = Color(0x33000000);              // 20% black overlay

  // ═══════════════════════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // Use for: Dynamic color generation, state-based colors
  // ═══════════════════════════════════════════════════════════════════════════════════════════════

  /// Logo shadow with custom opacity
  static Color logoShadowWithOpacity(double opacity) =>
      logoShadow.withValues(alpha: opacity);

  /// Primary color with custom opacity
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);

  /// Border color based on state
  static Color getBorderColor({
    required bool isFocused,
    required bool hasError,
  }) {
    if (hasError) return inputError;
    if (isFocused) return inputBorderFocus;
    return inputBorder;
  }

  /// Get background color based on enabled state
  static Color getBackgroundColor({required bool isEnabled}) =>
      isEnabled ? inputBg : bgDisabled;

  /// Get text color based on enabled state
  static Color getTextColor({required bool isEnabled}) =>
      isEnabled ? textPrimary : textLight;
}
