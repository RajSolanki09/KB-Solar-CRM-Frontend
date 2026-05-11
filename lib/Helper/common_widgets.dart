import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

// ----------------- Responsive Font Helper -------------------------------

double responsiveFont(BuildContext context, double size) {
  double width = MediaQuery.of(context).size.width;
  if (width < 360) {
    return size * 0.75;
  } else if (width < 400) {
    return size * 0.85;
  } else if (width < 600) {
    return size;
  } else if (width < 900) {
    return size * 1.1;
  } else if (width < 1280) {
    return size * 1.0;
  } // ← add this
  else {
    return size * 0.9;
  } // ← tighten large desktop
}

// ----------------- Responsive Padding Helper -------------------------------

double responsivePadding(BuildContext context, double size) {
  double width = MediaQuery.of(context).size.width;
  if (width < 360) {
    return size * 0.6;
  } else if (width < 400) {
    return size * 0.75;
  } else if (width < 600) {
    return size;
  } else if (width < 900) {
    return size * 1.05;
  } // was 1.1
  else if (width < 1280) {
    return size * 1.0;
  } else {
    return size * 0.9;
  } // ← was 1.5, that caused the overflow
}

/// ---------------- Responsive Layout ------------------

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context))
      return desktop ?? tablet ?? mobile;
    else if (isTablet(context))
      return tablet ?? mobile;
    else
      return mobile;
  }
}

/// ---------------- DASHBOARD CARD ----------------

class DashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? svgAsset;
  final Color cardColor;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.svgAsset,
    required this.cardColor,
    this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin { // ← TickerProviderStateMixin se change karo
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  // ← _ripples list hata do

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!mounted) return;
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!mounted) return;
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!mounted) return;
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final double pad = responsivePadding(context, 12);
    final double iconSize = responsiveFont(context, 18);
    final double valueSize = responsiveFont(context, 30);
    final double titleSize = responsiveFont(context, 13);

    final Color textColor = widget.cardColor.computeLuminance() > 0.5
        ? AppColors.textDark
        : AppColors.surface;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.cardColor.withValues(alpha: 0.88),
                widget.cardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(responsivePadding(context, 18)),
            boxShadow: [
              BoxShadow(
                color: widget.cardColor.withValues(alpha: 0.40),
                blurRadius: responsivePadding(context, 20),
                offset: Offset(0, responsivePadding(context, 8)),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(responsivePadding(context, 18)),
                  child: CustomPaint(painter: _SunRaysPainter()),
                ),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0x38FFFFFF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              // ← Ripple layer hata do (_ripples.map(...) wali line)
              Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        SizedBox(width: responsivePadding(context, 8)),
                        SizedBox(
                          width: responsivePadding(context, 32),
                          height: responsivePadding(context, 32),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(responsivePadding(context, 12)),
                              border: Border.all(
                                color: AppColors.surface.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: widget.svgAsset != null
                                  ? AppSvgIcon(widget.svgAsset!, size: iconSize, color: textColor)
                                  : widget.icon != null
                                  ? Icon(widget.icon!, color: textColor, size: iconSize)
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: valueSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Sun Rays Painter ──────────────────────────────────────────────────────────

class _SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final origin = Offset(-size.width * 0.05, -size.height * 0.05);

    final rays = [
      _buildRay(origin, 25, 10, size),
      _buildRay(origin, 40, 8, size),
      _buildRay(origin, 55, 11, size),
      _buildRay(origin, 70, 8, size),
      _buildRay(origin, 85, 10, size),
      _buildRay(origin, 100, 9, size),
      _buildRay(origin, 115, 8, size),
      _buildRay(origin, 130, 10, size),
      _buildRay(origin, 145, 8, size),
    ];

    for (int i = 0; i < rays.length; i++) {
      canvas.drawPath(rays[i], i.isEven ? paint : paint2);
    }
  }

  Path _buildRay(
    Offset origin,
    double angleDeg,
    double halfSpreadDeg,
    Size size,
  ) {
    final double length = size.longestSide * 2.5;
    final double angleRad = angleDeg * (pi / 180);
    final double spreadRad = halfSpreadDeg * (pi / 180);
    final Offset left =
        origin +
        Offset(
          length * cos(angleRad - spreadRad),
          length * sin(angleRad - spreadRad),
        );
    final Offset right =
        origin +
        Offset(
          length * cos(angleRad + spreadRad),
          length * sin(angleRad + spreadRad),
        );
    return Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
  }

  @override
  bool shouldRepaint(_SunRaysPainter old) => false;
}

/// ---------------- STATUS CHIP ----------------

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
      case 'green':
        return AppColors.success;
      case 'grey':
        return Colors.grey;
      case 'crash':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.surface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// ---------------- INPUT FIELD ----------------

Widget inputField(
  TextEditingController controller,
  String label,
  IconData icon, {
  bool obscure = false,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
  );
}

/// ---------------- GLOW ICON ----------------

class GlowIcon extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final bool isSelected;

  const GlowIcon({
    super.key,
    this.icon,
    this.svgAsset,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(
                        0xFF7B2FF7,
                      ).withValues(alpha: 0.6 * value),
                      blurRadius: 14 * value,
                      spreadRadius: 2 * value,
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFF6EB6FF,
                      ).withValues(alpha: 0.6 * value),
                      blurRadius: 20 * value,
                      spreadRadius: 4 * value,
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFFFF5D8F,
                      ).withValues(alpha: 0.6 * value),
                      blurRadius: 26 * value,
                      spreadRadius: 6 * value,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (svgAsset != null)
                AppSvgIcon(
                  svgAsset!,
                  size: 24,
                  color: isSelected ? AppColors.surface : Colors.black,
                )
              else if (icon != null)
                Icon(
                  icon!,
                  size: 24,
                  color: isSelected ? AppColors.surface : Colors.black,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------- APP SCAFFOLD ----------------

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const AppScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(child: child),
    );
  }
}

/// ---------------- COMMON LIST TILE ----------------

class CommonListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;

  const CommonListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(label: Text(status)),
        onTap: onTap,
      ),
    );
  }
}

// --------------- Modern Dropdown (Bottom Sheet) -----------------

Widget modernDropdown<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) displayText,
  required Function(T?) onChanged,
}) {
  return _ModernDropdown<T>(
    label: label,
    value: value,
    items: items,
    displayText: displayText,
    onChanged: onChanged,
  );
}

class _ModernDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayText;
  final Function(T?) onChanged;

  const _ModernDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.displayText,
    required this.onChanged,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DropdownSheet<T>(
        label: label,
        value: value,
        items: items,
        displayText: displayText,
        onChanged: (v) {
          onChanged(v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final displayLabel = hasValue ? displayText(value as T) : 'All';

    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.6)
                : Colors.grey.shade300,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: hasValue
                          ? AppColors.primary
                          : AppColors.background,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            // Clear button when value is selected
            if (hasValue)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: AppSvgIcon(
                    AppSvgAssets.x,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              AppSvgIcon(
                AppSvgAssets.chevronDown,
                color: AppColors.background,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet picker ───────────────────────────────────────────────────────

class _DropdownSheet<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayText;
  final Function(T?) onChanged;

  const _DropdownSheet({
    required this.label,
    required this.value,
    required this.items,
    required this.displayText,
    required this.onChanged,
  });

  @override
  State<_DropdownSheet<T>> createState() => _DropdownSheetState<T>();
}

class _DropdownSheetState<T> extends State<_DropdownSheet<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // All items including "All" option
    final allItems = <T?>[null, ...widget.items];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      // Cap height at 55% of screen
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: const AppSvgIcon(
                      AppSvgAssets.x,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.divider),

          // ── Scrollable items ─────────────────────────────────
          Flexible(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: allItems.length,
                itemBuilder: (_, i) {
                  final item = allItems[i];
                  final label = item == null ? 'All' : widget.displayText(item);
                  final isSelected = widget.value == item;

                  return InkWell(
                    onTap: () => widget.onChanged(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          // Color dot for selected
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            AppSvgIcon(
                              AppSvgAssets.check,
                              size: 18,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
