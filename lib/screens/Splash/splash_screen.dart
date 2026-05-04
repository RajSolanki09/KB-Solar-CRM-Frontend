import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_logo.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controller A: logo + tagline reveal ───────────────────────────────────
  late AnimationController _logoCtrl;

  late Animation<Offset> _logoSlide; // left → center slide
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsFade;

  // ── Controller B: idle glow pulse on logo ─────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _idleGlow;

  final ApiService _authService = ApiService();

  @override
  void initState() {
    super.initState();

    // ── Logo reveal: 4500 ms, starts immediately ───────────────────────────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    // Logo slides in from left edge to center
    _logoSlide = Tween<Offset>(begin: const Offset(-1.2, 0.0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _logoCtrl,
            curve: const Interval(0.0, 0.75, curve: Curves.easeInOutSine),
          ),
        );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutSine),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOutSine),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.55, 0.82, curve: Curves.easeInOutSine),
      ),
    );
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.78, 1.00, curve: Curves.easeInOutSine),
      ),
    );

    // ── Idle glow pulse ───────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _idleGlow = Tween<double>(
      begin: 0.08,
      end: 0.22,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Start logo animation immediately ─────────────────────────────────
    _logoCtrl.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final results = await Future.wait([
      _authService.getProfile().catchError((_) => null),
      Future.delayed(const Duration(milliseconds: 4500)),
    ]);

    if (!mounted) return;

    final profile = results[0] as Map<String, dynamic>?;

    if (profile != null && profile['role'] != null) {
      final roleStr = (profile['role'] as String).toLowerCase();
      final userId = (profile['_id'] ?? profile['id'] ?? '') as String;
      final userName = (profile['name'] ?? profile['fullName'] ?? '') as String;
      final phone = profile['phone'] as String?;

      UserRole? role;
      if (roleStr.contains('admin') || roleStr.contains('owner')) {
        role = UserRole.admin;
      } else if (roleStr.contains('sales')) {
        role = UserRole.sales;
      } else if (roleStr.contains('service')) {
        role = UserRole.service;
      } else if (roleStr.contains('installation')) {
        role = UserRole.installation;
      }

      if (role != null) {
        context.read<AppStateCubit>().login(
          role: role,
          userId: userId,
          userName: userName,
          phone: phone,
        );
        return;
      }
    }

    context.read<AppStateCubit>().logout();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Soft radial background ────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Color(0xFFF8F5FF), Colors.white],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Corner decorative circles ─────────────────────────────────────
          Positioned(
            top: -size.width * 0.22,
            right: -size.width * 0.22,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: AppColors.primary.withOpacity(0.04),
               ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.28,
            left: -size.width * 0.18,
            child: Container(
              width: size.width * 0.62,
              height: size.width * 0.62,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: AppColors.primaryLight.withOpacity(0.05),
               ),
            ),
          ),

          // ── Top accent bar ────────────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                   colors: [AppColors.primary, AppColors.primaryLight],
                 ),
               ),
              ),
            ),
          

          // ── Bottom accent bar ─────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent2.withOpacity(0.25),
                    AppColors.primary.withOpacity(0.25),
                  ],
                ),
              ),
            ),
          ),

          // ── Logo + tagline + dots ─────────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
            builder: (_, __) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo card: slides in from left
                    SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: AppLogo(
                            size: LogoSize.custom,
                            customWidth: size.width * 0.45 > 180 ? 180 : size.width * 0.45,
                            customHeight: size.width * 0.45 > 180 ? 180 : size.width * 0.45,
                            borderRadius: 36,
                            withShadow: true,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Divider pill
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Container(
                        width: 48,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Text(
                        'KaaryaBook Project Management',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.85),
                          fontSize: 13,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Loading dots
                    Opacity(
                      opacity: _dotsFade.value,
                      child: const _PulseDots(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Pulsing loading dots ──────────────────────────────────────────────────────
class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots> with TickerProviderStateMixin {
  late AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dots,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_dots.value - i * 0.25 + 1.0) % 1.0;
            final scale = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.0, 1.0);
            final opacity = 0.3 + scale * 0.7;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 7 + scale * 2,
              height: 7 + scale * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                  color: Color.lerp(
                    AppColors.primary.withOpacity(opacity * 0.5),
                    AppColors.primaryLight,
                    scale,
                  )!.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}





