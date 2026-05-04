import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_cubit.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_state.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_logo.dart';
import 'package:solar_project/Helper/app_colors.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminNavCubit, AdminNavPage>(
      builder: (context, state) {
        return Container(
          width: 260,
          decoration: const BoxDecoration(
            color: Color(0xffE6E8FF),
            border: Border(
              right: BorderSide(color: Color(0xffCFD2FF), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SidebarBrandHeader(),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    _SectionLabel(label: 'MAIN MENU'),
                    const SizedBox(height: 4),

                    _NavItem(
                      svgAsset: AppSvgAssets.dashboard,
                      label: 'Dashboard',
                      isActive: state == AdminNavPage.dashboard,
                      onTap: () => context.read<AdminNavCubit>().changePage(
                        AdminNavPage.dashboard,
                      ),
                    ),
                    _NavItem(
                      svgAsset: AppSvgAssets.sun,
                      label: 'Leads',
                      isActive: state == AdminNavPage.leads,
                      onTap: () => context.read<AdminNavCubit>().changePage(
                        AdminNavPage.leads,
                      ),
                    ),
                    _NavItem(
                      svgAsset: AppSvgAssets.cog,
                      label: 'Services',
                      isActive: state == AdminNavPage.service,
                      onTap: () => context.read<AdminNavCubit>().changePage(
                        AdminNavPage.service,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'ANALYTICS'),
                    const SizedBox(height: 4),

                    _NavItem(
                      svgAsset: AppSvgAssets.chartNoAxisCombined,
                      label: 'Reports',
                      isActive: state == AdminNavPage.reports,
                      onTap: () => context.read<AdminNavCubit>().changePage(
                        AdminNavPage.reports,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'ACCOUNT'),
                    const SizedBox(height: 4),

                    _NavItem(
                      svgAsset: AppSvgAssets.userRound,
                      label: 'Admin Profile',
                      isActive: state == AdminNavPage.profile,
                      onTap: () => context.read<AdminNavCubit>().changePage(
                        AdminNavPage.profile,
                      ),
                    ),
                  ],
                ),
              ),

              _BottomSection(),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand Header — logo image + clickable notification + search
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarBrandHeader extends StatefulWidget {
  @override
  State<_SidebarBrandHeader> createState() => _SidebarBrandHeaderState();
}

class _SidebarBrandHeaderState extends State<_SidebarBrandHeader> {
  bool _logoHovered = false;

  void _onLogoTap(BuildContext context) {
    // Navigate to dashboard (or refresh if already on dashboard)
    context.read<AdminNavCubit>().changePage(AdminNavPage.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Row(
        children: [
          // ── Logo — clickable, replaces sun icon ──────────────────────────
          MouseRegion(
            onEnter: (_) => setState(() => _logoHovered = true),
            onExit: (_) => setState(() => _logoHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _onLogoTap(context),
              child: Tooltip(
                message: 'Go to Dashboard',
                preferBelow: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent2.withOpacity(_logoHovered ? 0.45 : 0.30),
                        blurRadius: _logoHovered ? 14 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _logoHovered ? 0.85 : 1.0,
                      child: AppLogo(
                        size: LogoSize.custom,
                        customWidth: 52,
                        customHeight: 52,
                        borderRadius: 0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Brand text (unchanged) ────────────────────────────────────────
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KaaryaBook',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Project Management',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 36,
      decoration: BoxDecoration(
        color: _focused ? Colors.white : const Color(0xffD8DAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? AppColors.accent2 : const Color(0xffBFC2F0),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.accent2.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: const TextStyle(
              fontSize: 12.5,
              color: Color(0xff9396CC),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: AppSvgIcon(
                AppSvgAssets.search,
                size: 14,
                color: _focused
                    ? AppColors.accent2
                    : const Color(0xff9396CC),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Chip (notification / today button)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickChip extends StatefulWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color.withOpacity(_hovered ? 0.5 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(widget.icon, size: 12, color: widget.color),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
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
// Section Label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xff7B7EC4),
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Item
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final String svgAsset;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.svgAsset,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    // ── Pre-compute colors (no inline ternaries inside AnimatedContainer) ──
    final bgColor = active
        ? Colors.white
        : _hovered
        ? const Color(0xffD8DAFF)
        : const Color(0xffE6E8FF); // ← transparent ki jagah parent bg color

    final iconBg = active
        ? const Color(0xffECECFF)
        : _hovered
        ? const Color(0xffC8CAFF)
        : const Color(0xffD0D2F0);

    final iconColor = active
        ? AppColors.accent2
        : _hovered
        ? const Color(0xff3B3DCC)
        : const Color(0xff7476B8);

    final labelColor = active
        ? const Color(0xff3B3DCC)
        : _hovered
        ? const Color(0xff2D2FAA)
        : const Color(0xff6668A8);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut, // ← smoother curve
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent2.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AppSvgIcon(
                    widget.svgAsset,
                    size: 16,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                    letterSpacing: -0.1,
                  ),
                  child: Text(widget.label),
                ),
              ),
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accent2,
                    shape: BoxShape.circle,
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
// Bottom Section
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  const _BottomSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xffC4C6F0),
        ),
        const SizedBox(height: 6),
        _LogoutButton(onTap: () => _showLogoutDialog(context)),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.bgPrimary,
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Color(0xff6366D4)),
        ),
        actions: [
          TextButton(
            onPressed: () => safePop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xff9396CC)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _performLogout(context),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Production-ready logout handler
  /// Clears all stored tokens and user data, then triggers auth state change
  Future<void> _performLogout(BuildContext context) async {
    final apiService = ApiService();

    try {
      // Close the confirmation dialog first (defensive)
      safePop(context);

      // Show loading indicator while logging out
      _showLogoutProgressDialog(context);

      // Call backend logout endpoint (notify server of logout)
      await apiService.logout();

      // Close progress dialog before emitting logout so that the UI
      // teardown caused by logout does not remove the dialog underneath
      // us and cause framework assertions.
      if (context.mounted) {
        // Close progress dialog if shown
        safePop(context);
        context.read<AppStateCubit>().logout();
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      // Even if there's an error, still emit logout state
      // (apiService.logout() already clears TokenStorage)
      if (context.mounted) {
        safePop(context); // Close progress dialog if shown
        context.read<AppStateCubit>().logout();
      }
    }
  }

  /// Show a loading dialog while logout is in progress
  void _showLogoutProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: AppColors.bgPrimary,
        content: SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(  
                      AppColors.accent2,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Signing out...',
                  style: TextStyle(
                    color: Color(0xff6366D4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Pre-compute colors
    final bgColor = _hovered
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primary.withValues(alpha: 0.08);

    final iconBg = _hovered ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2);

    final iconColor = _hovered
        ? Colors.white
        : AppColors.primary;

    final labelColor = _hovered
        ? AppColors.primary
        : AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  letterSpacing: -0.1,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





