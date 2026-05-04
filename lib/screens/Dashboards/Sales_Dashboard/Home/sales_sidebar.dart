// lib/screens/Dashboards/Sales_Dashboard/Home/sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_cubit.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_logo.dart';
import 'package:solar_project/Helper/app_colors.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesNavCubit, SalesNavPage>(
      builder: (context, state) {
        return Container(
          width: 260,
          decoration: const BoxDecoration(
            color: AppColors.primaryLightest),
            border: Border(
              right: BorderSide(color: AppColors.primaryLighter), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SalesBrandHeader(),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    const _SectionLabel(label: 'MAIN MENU'),
                    const SizedBox(height: 4),

                    _NavItem(
                      svgAsset: AppSvgAssets.dashboard,
                      label: 'Dashboard',
                      isActive: state == SalesNavPage.dashboard,
                      onTap: () => context.read<SalesNavCubit>().changePage(
                            SalesNavPage.dashboard,
                          ),
                    ),
                    _NavItem(
                      svgAsset: AppSvgAssets.sun,
                      label: 'Leads',
                      isActive: state == SalesNavPage.leads,
                      onTap: () => context.read<SalesNavCubit>().changePage(
                            SalesNavPage.leads,
                          ),
                    ),
                    _NavItem(
                      svgAsset: AppSvgAssets.calendarDays,
                      label: 'Follow-ups',
                      isActive: state == SalesNavPage.followups,
                      onTap: () => context.read<SalesNavCubit>().changePage(
                            SalesNavPage.followups,
                          ),
                    ),

                    const SizedBox(height: 20),
                    const _SectionLabel(label: 'ACCOUNT'),
                    const SizedBox(height: 4),

                    _NavItem(
                      svgAsset: AppSvgAssets.userRound,
                      label: 'Profile',
                      isActive: state == SalesNavPage.profile,
                      onTap: () => context.read<SalesNavCubit>().changePage(
                            SalesNavPage.profile,
                          ),
                    ),
                  ],
                ),
              ),

              const _BottomSection(),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand Header
// ─────────────────────────────────────────────────────────────────────────────
class _SalesBrandHeader extends StatefulWidget {
  @override
  State<_SalesBrandHeader> createState() => _SalesBrandHeaderState();
}

class _SalesBrandHeaderState extends State<_SalesBrandHeader> {
  bool _logoHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Row(
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          MouseRegion(
            onEnter: (_) => setState(() => _logoHovered = true),
            onExit: (_) => setState(() => _logoHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.read<SalesNavCubit>().changePage(
                    SalesNavPage.dashboard,
                  ),
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
                        color: AppColors.accent2)
                            .withOpacity(_logoHovered ? 0.45 : 0.30),
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

          // ── Brand Text ────────────────────────────────────────────────────
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KaaryaBook',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Sales Team',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff7B7EC4),
                  letterSpacing: 0.1,
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
// Nav Item — with grey flash fix
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

    final bgColor = active
        ? Colors.white
        : _hovered
            ? const Color(0xffD8DAFF)
            : const Color(0xffE6E8FF);

    final iconBg = active
        ? const Color(0xffECECFF)
        : _hovered
            ? const Color(0xffC8CAFF)
            : const Color(0xffD0D2F0);

    final iconColor = active
        ? AppColors.accent2)
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
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent2).withOpacity(0.10),
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
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w500,
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
                    color: AppColors.accent2),
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
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.bgPrimary),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
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
              backgroundColor: AppColors.accent2),
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

  Future<void> _performLogout(BuildContext context) async {
    final apiService = ApiService();

      try {
      // Close the confirmation dialog safely
      safePop(context);
      _showLogoutProgressDialog(context);

      await apiService.logout();

      if (context.mounted) {
        // Close progress dialog if shown
        safePop(context);
        context.read<AppStateCubit>().logout();
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        safePop(context);
        context.read<AppStateCubit>().logout();
      }
    }
  }

  void _showLogoutProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: AppColors.bgPrimary),
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
                      AppColors.accent2),
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
// Logout Button — with grey flash fix
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
    final bgColor =
        _hovered ? AppColors.primary).withValues(alpha: 0.15) : AppColors.primary).withValues(alpha: 0.08);

    final iconBg =
        _hovered ? AppColors.primary) : AppColors.primary).withValues(alpha: 0.2);

    final iconColor =
        _hovered ? Colors.white : AppColors.primary);

    final labelColor =
        _hovered ? AppColors.primary) : AppColors.primary);

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
                child:
                    Icon(Icons.logout_rounded, size: 16, color: iconColor),
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







