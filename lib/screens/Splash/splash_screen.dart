import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late Animation<Offset> _logoSlide;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsFade;

  late AnimationController _pulseCtrl;
  late Animation<double> _idleGlow;

  final ApiService _authService = ApiService();

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _logoSlide =
        Tween<Offset>(begin: const Offset(-1.2, 0.0), end: Offset.zero).animate(
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

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _idleGlow = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

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
      final userName =
          (profile['name'] ?? profile['fullName'] ?? '') as String;
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

    // ── Logo size: screen ke hisaab se responsive ──────────────────────────
    // Mobile: 0.28 * width  |  Tablet/Web: max 120px
    final double logoSize = (size.width * 0.28).clamp(80.0, 120.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Soft radial background ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Color(0xFFF3EEFF), AppColors.surface],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Corner decorative circles ───────────────────────────────────
          Positioned(
            top: -size.width * 0.22,
            right: -size.width * 0.22,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
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
                color:  AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── Top accent bar ──────────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                ),
              ),
            ),
          ),

          // ── Bottom accent bar ───────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                     AppColors.primary.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),

          // ── Logo + tagline + dots ───────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
            builder: (_, __) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo card ─────────────────────────────────────────
                    SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            // padding image ke saath proportional
                            padding: EdgeInsets.all(logoSize * 0.18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: AppColors.surface,
                              boxShadow: [
                                BoxShadow(
                                  color:  AppColors.primary
                                      .withValues(alpha: _idleGlow.value),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/splash-logo.png',
                              // ── SIZE YAHAN CONTROL KARO ────────────────
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Divider pill ──────────────────────────────────────
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Container(
                        width: 48,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Tagline ───────────────────────────────────────────
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Text(
                        'Solar Plant Management System',
                        style: TextStyle(
                          color:
                              const Color(0xFF6B7280).withValues(alpha: 0.85),
                          fontSize: 13,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Loading dots ──────────────────────────────────────
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
                  AppColors.primary.withValues(alpha: opacity * 0.5),
                   AppColors.primary,
                  scale,
                )!
                    .withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}