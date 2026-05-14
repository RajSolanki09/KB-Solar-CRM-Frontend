// lib/screens/Dashboards/Installation_Dashboards/Profile/installation_profile_screen.dart

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

class InstallationProfileScreen extends StatefulWidget {
  const InstallationProfileScreen({super.key});

  @override
  State<InstallationProfileScreen> createState() =>
      _InstallationProfileScreenState();
}

class _InstallationProfileScreenState extends State<InstallationProfileScreen> {
  final ApiService _apiService = ApiService();
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

  // ── Fetch Profile ──────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await _apiService.getProfile();
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

  // ── Build Image Provider ───────────────────────────────────────────────────
  ImageProvider? _buildImageProvider() {
    if (_localImage != null) return FileImage(_localImage!);
    final rawPath = _user?['image'] as String?;
    final url = ApiService.buildImageUrl(rawPath);
    if (url == null) return null;
    return NetworkImage(url);
  }

  // ── Pick & Upload Profile Image ────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final source = await showProfilePhotoSourceSheet(context);
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _localImage = file;
        _isUploadingImage = true;
      });

      final updatedUser = await _apiService.updateProfile(
        imagePath: picked.path,
        imageBytes: await picked.readAsBytes(),
        imageFilename: picked.name,
      );

      if (mounted) {
        setState(() {
          _user = updatedUser;
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
        AppFeedback.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // ── Logout Confirmation ────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
    await showProfileLogoutConfirmation(
      context,
      onConfirm: () async {
        await _apiService.logout();
        if (mounted) context.read<AppStateCubit>().logout();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: AppColors.slate50,
        elevation: 0,
        centerTitle: true,
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
          : _buildProfile(),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildProfile() {
    final name = _user?['name'] ?? 'N/A';
    final email = _user?['email'] ?? 'N/A';
    final phone = _user?['phone'] ?? 'N/A';
    final role = _user?['role'] ?? 'N/A';
    final status = _user?['status'] ?? 'N/A';

    final roleDisplay = role.toString().isNotEmpty
        ? role.toString()[0].toUpperCase() + role.toString().substring(1)
        : role.toString();

    final isActive = status.toString().toLowerCase() == 'active';
    final imageProvider = _buildImageProvider();
    final hasImage = imageProvider != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Profile Header Card ──────────────────────────────────────────
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
                  color:   AppColors.purple500.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Avatar with Camera Icon ──────────────────────────────
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: hasImage ? imageProvider : null,
                      child: !hasImage
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
                          onTap: _pickAndUploadImage,
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
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const AppSvgIcon(
                              AppSvgAssets.camera,
                              size: 16,
                              color: AppColors.purple500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 20),

                // ── Name, Role, Status ───────────────────────────────────
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
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.w600,
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

          // ── Info Tiles ───────────────────────────────────────────────────
          _infoTile(AppSvgAssets.mail, 'Email', email),
          _infoTile(AppSvgAssets.phone, 'Phone', phone),
          _infoTile(AppSvgAssets.idCard, 'Role', roleDisplay),
          _infoTile(
            AppSvgAssets.building2,
            'Zone / Area',
            _user?['zone'] ?? 'N/A',
          ),

          const SizedBox(height: 30),

          // ── Logout Button ────────────────────────────────────────────────
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
        ],
      ),
    );
  }

  // ── Reusable Info Tile ─────────────────────────────────────────────────────
  Widget _infoTile(String svgAsset, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          AppSvgIcon(svgAsset, color:   AppColors.purple500),
          const SizedBox(width: 16),
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
  }
}



