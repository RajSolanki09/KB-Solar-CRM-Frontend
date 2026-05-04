import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/profile_widgets.dart';
import 'package:solar_project/Helper/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OWNER PROFILE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});
  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _error;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await _api.getProfile();
      if (mounted)
        setState(() {
          _user = user;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
    }
  }

  // ── Image Provider ─────────────────────────────────────────────────────────
  ImageProvider? _imageProvider() {
    if (_localImage != null) return FileImage(_localImage!);
    final url = ApiService.buildImageUrl(_user?['image'] as String?);
    if (url == null) return null;
    return NetworkImage(url);
  }

  // ── Pick & Upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    final source = await showProfilePhotoSourceSheet(context);
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;

      setState(() {
        _localImage = File(picked.path);
        _isUploadingImage = true;
      });

      final updated = await _api.updateProfile(
        imagePath: picked.path,
        imageBytes: await picked.readAsBytes(),
        imageFilename: picked.name,
      );
      if (mounted) {
        setState(() {
          _user = updated;
          _localImage = null;
          _isUploadingImage = false;
        });
        AppFeedback.showSuccess(context, 'Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localImage = null;
          _isUploadingImage = false;
        });
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
    await showProfileLogoutConfirmation(
      context,
      onConfirm: () async {
        await _api.logout();
        if (mounted) context.read<AppStateCubit>().logout();
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: Center(child: CircularProgressIndicator(color: AppColors.lightPurple))
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.lightPurple.withValues(alpha: 0.15),
                    backgroundImage: _imageProvider(),
                    child: _imageProvider() == null
                        ? const Icon(Icons.person, size: 48, color: AppColors.lightPurple)
                        : null,
                  ),
                  if (_isUploadingImage)
                    const Positioned.fill(
                      child: CircleAvatar(
                        backgroundColor: Colors.black38,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUpload,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.lightPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _user?['name'] ?? 'User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _user?['email'] ?? '',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // Edit Profile
            _profileTile(
              icon: AppSvgAssets.userRound,
              label: 'Edit Profile',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(user: _user!),
                  ),
                );
                _loadProfile();
              },
            ),

            // Change Password
            _profileTile(
              icon: AppSvgAssets.lock,
              label: 'Change Password',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              ),
            ),

            // Notification Settings
            _profileTile(
              icon: AppSvgAssets.cog,
              label: 'Notification Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              ),
            ),

            // Privacy Policy
            _profileTile(
              icon: AppSvgAssets.sun,
              label: 'Privacy Policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),

            // Help & Support
            _profileTile(
              icon: AppSvgAssets.phone,
              label: 'Help & Support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppSvgIcon(icon, color: AppColors.lightPurple, size: 16),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANGE PASSWORD PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _saving = false;

  void _toggleCurrentPasswordVisibility() =>
      setState(() => _showCurrentPassword = !_showCurrentPassword);
  void _toggleNewPasswordVisibility() =>
      setState(() => _showNewPassword = !_showNewPassword);
  void _toggleConfirmPasswordVisibility() =>
      setState(() => _showConfirmPassword = !_showConfirmPassword);

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      AppFeedback.showError(context, 'New passwords do not match');
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().changePassword(
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, 'Password changed successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.lightPurple,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              _pwField(
                'Current Password',
                _currentPasswordCtrl,
                _showCurrentPassword,
                _toggleCurrentPasswordVisibility,
              ),
              const SizedBox(height: 16),
              _pwField(
                'New Password',
                _newPasswordCtrl,
                _showNewPassword,
                _toggleNewPasswordVisibility,
              ),
              const SizedBox(height: 16),
              _pwField(
                'Confirm New Password',
                _confirmPasswordCtrl,
                _showConfirmPassword,
                _toggleConfirmPasswordVisibility,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),),),),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pwField(
    String label,
    TextEditingController ctrl,
    bool show,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: ctrl,
      obscureText: !show,
      validator: (v) =>
          (v == null || v.isEmpty) ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(8.0),
          child: AppSvgIcon(AppSvgAssets.lock, color: AppColors.lightPurple),
        ),
        suffixIcon: IconButton(
          icon: AppSvgIcon(
            show ? AppSvgAssets.eyeOff : AppSvgAssets.eye,
            color: AppColors.textSecondary,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
            focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: AppColors.lightPurple),
         ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfilePage({super.key, required this.user});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.user['name'] ?? '');
  late final _emailCtrl = TextEditingController(
    text: widget.user['email'] ?? '',
  );
  late final _phoneCtrl = TextEditingController(
    text: widget.user['phone'] ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService().updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        AppFeedback.showSuccess(context, 'Profile updated!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: _appBar('Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              _field(
                'Full Name',
                _nameCtrl,
                AppSvgAssets.userRound,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _field(
                'Email',
                _emailCtrl,
                AppSvgAssets.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _field(
                'Phone',
                _phoneCtrl,
                AppSvgAssets.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String svgAsset, {
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppSvgIcon(svgAsset, color: AppColors.lightPurple),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent2)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION SETTINGS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _leads = true;
  bool _services = true;
  bool _payments = false;
  bool _followups = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: AppColors.primary),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _notifTile(
            'Lead Notifications',
            'Get notified for new leads',
            AppSvgAssets.sun,
            AppColors.warning,
            _leads,
            (v) => setState(() => _leads = v),
          ),
          _notifTile(
            'Service Updates',
            'Updates on service requests',
            AppSvgAssets.cog,
            AppColors.lightPurple,
            _services,
            (v) => setState(() => _services = v),
          ),
          _notifTile(
            'Payment Alerts',
            'Reminders for pending payments',
            AppSvgAssets.indianRupee,
            AppColors.success,
            _payments,
            (v) => setState(() => _payments = v),
          ),
          _notifTile(
            'Follow-up Reminders',
            'Daily follow-up alerts',
            AppSvgAssets.calendarDays,
            AppColors.info,
            _followups,
            (v) => setState(() => _followups = v),
          ),
        ],
      ),
    );
  }

  Widget _notifTile(
    String title,
    String subtitle,
    String svgAsset,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppSvgIcon(svgAsset, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.lightPurple,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY PAGE
// ─────────────────────────────────────────────────────────────────────────────
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: _appBar('Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _policySection(
            'Data Collection',
            'We collect information you provide directly to us including name, email, phone number, and usage data to improve the Solar CRM experience.',
          ),
          _policySection(
            'Data Storage',
            'Your data is securely stored using industry-standard encryption. We do not sell or share your personal data with third parties.',
          ),
          _policySection(
            'Data Usage',
            'Collected data is used solely to provide and improve the CRM services. Analytics are performed in aggregate and anonymised form.',
          ),
          _policySection(
            'Your Rights',
            'You may request access, correction, or deletion of your personal data at any time by contacting our support team.',
          ),
          _policySection(
            'Contact',
            'For privacy-related queries, email us at privacy@solarcrm.com',
          ),
        ],
      ),
    );
  }

  Widget _policySection(String title, String body) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.lightPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELP & SUPPORT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: _appBar('Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.lightPurple, AppColors.lightPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _contactRow(AppSvgAssets.mail, 'support@solarcrm.com'),
                const SizedBox(height: 10),
                _contactRow(AppSvgAssets.phone, '+91 9876543210'),
                const SizedBox(height: 10),
                _contactRow(AppSvgAssets.clock, 'Mon–Sat: 9 AM – 6 PM'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FAQs
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => _FaqTile(q: faq[0], a: faq[1])),
        ],
      ),
    );
  }

  Widget _contactRow(String svgAsset, String text) => Row(
        children: [
          AppSvgIcon(svgAsset, color: Colors.white70),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      );

  static const List<List<String>> _faqs = [
    [
      'How do I add a new lead?',
      'Go to the Leads tab and tap the + button at the bottom right corner.',
    ],
    [
      'How do I assign a service request?',
      'Open Service Requests, tap a request, and use the Assign Technician option.',
    ],
    [
      'How do I reset my password?',
      'Go to My Profile → Settings → Change Password.',
    ],
    [
      'Why is my data not syncing?',
      'Ensure the backend server is running and ADB reverse is active for USB debugging.',
    ],
  ];
}

class _FaqTile extends StatefulWidget {
  final String q, a;
  const _FaqTile({required this.q, required this.a});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              onTap: () => setState(() => _open = !_open),
              title: Text(
                widget.q,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: AppSvgIcon(
                _open ? AppSvgAssets.chevronUp : AppSvgAssets.chevronDown,
                color: AppColors.lightPurple,
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  widget.a,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED APP BAR HELPER
// ─────────────────────────────────────────────────────────────────────────────
AppBar _appBar(String title) => AppBar(
      backgroundColor: AppColors.bgSecondary),
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.lightPurple),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.lightPurple,
          fontSize: 16,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderPrimary),
      ),
    );






