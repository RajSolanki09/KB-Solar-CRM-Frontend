// lib/Helper/sidebar_widgets.dart
//
// Shared widgets and helpers for all dashboard sidebars.
// Eliminates identical brand-header, nav-item, logout-button, and
// logout-dialog code that was previously duplicated across every sidebar.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand Header
// ─────────────────────────────────────────────────────────────────────────────

/// Logo + app-name header used at the top of every sidebar.
///
/// [title] – the main label (e.g. "Solar Plant CRM").
/// [subtitle] – optional secondary label (e.g. "Installation Team").
class SidebarBrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String iconAsset;

  const SidebarBrandHeader({
    required this.title,
    this.subtitle,
    this.iconAsset = AppSvgAssets.sun,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xffFFF7ED),
          child: AppSvgIcon(iconAsset, size: 30, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(color: AppColors.textGray, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Item
// ─────────────────────────────────────────────────────────────────────────────

/// Generic sidebar navigation row that replaces every sidebar's private
/// `_SideItem` widget.  Pass the cubit-specific `isActive` flag and `onTap`
/// callback so the widget stays decoupled from any specific cubit type.
class SidebarNavItem extends StatefulWidget {
  final String svgAsset;
  final IconData? fallbackIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarNavItem({
    required this.svgAsset,
    this.fallbackIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovering = false;

  bool _canHover(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    final isDesktopHover = _canHover(context) && _isHovering;
    final activeBg = widget.isActive
        ? const Color(0xffE0E7FF)
        : isDesktopHover
        ?  AppColors.background
        : Colors.transparent;

    return MouseRegion(
      onEnter: _canHover(context)
          ? (_) => setState(() => _isHovering = true)
          : null,
      onExit: _canHover(context)
          ? (_) => setState(() => _isHovering = false)
          : null,
      cursor: _canHover(context) ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          transform: Matrix4.translationValues(isDesktopHover ? 3 : 0, 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: activeBg,
            boxShadow: isDesktopHover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AppSvgIcon(
                widget.svgAsset,
                size: 24,
                color: widget.isActive
                    ? AppColors.primary
                    :  AppColors.textGray,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isActive
                        ? const Color(0xff1E40AF)
                        :  AppColors.textGray,
                    fontSize: 14,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────

/// The styled logout tile placed at the bottom of every sidebar.
class SidebarLogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const SidebarLogoutButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xffEEF2FF),
          ),
          child: const Row(
            children: [
              AppSvgIcon(
                AppSvgAssets.logOut,
                size: 20,
                color: AppColors.textGray,
              ),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the shared logout-confirmation dialog used by every sidebar.
///
/// Calls [ApiService().logout()] on confirmation and triggers
/// [AppStateCubit.logout()].  Any error is shown via [AppFeedback.showError].
void showSidebarLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffFEF3C7),
                ),
                child: const AppSvgIcon(
                  AppSvgAssets.logOut,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Logout Confirmation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to logout? You will need to log in again to access your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await ApiService().logout();
                          if (context.mounted) {
                            context.read<AppStateCubit>().logout();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppFeedback.showError(context, 'Logout failed: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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
}
