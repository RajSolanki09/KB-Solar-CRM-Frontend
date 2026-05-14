import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/profile_widgets.dart';

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
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
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
    return Scaffold(
      backgroundColor:    AppColors.slate50,
      appBar: AppBar(
        backgroundColor:    AppColors.slate50,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.purple500,
          ),
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.refreshCw,
              color: AppColors.purple500,
            ),
            onPressed: _loadProfile,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple500),
            )
          : _error != null
          ? ProfileErrorView(message: _error, onRetry: _loadProfile)
          : _buildBody(),
    );
  }

  // ── Main Body ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    final name = _user?['name'] ?? 'N/A';
    final email = _user?['email'] ?? 'N/A';
    final phone = _user?['phone'] ?? 'N/A';
    final role = _user?['role'] ?? 'N/A';
    final status = _user?['status'] ?? 'N/A';
    final roleDisplay = role.toString().isNotEmpty
        ? role.toString()[0].toUpperCase() + role.toString().substring(1)
        : role.toString();
    final isActive = status.toString().toLowerCase() == 'active';
    final imgProvider = _imageProvider();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Profile Header Card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple500, AppColors.purpleVariant1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:   AppColors.purple500.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar + camera
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: imgProvider,
                      child: imgProvider == null
                          ? const AppSvgIcon(
                              AppSvgAssets.userRound,
                              size: 40,
                              color: AppColors.purple500,
                            )
                          : null,
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.black45,
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    if (!_isUploadingImage)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUpload,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:   AppColors.purple500,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const AppSvgIcon(
                              AppSvgAssets.camera,
                              size: 12,
                              color: AppColors.purple500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 20),

                // Name / role / status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        roleDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Info Tiles ─────────────────────────────────────────────────────
          _infoTile(AppSvgAssets.mail, 'Email', email),
          _infoTile(AppSvgAssets.phone, 'Phone', phone),
          _infoTile(AppSvgAssets.idCard, 'Role', roleDisplay),

          const SizedBox(height: 24),

          // ── Settings Section ───────────────────────────────────────────────
          _sectionHeader('Settings'),
          const SizedBox(height: 12),

          _settingsTile(
            svgAsset: AppSvgAssets.lock,
            label: 'Change Password',
            color:   AppColors.purple500,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
          _settingsTile(
            svgAsset: AppSvgAssets.pencil,
            label: 'Edit Profile',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfilePage(user: _user ?? {}),
              ),
            ).then((_) => _loadProfile()),
          ),
          _settingsTile(
            svgAsset: AppSvgAssets.messageSquarePlus,
            label: 'Notification Settings',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsPage(),
              ),
            ),
          ),
          _settingsTile(
            svgAsset: AppSvgAssets.shield,
            label: 'Privacy Policy',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
          _settingsTile(
            svgAsset: AppSvgAssets.circle,
            label: 'Help & Support',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportPage()),
            ),
          ),

          const SizedBox(height: 24),

          // ── Logout ─────────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const AppSvgIcon(AppSvgAssets.logOut, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.grayDark,
      ),
    ),
  );

  Widget _infoTile(String svgAsset, String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        AppSvgIcon(svgAsset, color:   AppColors.purple500),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _settingsTile({
    required String svgAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: ListTile(
        onTap: onTap,
        leading: AppSvgIcon(
          svgAsset,
          color: color,
        ), // ← no container, no fixed size
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: const AppSvgIcon(
          AppSvgAssets.chevronRight,
          color: Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService().changePassword(
        currentPassword: _oldCtrl.text,
        newPassword: _newCtrl.text,
        confirmPassword: _confirmCtrl.text,
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
      backgroundColor:   AppColors.slate50,
      appBar: _appBar('Change Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              _pwField(
                'Current Password',
                _oldCtrl,
                _showOld,
                () => setState(() => _showOld = !_showOld),
              ),
              const SizedBox(height: 14),
              _pwField(
                'New Password',
                _newCtrl,
                _showNew,
                () => setState(() => _showNew = !_showNew),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Minimum 6 characters';
                  if (v == _oldCtrl.text) {
                    return 'New password must be different from current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _pwField(
                'Confirm New Password',
                _confirmCtrl,
                _showConfirm,
                () => setState(() => _showConfirm = !_showConfirm),
                validator: (v) =>
                    v != _newCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:   AppColors.purple500,
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
                          'Update Password',
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
    VoidCallback toggle, {
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !show,
      validator:
          validator ??
          (v) => (v == null || v.isEmpty) ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(8.0),
          child: AppSvgIcon(AppSvgAssets.lock, color: AppColors.purple500),
        ),
        suffixIcon: IconButton(
          icon: AppSvgIcon(
            show ? AppSvgAssets.eyeOff : AppSvgAssets.eye,
            color: Colors.grey,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple500),
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
      backgroundColor:   AppColors.slate50,
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
                    backgroundColor:   AppColors.purple500,
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
          child: AppSvgIcon(svgAsset, color:   AppColors.purple500),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple500),
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
      backgroundColor:   AppColors.slate50,
      appBar: _appBar('Notification Settings'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _notifTile(
            'Lead Notifications',
            'Get notified for new leads',
            AppSvgAssets.sun,
            Colors.orange,
            _leads,
            (v) => setState(() => _leads = v),
          ),
          _notifTile(
            'Service Updates',
            'Updates on service requests',
            AppSvgAssets.cog,
              AppColors.purple500,
            _services,
            (v) => setState(() => _services = v),
          ),
          _notifTile(
            'Payment Alerts',
            'Reminders for pending payments',
            AppSvgAssets.indianRupee,
            Colors.green,
            _payments,
            (v) => setState(() => _payments = v),
          ),
          _notifTile(
            'Follow-up Reminders',
            'Daily follow-up alerts',
            AppSvgAssets.calendarDays,
            Colors.blue,
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
              color: color.withOpacity(0.1),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor:   AppColors.purple500,
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
      backgroundColor:   AppColors.slate50,
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
            color: AppColors.purple500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
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
      backgroundColor:   AppColors.slate50,
      appBar: _appBar('Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple500, AppColors.purpleVariant1],
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: AppSvgIcon(
            _open ? AppSvgAssets.chevronUp : AppSvgAssets.chevronDown,
            color:   AppColors.purple500,
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              widget.a,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
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
  backgroundColor:   AppColors.slate50,
  elevation: 0,
  centerTitle: true,
  iconTheme: const IconThemeData(color: AppColors.purple500),
  title: Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: AppColors.purple500,
      fontSize: 16,
    ),
  ),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(height: 1, color: Colors.grey.shade300),
  ),
);




