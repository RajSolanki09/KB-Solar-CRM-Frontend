import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Helper/app_inputfield.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/services/notification_service.dart';
import 'package:solar_project/Helper/app_logo.dart';
import 'package:solar_project/Helper/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final ApiService _authService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Stack(
        children: [
          // ── Decorative background circles ──────────────────────────────
          Positioned(
            top: -80,
            right: -60,
             child: _GlowCircle(
               size: 260,
               color: const Color(0xFF7F36E6).withValues(alpha: 0.08),
             ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
             child: _GlowCircle(
               size: 300,
               color: const Color(0xFF7F36E6).withValues(alpha: 0.07),
             ),
          ),
          Positioned(
            top: size.height * 0.3,
            left: -40,
             child: _GlowCircle(
               size: 160,
               color: const Color(0xFF7F36E6).withValues(alpha: 0.06),
             ),
          ),

          // ── Main content ───────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo + brand ─────────────────────────────────
                        _buildBrand(context, isSmall),

                        const SizedBox(height: 28),

                        // ── Card ─────────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                               BoxShadow(
                                 color: const Color(0xFF7F36E6).withValues(alpha: 0.08),
                                 blurRadius: 32,
                                 offset: const Offset(0, 8),
                               ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 20 : 28,
                            vertical: 28,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Heading
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                 const Text(
                                   'Sign in to your KaaryaBook account',
                                   style: TextStyle(
                                     fontSize: 13,
                                     color: AppColors.textSecondary,
                                     fontWeight: FontWeight.w400,
                                   ),
                                 ),

                                const SizedBox(height: 24),

                                // ── Divider line ─────────────────────────
                                Container(
                                  height: 1,
                                  color: const Color(0xFFF1F5F9),
                                ),

                                const SizedBox(height: 20),

                                // ── Error banner ─────────────────────────
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                         const AppSvgIcon(
                                           AppSvgAssets.triangleAlert,
                                           size: 16,
                                           color: AppColors.error,
                                         ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                           child: Text(
                                             _errorMessage!,
                                             style: const TextStyle(
                                               fontSize: 12,
                                               color: AppColors.error,
                                               fontWeight: FontWeight.w500,
                                             ),
                                           ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => _errorMessage = null,
                                          ),
                                           child: const AppSvgIcon(
                                             AppSvgAssets.x,
                                             size: 15,
                                             color: AppColors.error,
                                           ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // ── Email ─────────────────────────────────
                                _FieldLabel(label: 'Email Address'),
                                const SizedBox(height: 6),
                                AppInputField(
                                  controller: _emailController,
                                  label: 'Email',
                                  svgIcon: AppSvgAssets.mail,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value.trim())) {
                                      return 'Enter valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ── Password ──────────────────────────────
                                _FieldLabel(label: 'Password'),
                                const SizedBox(height: 6),
                                AppInputField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  svgIcon: AppSvgAssets.lock,
                                  focusNode: _passwordFocus,
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Minimum 6 characters';
                                    }
                                    return null;
                                  },
                                  suffixIcon: IconButton(
                                     icon: AppSvgIcon(
                                       _obscurePassword
                                           ? AppSvgAssets.eyeOff
                                           : AppSvgAssets.eye,
                                       size: 18,
                                       color: AppColors.textTertiary,
                                     ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Login Button ──────────────────────────
                                _buildLoginButton(),

                                const SizedBox(height: 20),

                                // ── Footer ────────────────────────────────
                                Center(
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                    ),
                                    child: const Text(
                                      "Don't have an account? Contact admin",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Bottom tagline ────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.shield,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Secured & encrypted login',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, bool isSmall) {
    return AppLogo(
      size: LogoSize.custom,
      customWidth: isSmall ? 100 : 130,
      customHeight: isSmall ? 100 : 130,
      borderRadius: 28,
      withShadow: true,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A3FD1),
          disabledBackgroundColor: AppColors.accent1,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  AppSvgIcon(
                    AppSvgAssets.arrowRight,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _onLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final user = await _authService.login(email, password);

      // Register FCM token with backend
      NotificationService.instance.registerToken();

      final dynamic rawRole = user['role'];
      if (rawRole == null) throw Exception('Role missing in server response');

      final String roleStr = rawRole.toString().toLowerCase().trim();

      if (!mounted) return;

      // ── Map role string → UserRole enum ─────────────────────────────────
      UserRole userRole;
      if (roleStr == 'admin' || roleStr == 'owner') {
        userRole = UserRole.admin;
      } else if (roleStr == 'sales') {
        userRole = UserRole.sales;
      } else if (roleStr == 'service') {
        userRole = UserRole.service;
      } else if (roleStr == 'installation') {
        userRole = UserRole.installation;
      } else {
        throw Exception('Unknown role: $roleStr');
      }

      // ── Emit authenticated state ─────────────────────────────────────────
      if (!mounted) return;
      context.read<AppStateCubit>().login(
        role: userRole,
        userId: user['_id']?.toString() ?? user['id']?.toString() ?? '',
        userName: user['name']?.toString() ?? '',
        phone: user['phone']?.toString(),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Glow Circle decoration ────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }
}







